//! Tauri command surface — the `invoke()` API exposed to the frontend.
//!
//! Phase 0 ships *stub implementations* so the frontend can compile and the
//! mock client can be exercised end-to-end. The backend subagent replaces
//! the bodies with real chess logic; the **signatures must remain stable**.

use std::collections::HashMap;

use crate::api::*;
use crate::session::SessionManager;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn standard_legal_moves_stub() -> HashMap<SquareStr, Vec<SquareStr>> {
    // Opening-position pseudo-legal hints so the UI has *something* to render
    // before the real engine is wired in.
    let mut m: HashMap<SquareStr, Vec<SquareStr>> = HashMap::new();
    let pawn_files = ["a", "b", "c", "d", "e", "f", "g", "h"];
    for f in pawn_files {
        m.insert(format!("{f}2"), vec![format!("{f}3"), format!("{f}4")]);
    }
    m.insert("b1".into(), vec!["a3".into(), "c3".into()]);
    m.insert("g1".into(), vec!["f3".into(), "h3".into()]);
    m
}

fn empty_snapshot(game_id: &str, opts: &NewGameOpts) -> GameSnapshot {
    GameSnapshot {
        game_id: game_id.into(),
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1".into(),
        turn: Color::W,
        in_check: false,
        status: GameStatus::Active,
        result: GameResult::Ongoing,
        history: vec![],
        legal_moves: standard_legal_moves_stub(),
        clock: opts.time_control.map(|tc| ClockState {
            white_ms: tc.initial_ms,
            black_ms: tc.initial_ms,
            active: Some(Color::W),
            paused: false,
        }),
        mode: opts.mode,
        ai_difficulty: opts.ai_difficulty,
        human_color: match opts.human_color {
            Some(HumanColorChoice::B) => Some(Color::B),
            Some(HumanColorChoice::W) | Some(HumanColorChoice::Random) | None => Some(Color::W),
        },
        last_move: None,
    }
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

#[tauri::command]
#[specta::specta]
pub async fn new_game(
    session: tauri::State<'_, SessionManager>,
    opts: NewGameOpts,
) -> ApiResult<GameSnapshot> {
    let id = uuid::Uuid::new_v4().to_string();
    let snap = empty_snapshot(&id, &opts);
    session.insert(id.clone(), snap.clone());
    Ok(snap)
}

#[tauri::command]
#[specta::specta]
pub async fn legal_moves_from(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
    square: SquareStr,
) -> ApiResult<Vec<SquareStr>> {
    let snap = session
        .get(&game_id)
        .ok_or_else(|| ApiError::GameNotFound(game_id.clone()))?;
    Ok(snap.legal_moves.get(&square).cloned().unwrap_or_default())
}

#[tauri::command]
#[specta::specta]
pub async fn make_move(
    _session: tauri::State<'_, SessionManager>,
    game_id: GameId,
    from: SquareStr,
    to: SquareStr,
    promotion: Option<Promotion>,
) -> ApiResult<MoveResult> {
    Err(ApiError::Engine(format!(
        "make_move stub: backend not yet implemented (game={game_id} {from}->{to} promo={promotion:?})"
    )))
}

#[tauri::command]
#[specta::specta]
pub async fn request_ai_move(
    _session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<()> {
    Err(ApiError::Engine(format!(
        "request_ai_move stub: backend not yet implemented (game={game_id})"
    )))
}

#[tauri::command]
#[specta::specta]
pub async fn undo_move(
    _session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    Err(ApiError::Engine(format!(
        "undo_move stub: backend not yet implemented (game={game_id})"
    )))
}

#[tauri::command]
#[specta::specta]
pub async fn resign(
    _session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    Err(ApiError::Engine(format!(
        "resign stub (game={game_id})"
    )))
}

#[tauri::command]
#[specta::specta]
pub async fn offer_draw(
    _session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    Err(ApiError::Engine(format!(
        "offer_draw stub (game={game_id})"
    )))
}

#[tauri::command]
#[specta::specta]
pub async fn claim_draw(
    _session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    Err(ApiError::Engine(format!(
        "claim_draw stub (game={game_id})"
    )))
}

#[tauri::command]
#[specta::specta]
pub async fn load_pgn(
    _session: tauri::State<'_, SessionManager>,
    pgn: String,
) -> ApiResult<GameSnapshot> {
    Err(ApiError::Engine(format!(
        "load_pgn stub ({} bytes)",
        pgn.len()
    )))
}

#[tauri::command]
#[specta::specta]
pub async fn export_pgn(
    _session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<String> {
    Err(ApiError::Engine(format!(
        "export_pgn stub (game={game_id})"
    )))
}

#[tauri::command]
#[specta::specta]
pub async fn set_clock(
    _session: tauri::State<'_, SessionManager>,
    game_id: GameId,
    time_control: TimeControl,
) -> ApiResult<GameSnapshot> {
    Err(ApiError::Engine(format!(
        "set_clock stub (game={game_id} init={}ms inc={}ms)",
        time_control.initial_ms, time_control.increment_ms
    )))
}

#[tauri::command]
#[specta::specta]
pub async fn pause_clock(
    _session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    Err(ApiError::Engine(format!(
        "pause_clock stub (game={game_id})"
    )))
}

#[tauri::command]
#[specta::specta]
pub async fn resume_clock(
    _session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    Err(ApiError::Engine(format!(
        "resume_clock stub (game={game_id})"
    )))
}

#[tauri::command]
#[specta::specta]
pub async fn get_settings(
    session: tauri::State<'_, SessionManager>,
) -> ApiResult<Settings> {
    Ok(session.get_settings())
}

#[tauri::command]
#[specta::specta]
pub async fn set_settings(
    session: tauri::State<'_, SessionManager>,
    settings: Settings,
) -> ApiResult<Settings> {
    session.set_settings(settings.clone());
    Ok(settings)
}
