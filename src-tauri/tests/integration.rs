//! End-to-end backend smoke test that exercises the same code paths the
//! Tauri commands use, but without a live `AppHandle` (so it can run
//! headless on CI / inside a Cloud Agent).
//!
//! Covers:
//! 1. HvAI difficulty 2 (custom engine): play 10 plies, alternating human
//!    "first legal move from `legal_moves_from`" + AI move.
//! 2. HvAI difficulty 6: if the bundled Stockfish ELF is available, play 4
//!    plies and assert the AI returned moves; otherwise expect a graceful
//!    fallback to the custom engine.
//! 3. PGN export → import roundtrip: position FEN matches.

use std::path::PathBuf;
use std::time::Duration;

use chess_lib::ai;
use chess_lib::api::{
    ApiError, ApiResult, GameMode, GameStatus, HumanColorChoice, MoveResult, NewGameOpts,
    SquareStr,
};
use chess_lib::commands::{api_move_from_engine, apply_engine_move, find_legal_move};
use chess_lib::engine::Position;
use chess_lib::pgn;
use chess_lib::session::{GameSession, SessionManager};

fn sidecar_is_real_elf() -> bool {
    let path: PathBuf = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("binaries")
        .join("stockfish-x86_64-unknown-linux-gnu");
    let Ok(bytes) = std::fs::read(&path) else {
        return false;
    };
    bytes.len() > 4 && bytes.starts_with(&[0x7f, b'E', b'L', b'F'])
}

fn first_legal_move(session: &SessionManager, game_id: &str) -> (SquareStr, SquareStr) {
    let snap = session
        .get(game_id)
        .expect("session::get must return a snapshot for an existing game");
    let mut entries: Vec<_> = snap.legal_moves.iter().collect();
    entries.sort_by(|a, b| a.0.cmp(b.0));
    let (from, targets) = entries
        .first()
        .copied()
        .expect("game must have at least one legal move");
    let mut sorted_targets = targets.clone();
    sorted_targets.sort();
    let to = sorted_targets
        .first()
        .cloned()
        .expect("source square must have at least one target");
    (from.clone(), to)
}

async fn play_human_move(session: &SessionManager, game_id: &str) -> ApiResult<MoveResult> {
    let (from, to) = first_legal_move(session, game_id);
    let mv = session.with_game_mut(game_id, |game| find_legal_move(game, &from, &to, None))?;
    apply_engine_move(session, game_id, mv)
}

