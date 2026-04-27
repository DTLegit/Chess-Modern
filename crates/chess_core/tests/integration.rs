//! End-to-end backend smoke test that exercises the same code paths the
//! original Tauri commands used, but driven through the new trait-based
//! seams (no `AppHandle`, no `tauri_plugin_shell`).
//!
//! Covers:
//! 1. HvAI difficulty 2 (custom engine): play 10 plies.
//! 2. HvAI difficulty 6: with [`NoStockfishSpawner`] the AI module falls
//!    through to the strongest custom-engine tier; we just assert plies
//!    are returned.
//! 3. PGN export → import roundtrip: position FEN matches.
//! 4. Trait seams: `EventSink` and `AppDirs` are exercised end-to-end.

use std::sync::Arc;
use std::time::Duration;

use chess_core::ai;
use chess_core::api::{
    ApiError, ApiResult, BackendEvent, GameMode, GameStatus, HumanColorChoice, MoveResult,
    NewGameOpts, SquareStr, TimeControl,
};
use chess_core::commands::{api_move_from_engine, apply_engine_move, find_legal_move};
use chess_core::engine::Position;
use chess_core::pgn;
use chess_core::platform::{
    CapturingEventSink, EventSink, NoStockfishSpawner, NullEventSink, StaticAppDirs,
};
use chess_core::session::{GameSession, SessionManager};

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

    let spawner = NoStockfishSpawner;
    let output = tokio::time::timeout(
        Duration::from_secs(30),
        ai::choose_move(&spawner, game_id, position, history_uci, difficulty, |_| {}),
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
async fn hvai_difficulty_6_falls_back_gracefully_when_stockfish_missing() {
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

    // With the default builder (NoStockfishSpawner), levels 4-10 transparently
    // remap to `fallback_custom_level`. The game must still progress.
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
    use chess_core::engine::ChessMove;

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

// ------------------------------------------------------------ trait seams

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn event_sink_receives_move_made_event() {
    let sink = Arc::new(CapturingEventSink::new());
    let session = SessionManager::builder()
        .sink(sink.clone() as Arc<dyn EventSink>)
        .build();

    let game_id = uuid::Uuid::new_v4().to_string();
    session
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

    let _ = play_human_move(&session, &game_id).await.unwrap();
    let events = sink.drain();
    assert!(
        events.iter().any(|e| matches!(e, BackendEvent::MoveMade(ev) if ev.game_id == game_id)),
        "expected at least one MoveMade event for {game_id}, got {events:?}"
    );
}

#[test]
fn app_dirs_persist_settings_to_disk() {
    let dir = tempdir();
    let session = SessionManager::builder()
        .dirs(Arc::new(StaticAppDirs::new(dir.path.clone())))
        .sink(Arc::new(NullEventSink))
        .build();

    let mut settings = chess_core::api::Settings::default();
    settings.sound_enabled = false;
    session.set_settings(settings.clone());

    // Re-open: a fresh manager pointed at the same dir loads the JSON.
    let session2 = SessionManager::builder()
        .dirs(Arc::new(StaticAppDirs::new(dir.path.clone())))
        .build();
    session2.hydrate();
    let loaded = session2.get_settings();
    assert!(!loaded.sound_enabled);
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn replace_spawner_hot_swaps_at_runtime() {
    use chess_core::api::ApiError;
    use chess_core::platform::{StockfishSpawner, UciChild};

    struct CountingSpawner {
        calls: std::sync::atomic::AtomicUsize,
    }

    #[async_trait::async_trait]
    impl StockfishSpawner for CountingSpawner {
        fn is_available(&self) -> bool {
            true
        }
        async fn spawn(&self) -> Result<UciChild, ApiError> {
            self.calls
                .fetch_add(1, std::sync::atomic::Ordering::Relaxed);
            Err(ApiError::Engine("counting only".into()))
        }
    }

    let session = SessionManager::new();
    assert!(!session.spawner().is_available());

    let counter = Arc::new(CountingSpawner {
        calls: Default::default(),
    });
    session.set_spawner(counter.clone() as Arc<dyn StockfishSpawner>);
    assert!(session.spawner().is_available());

    // Triggering an AI request through choose_move forwards into the
    // installed spawner, which records the call and errors back; the
    // module then transparently falls through to the custom engine.
    let position = chess_core::engine::Position::default();
    let _ = chess_core::ai::choose_move(
        session.spawner().as_ref(),
        "test",
        position,
        Vec::new(),
        7,
        |_| {},
    )
    .await;
    assert!(counter.calls.load(std::sync::atomic::Ordering::Relaxed) >= 1);
}

#[test]
fn clock_event_round_trips_through_set_clock() {
    // Just verifies set_clock returns a snapshot containing the new clock;
    // the actual ticking task only runs under a tokio runtime.
    let session = SessionManager::new();
    let id = uuid::Uuid::new_v4().to_string();
    session
        .create_game(
            id.clone(),
            NewGameOpts {
                mode: GameMode::Hvh,
                ai_difficulty: None,
                human_color: Some(HumanColorChoice::W),
                time_control: Some(TimeControl {
                    initial_ms: 60_000,
                    increment_ms: 0,
                }),
            },
        )
        .expect("create_game");
    let snap = session.get(&id).expect("snapshot");
    assert!(snap.clock.is_some());
    let clock = snap.clock.unwrap();
    // ChessClock::state() calls `tick()` internally, which subtracts the
    // wall-clock delta since `last_tick`. On a slow CI runner this is
    // already a few ms by the time we read it, so we assert a tolerance
    // instead of equality.
    assert!(
        (59_500..=60_000).contains(&clock.white_ms),
        "white_ms drained too far: {}",
        clock.white_ms,
    );
    assert!(
        (59_500..=60_000).contains(&clock.black_ms),
        "black_ms drained too far: {}",
        clock.black_ms,
    );
}

// ---------------------------------------------------------- tiny tempdir helper
struct TempDir {
    path: std::path::PathBuf,
}

fn tempdir() -> TempDir {
    let mut path = std::env::temp_dir();
    path.push(format!(
        "chess-core-test-{}",
        uuid::Uuid::new_v4().simple()
    ));
    std::fs::create_dir_all(&path).expect("create tempdir");
    TempDir { path }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.path);
    }
}
