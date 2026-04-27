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
// Re-exported types — mirror declarations so codegen generates concrete
// Dart classes/enums (otherwise frb leaves them as opaque Rust handles).
// ---------------------------------------------------------------------------

pub use chess_core::api::{
    Accent, AiProgressEvent, ApiError, AppTheme, BackendEvent, BoardTheme, ClockState,
    ClockTickEvent, Color, GameMode, GameOverEvent, GameResult, GameSnapshot, GameStatus,
    HumanColorChoice, Move, MoveMadeEvent, MoveResult, NewGameOpts, Piece, PieceKind, PieceSet,
    Promotion, Settings, TimeControl,
};

#[frb(mirror(Color))]
pub enum _MirrorColor {
    W,
    B,
}

#[frb(mirror(PieceKind))]
pub enum _MirrorPieceKind {
    P,
    N,
    B,
    R,
    Q,
    K,
}

#[frb(mirror(Piece))]
pub struct _MirrorPiece {
    pub color: Color,
    pub kind: PieceKind,
}

#[frb(mirror(Promotion))]
pub enum _MirrorPromotion {
    N,
    B,
    R,
    Q,
}

#[frb(mirror(Move))]
pub struct _MirrorMove {
    pub from: String,
    pub to: String,
    pub promotion: Option<Promotion>,
    pub san: String,
    pub uci: String,
    pub captured: Option<Piece>,
    pub is_check: bool,
    pub is_mate: bool,
    pub is_castle: bool,
    pub is_en_passant: bool,
}

#[frb(mirror(GameStatus))]
pub enum _MirrorGameStatus {
    Active,
    Checkmate,
    Stalemate,
    DrawFiftyMove,
    DrawThreefold,
    DrawInsufficient,
    DrawAgreement,
    Resigned,
    TimeForfeit,
}

#[frb(mirror(GameResult))]
pub enum _MirrorGameResult {
    White,
    Black,
    Draw,
    Ongoing,
}

#[frb(mirror(ClockState))]
pub struct _MirrorClockState {
    pub white_ms: u64,
    pub black_ms: u64,
    pub active: Option<Color>,
    pub paused: bool,
}

#[frb(mirror(GameSnapshot))]
pub struct _MirrorGameSnapshot {
    pub game_id: String,
    pub fen: String,
    pub turn: Color,
    pub in_check: bool,
    pub status: GameStatus,
    pub result: GameResult,
    pub history: Vec<Move>,
    pub legal_moves: std::collections::HashMap<String, Vec<String>>,
    pub clock: Option<ClockState>,
    pub mode: GameMode,
    pub ai_difficulty: Option<u8>,
    pub human_color: Option<Color>,
    pub last_move: Option<Move>,
}

#[frb(mirror(MoveResult))]
pub struct _MirrorMoveResult {
    pub mv: Move,
    pub snapshot: GameSnapshot,
}

#[frb(mirror(GameMode))]
pub enum _MirrorGameMode {
    Hvh,
    Hva,
}

#[frb(mirror(HumanColorChoice))]
pub enum _MirrorHumanColorChoice {
    W,
    B,
    Random,
}

#[frb(mirror(TimeControl))]
pub struct _MirrorTimeControl {
    pub initial_ms: u64,
    pub increment_ms: u64,
}

#[frb(mirror(NewGameOpts))]
pub struct _MirrorNewGameOpts {
    pub mode: GameMode,
    pub ai_difficulty: Option<u8>,
    pub human_color: Option<HumanColorChoice>,
    pub time_control: Option<TimeControl>,
}

#[frb(mirror(BoardTheme))]
pub enum _MirrorBoardTheme {
    Wood,
    Slate,
    WoodRealistic,
    SlateRealistic,
    Marble,
    Emerald,
    Obsidian,
    Sandstone,
    Midnight,
}

#[frb(mirror(AppTheme))]
pub enum _MirrorAppTheme {
    Light,
    Dark,
    Blue,
}

#[frb(mirror(PieceSet))]
pub enum _MirrorPieceSet {
    Classic,
    Modern,
    Merida,
    Minimal,
}

#[frb(mirror(Accent))]
pub enum _MirrorAccent {
    Walnut,
    Forest,
    Violet,
    Teal,
    Rose,
}

#[frb(mirror(Settings))]
pub struct _MirrorSettings {
    pub app_theme: AppTheme,
    pub board_theme: BoardTheme,
    pub piece_set: PieceSet,
    pub accent: Accent,
    pub sound_enabled: bool,
    pub sound_volume: f32,
    pub show_legal_moves: bool,
    pub show_coordinates: bool,
    pub show_last_move: bool,
}

#[frb(mirror(MoveMadeEvent))]
pub struct _MirrorMoveMadeEvent {
    pub game_id: String,
    pub mv: Move,
    pub snapshot: GameSnapshot,
}

#[frb(mirror(AiProgressEvent))]
pub struct _MirrorAiProgressEvent {
    pub game_id: String,
    pub depth: u32,
    pub eval_cp: i32,
    pub pv_san: Vec<String>,
}

#[frb(mirror(GameOverEvent))]
pub struct _MirrorGameOverEvent {
    pub game_id: String,
    pub result: GameResult,
    pub reason: GameStatus,
}

#[frb(mirror(ClockTickEvent))]
pub struct _MirrorClockTickEvent {
    pub game_id: String,
    pub white_ms: u64,
    pub black_ms: u64,
    pub active: Option<Color>,
}

#[frb(mirror(BackendEvent))]
pub enum _MirrorBackendEvent {
    MoveMade(MoveMadeEvent),
    AiProgress(AiProgressEvent),
    GameOver(GameOverEvent),
    ClockTick(ClockTickEvent),
}

#[frb(mirror(ApiError))]
pub enum _MirrorApiError {
    GameNotFound(String),
    IllegalMove(String),
    InvalidInput(String),
    Engine(String),
    Internal(String),
}

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
#[frb(sync)]
pub fn bridge_provide_external_stockfish(binary_path: String) -> Result<(), String> {
    let session = crate::try_session().ok_or("bridge_init must be called first")?;
    let path = std::path::PathBuf::from(&binary_path);
    if !path.is_file() {
        return Err(format!(
            "stockfish binary not found at {}",
            path.display()
        ));
    }
    session.set_spawner(platform::external_spawner(path));
    log::info!("stockfish spawner installed: {}", binary_path);
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