async fn play_ai_move_sync(
    session: &SessionManager,
    game_id: &str,
    difficulty: u8,
) -> ApiResult<MoveResult> {
    let (position, history_uci) = {
        let game = session
            .game(game_id)
            .ok_or_else(|| ApiError::GameNotFound(game_id.to_string()))?;
        if game.status != GameStatus::Active {
            return Err(ApiError::IllegalMove("game is not active".into()));
        }
        (
            game.position.clone(),
            game.history
                .iter()
                .map(|mv| mv.uci.clone())
                .collect::<Vec<_>>(),
        )
    };

    let output = tokio::time::timeout(
        Duration::from_secs(30),
        ai::choose_move(None, game_id, position, history_uci, difficulty, |_| {}),
    )
    .await
    .map_err(|_| ApiError::Engine("ai timed out".into()))??
    .ok_or_else(|| ApiError::Engine("ai returned no move".into()))?;

    apply_engine_move(session, game_id, output.mv)
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn hvai_difficulty_2_plays_ten_plies() {
    let session = SessionManager::new();
    let game_id = uuid::Uuid::new_v4().to_string();
    let snap = session
        .create_game(
            game_id.clone(),
            NewGameOpts {
                mode: GameMode::Hva,
                ai_difficulty: Some(2),
                human_color: Some(HumanColorChoice::W),
                time_control: None,
            },
        )
        .expect("create_game");
    assert_eq!(snap.status, GameStatus::Active);
    assert_eq!(snap.history.len(), 0);

    for ply in 0..10 {
        let result = if ply % 2 == 0 {
            play_human_move(&session, &game_id).await
        } else {
            play_ai_move_sync(&session, &game_id, 2).await
        };
        let result = result.unwrap_or_else(|err| panic!("ply {ply} failed: {err}"));
        assert_eq!(
            result.snapshot.history.len(),
            (ply + 1) as usize,
            "history length must grow monotonically"
        );
        assert_eq!(result.snapshot.game_id, game_id);
        if result.snapshot.status != GameStatus::Active {
            panic!("game ended unexpectedly at ply {ply}: {:?}", result.snapshot.status);
        }
    }

    let final_snap = session.get(&game_id).expect("snapshot");
    assert_eq!(final_snap.history.len(), 10);
    assert!(!final_snap.fen.is_empty());
    assert!(
        !final_snap.legal_moves.is_empty(),
        "active game must have legal moves"
    );
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn hvai_difficulty_6_uses_stockfish_or_falls_back_gracefully() {
    let session = SessionManager::new();
    let game_id = uuid::Uuid::new_v4().to_string();
    session
        .create_game(
            game_id.clone(),
            NewGameOpts {
                mode: GameMode::Hva,
                ai_difficulty: Some(6),
                human_color: Some(HumanColorChoice::W),
                time_control: None,
            },
        )
        .expect("create_game");

    let real_engine = sidecar_is_real_elf();
    eprintln!("stockfish sidecar present and ELF: {real_engine}");

    for ply in 0..4 {
        let result = if ply % 2 == 0 {
            play_human_move(&session, &game_id).await
        } else {
            play_ai_move_sync(&session, &game_id, 6).await
        };
        let result = result.unwrap_or_else(|err| panic!("ply {ply} failed: {err}"));
        assert_eq!(result.snapshot.history.len(), (ply + 1) as usize);
    }

    let snap = session.get(&game_id).expect("snapshot");
    assert_eq!(snap.history.len(), 4);
}

#[test]
fn pgn_export_load_roundtrip_matches_position() {
    use chess_lib::engine::ChessMove;

    let session = SessionManager::new();
    let game_id = uuid::Uuid::new_v4().to_string();
    let _snap = session
        .create_game(
            game_id.clone(),
            NewGameOpts {
                mode: GameMode::Hvh,
                ai_difficulty: None,
                human_color: Some(HumanColorChoice::W),
                time_control: None,
            },
        )
        .expect("create_game");

    let opening_uci = ["e2e4", "e7e5", "g1f3", "b8c6", "f1c4", "g8f6"];
    for uci in opening_uci {
        let mv: ChessMove = session
            .with_game_mut(&game_id, |game| {
                game.position
                    .parse_uci(uci)
                    .ok_or_else(|| ApiError::IllegalMove(format!("invalid uci: {uci}")))
            })
            .unwrap();
        let api_mv = session
            .with_game_mut(&game_id, |game| {
                let api_mv = api_move_from_engine(game, mv);
                game.position.make_move(mv);
                game.history.push(api_mv.clone());
                game.last_move = Some(api_mv.clone());
                Ok(api_mv)
            })
            .unwrap();
        assert_eq!(api_mv.uci, uci);
    }

    let snap = session.get(&game_id).expect("snapshot");
    let original_fen = snap.fen.clone();
    let history_len = snap.history.len();
    assert_eq!(history_len, opening_uci.len());

    let pgn_text = pgn::serialize(&snap.history, snap.result, None, None);
    let parsed = pgn::parse(&pgn_text).expect("PGN should round-trip cleanly");
    assert_eq!(parsed.history.len(), history_len);
    assert_eq!(parsed.position.to_fen(), original_fen);

    let new_id = uuid::Uuid::new_v4().to_string();
    let restored = GameSession::from_loaded_game(new_id.clone(), parsed.position, parsed.history);
    let mut restored_clone = restored.clone();
    let restored_snap = restored_clone.snapshot();
    assert_eq!(restored_snap.fen, original_fen);
    assert_eq!(restored_snap.history.len(), history_len);

    let original_position = Position::from_fen(&original_fen).expect("re-parse fen");
    assert_eq!(original_position.to_fen(), original_fen);

    let restored_san: Vec<_> = restored_snap.history.iter().map(|m| m.san.clone()).collect();
    let original_san: Vec<_> = snap.history.iter().map(|m| m.san.clone()).collect();
    assert_eq!(restored_san, original_san);
}
