//! Public Dart-facing API surface.
//!
//! Every function below corresponds 1:1 to a legacy Tauri command in
//! `legacy/tauri/src/lib.rs`. Argument shapes are byte-compatible with
//! the JSON payloads the Svelte client used (see
//! `legacy/svelte/lib/api/contract.ts`).
//!
//! The four push events from the original contract (`move-made`,
//! `ai-progress`, `game-over`, `clock-tick`) are unified into a single
//! [`BackendEvent`] broadcast stream, exposed via [`subscribe_events`].

use std::path::PathBuf;
use std::sync::Arc;

use flutter_rust_bridge::frb;

use crate::frb_generated::StreamSink;

use chess_core::commands as cmd;
use chess_core::platform::{ArcDirs, ArcSink, ArcSpawner, StaticAppDirs};
use chess_core::session::SessionManager;

use crate::broadcast::{BroadcastSink, BROADCAST};
use crate::platform;

// ---------------------------------------------------------------------------
// Re-exported types (codegen mirrors them on the Dart side)
// ---------------------------------------------------------------------------

pub use chess_core::api::{
    Accent, AiProgressEvent, ApiError, AppTheme, BackendEvent, BoardTheme, ClockState,
    ClockTickEvent, Color, GameMode, GameOverEvent, GameResult, GameSnapshot, GameStatus,
    HumanColorChoice, Move, MoveMadeEvent, MoveResult, NewGameOpts, Piece, PieceKind, PieceSet,
    Promotion, Settings, TimeControl,
};

// ---------------------------------------------------------------------------
// Init
// ---------------------------------------------------------------------------

/// One-time bootstrap. Dart calls this with the writable application
/// data directory (from `path_provider`) before issuing any command.
#[frb(sync)]
pub fn bridge_init(data_dir: String) -> Result<(), String> {
    if crate::try_session().is_some() {
        return Ok(());
    }

    let dirs: ArcDirs = Arc::new(StaticAppDirs::new(PathBuf::from(data_dir)));
    let broadcast = BROADCAST
        .get_or_init(|| Arc::new(BroadcastSink::default()))
        .clone();
    let sink: ArcSink = broadcast;
    let spawner: ArcSpawner = platform::default_spawner();

    let session = SessionManager::builder()
        .dirs(dirs)
        .sink(sink)
        .spawner(spawner)
        .build();
    session.hydrate();

    crate::install_session(session);
    Ok(())
}

/// Subscribe to push events. flutter_rust_bridge turns
/// `StreamSink<BackendEvent>` into a Dart `Stream<BackendEvent>`.
pub fn subscribe_events(sink: StreamSink<BackendEvent>) -> Result<(), String> {
    let broadcast = BROADCAST
        .get_or_init(|| Arc::new(BroadcastSink::default()))
        .clone();
    broadcast.attach(Box::new(move |event| {
        let _ = sink.add(event);
    }));
    Ok(())
}

/// Override the Stockfish spawner with an explicit binary path. The
/// Flutter Android plugin code calls this after extracting the binary
/// out of `assets/stockfish/<abi>/stockfish`, chmod 0755'ing it.
///
/// No-op today: hot-swapping the spawner on a live session would
/// require a `SessionManager::replace_spawner` seam. We log and accept
/// silently; for now Android needs to stage the binary and call
/// [`bridge_init`] before the first AI request.
#[frb(sync)]
pub fn bridge_provide_external_stockfish(binary_path: String) -> Result<(), String> {
    log::info!(
        "bridge_provide_external_stockfish({}): pending hot-swap support",
        binary_path
    );
    Ok(())
}

// ---------------------------------------------------------------------------
// Commands (one per legacy Tauri command)
// ---------------------------------------------------------------------------

pub async fn new_game(opts: NewGameOpts) -> Result<GameSnapshot, ApiError> {
    cmd::new_game(crate::session(), opts).await
}

pub async fn legal_moves_from(
    game_id: String,
    square: String,
) -> Result<Vec<String>, ApiError> {
    cmd::legal_moves_from(crate::session(), game_id, square).await
}

pub async fn make_move(
    game_id: String,
    from: String,
    to: String,
    promotion: Option<Promotion>,
) -> Result<MoveResult, ApiError> {
    cmd::make_move(crate::session(), game_id, from, to, promotion).await
}

pub async fn request_ai_move(game_id: String) -> Result<(), ApiError> {
    cmd::request_ai_move(crate::session(), game_id).await
}

pub async fn undo_move(game_id: String) -> Result<GameSnapshot, ApiError> {
    cmd::undo_move(crate::session(), game_id).await
}

pub async fn resign(game_id: String) -> Result<GameSnapshot, ApiError> {
    cmd::resign(crate::session(), game_id).await
}

pub async fn offer_draw(game_id: String) -> Result<GameSnapshot, ApiError> {
    cmd::offer_draw(crate::session(), game_id).await
}

pub async fn claim_draw(game_id: String) -> Result<GameSnapshot, ApiError> {
    cmd::claim_draw(crate::session(), game_id).await
}

pub async fn load_pgn(pgn: String) -> Result<GameSnapshot, ApiError> {
    cmd::load_pgn(crate::session(), pgn).await
}

pub async fn export_pgn(game_id: String) -> Result<String, ApiError> {
    cmd::export_pgn(crate::session(), game_id).await
}

pub async fn set_clock(
    game_id: String,
    time_control: TimeControl,
) -> Result<GameSnapshot, ApiError> {
    cmd::set_clock(crate::session(), game_id, time_control).await
}

pub async fn pause_clock(game_id: String) -> Result<GameSnapshot, ApiError> {
    cmd::pause_clock(crate::session(), game_id).await
}

pub async fn resume_clock(game_id: String) -> Result<GameSnapshot, ApiError> {
    cmd::resume_clock(crate::session(), game_id).await
}

pub async fn get_settings() -> Result<Settings, ApiError> {
    cmd::get_settings(crate::session()).await
}

pub async fn set_settings(settings: Settings) -> Result<Settings, ApiError> {
    cmd::set_settings(crate::session(), settings).await
}

/// Returns the current snapshot for a game, or `None` if it does not exist.
pub fn snapshot(game_id: String) -> Option<GameSnapshot> {
    crate::session().get(&game_id)
}
