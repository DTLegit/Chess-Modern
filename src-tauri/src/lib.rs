//! Legacy Tauri shell — translates between the platform-agnostic
//! [`chess_core`] crate and the Tauri runtime.
//!
//! The Flutter app under `flutter/` is the shipping UI. This shell is
//! preserved for reference and parity testing; it builds against
//! `chess_core` through the trait seams (`AppDirs`, `EventSink`,
//! `StockfishSpawner`).

use std::sync::{Arc, Mutex};

use async_trait::async_trait;
use tauri::{AppHandle, Emitter, Manager};
use tauri_plugin_shell::{process::{CommandChild, CommandEvent}, ShellExt};
use tauri_specta::{collect_commands, collect_events, Builder};
use tokio::sync::mpsc;

use chess_core::api::{
    AiProgressEvent, ApiError, ApiResult, BackendEvent, ClockTickEvent, GameId, GameOverEvent,
    GameSnapshot, MoveMadeEvent, MoveResult, NewGameOpts, Promotion, Settings, SquareStr,
    TimeControl,
};
use chess_core::commands as core_cmd;
use chess_core::platform::{AppDirs, ArcDirs, ArcSink, ArcSpawner, EventSink, StockfishSpawner, UciChild};
use chess_core::session::SessionManager;

// Re-export so existing test/example code can keep importing `chess_lib::*`.
pub use chess_core::{ai, api, clock, engine, pgn, platform, session};

// ---------------------------------------------------------------------------
// Tauri impls of the chess_core traits
// ---------------------------------------------------------------------------

struct TauriAppDirs {
    app: AppHandle,
}

impl AppDirs for TauriAppDirs {
    fn data_dir(&self) -> Option<std::path::PathBuf> {
        self.app.path().app_data_dir().ok()
    }
}

struct TauriEventSink {
    app: AppHandle,
}

impl EventSink for TauriEventSink {
    fn emit(&self, event: BackendEvent) {
        let name = event.name();
        match event {
            BackendEvent::MoveMade(ev) => {
                let _ = self.app.emit(name, ev);
            }
            BackendEvent::AiProgress(ev) => {
                let _ = self.app.emit(name, ev);
            }
            BackendEvent::GameOver(ev) => {
                let _ = self.app.emit(name, ev);
            }
            BackendEvent::ClockTick(ev) => {
                let _ = self.app.emit(name, ev);
            }
        }
    }
}

struct TauriStockfishSpawner {
    app: AppHandle,
}

#[async_trait]
impl StockfishSpawner for TauriStockfishSpawner {
    fn is_available(&self) -> bool {
        sidecar_looks_real()
    }

    async fn spawn(&self) -> ApiResult<UciChild> {
        // Bridge `tauri_plugin_shell`'s sidecar (which uses tokio mpsc
        // channels, not raw stdio) into the AsyncRead/AsyncWrite shape
        // chess_core expects.
        let (mut rx, child) = self
            .app
            .shell()
            .sidecar("binaries/stockfish")
            .map_err(|e| ApiError::Engine(format!("stockfish sidecar: {e}")))?
            .spawn()
            .map_err(|e| ApiError::Engine(format!("stockfish spawn: {e}")))?;

        let child = Arc::new(Mutex::new(Some(child)));

        let (stdout_tx, stdout_rx) = mpsc::unbounded_channel::<Vec<u8>>();
        let (stderr_tx, stderr_rx) = mpsc::unbounded_channel::<Vec<u8>>();
        tokio::spawn(async move {
            while let Some(event) = rx.recv().await {
                match event {
                    CommandEvent::Stdout(bytes) => {
                        let _ = stdout_tx.send(bytes);
                    }
                    CommandEvent::Stderr(bytes) => {
                        let _ = stderr_tx.send(bytes);
                    }
                    CommandEvent::Terminated(_) | CommandEvent::Error(_) => break,
                    _ => {}
                }
            }
        });

        let writer_handle = child.clone();
        let kill_handle = child.clone();

        let stdin: std::pin::Pin<Box<dyn tokio::io::AsyncWrite + Send>> = Box::pin(SidecarStdin { child: writer_handle });
        let stdout: std::pin::Pin<Box<dyn tokio::io::AsyncRead + Send>> =
            Box::pin(MpscReader::new(stdout_rx));
        let stderr: std::pin::Pin<Box<dyn tokio::io::AsyncRead + Send>> =
            Box::pin(MpscReader::new(stderr_rx));

        Ok(UciChild {
            stdin,
            stdout,
            stderr: Some(stderr),
            kill: Box::new(move || {
                if let Some(c) = kill_handle.lock().unwrap().take() {
                    let _ = c.kill();
                }
            }),
        })
    }
}

// AsyncWrite that forwards bytes into the Tauri sidecar's writer.
struct SidecarStdin {
    child: Arc<Mutex<Option<CommandChild>>>,
}

impl tokio::io::AsyncWrite for SidecarStdin {
    fn poll_write(
        self: std::pin::Pin<&mut Self>,
        _cx: &mut std::task::Context<'_>,
        buf: &[u8],
    ) -> std::task::Poll<std::io::Result<usize>> {
        let this = self.get_mut();
        let mut guard = this.child.lock().unwrap();
        let Some(child) = guard.as_mut() else {
            return std::task::Poll::Ready(Ok(0));
        };
        match child.write(buf) {
            Ok(()) => std::task::Poll::Ready(Ok(buf.len())),
            Err(e) => std::task::Poll::Ready(Err(std::io::Error::new(std::io::ErrorKind::Other, e))),
        }
    }

    fn poll_flush(
        self: std::pin::Pin<&mut Self>,
        _cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<std::io::Result<()>> {
        std::task::Poll::Ready(Ok(()))
    }

    fn poll_shutdown(
        self: std::pin::Pin<&mut Self>,
        _cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<std::io::Result<()>> {
        std::task::Poll::Ready(Ok(()))
    }
}

// Adapts an unbounded mpsc receiver to AsyncRead.
struct MpscReader {
    rx: mpsc::UnboundedReceiver<Vec<u8>>,
    leftover: Vec<u8>,
    closed: bool,
}

impl MpscReader {
    fn new(rx: mpsc::UnboundedReceiver<Vec<u8>>) -> Self {
        Self {
            rx,
            leftover: Vec::new(),
            closed: false,
        }
    }
}

impl tokio::io::AsyncRead for MpscReader {
    fn poll_read(
        self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
        buf: &mut tokio::io::ReadBuf<'_>,
    ) -> std::task::Poll<std::io::Result<()>> {
        let this = self.get_mut();
        if !this.leftover.is_empty() {
            let n = this.leftover.len().min(buf.remaining());
            buf.put_slice(&this.leftover[..n]);
            this.leftover.drain(..n);
            return std::task::Poll::Ready(Ok(()));
        }
        if this.closed {
            return std::task::Poll::Ready(Ok(()));
        }
        match this.rx.poll_recv(cx) {
            std::task::Poll::Ready(Some(bytes)) => {
                let n = bytes.len().min(buf.remaining());
                buf.put_slice(&bytes[..n]);
                if n < bytes.len() {
                    this.leftover = bytes[n..].to_vec();
                }
                std::task::Poll::Ready(Ok(()))
            }
            std::task::Poll::Ready(None) => {
                this.closed = true;
                std::task::Poll::Ready(Ok(()))
            }
            std::task::Poll::Pending => std::task::Poll::Pending,
        }
    }
}

fn sidecar_looks_real() -> bool {
    let triple = target_triple();
    let exe = if cfg!(windows) { ".exe" } else { "" };
    let path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("binaries")
        .join(format!("stockfish-{triple}{exe}"));
    let Ok(bytes) = std::fs::read(path) else {
        return false;
    };
    bytes.starts_with(&[0x7f, b'E', b'L', b'F'])
        || bytes.starts_with(&[0xcf, 0xfa, 0xed, 0xfe])
        || bytes.starts_with(&[0xca, 0xfe, 0xba, 0xbe])
        || bytes.starts_with(&[0xfe, 0xed, 0xfa, 0xcf])
        || bytes.starts_with(b"MZ")
}

fn target_triple() -> &'static str {
    if cfg!(all(target_os = "macos", target_arch = "aarch64")) {
        "aarch64-apple-darwin"
    } else if cfg!(all(target_os = "macos", target_arch = "x86_64")) {
        "x86_64-apple-darwin"
    } else if cfg!(all(target_os = "linux", target_arch = "x86_64")) {
        "x86_64-unknown-linux-gnu"
    } else if cfg!(all(target_os = "windows", target_arch = "x86_64")) {
        "x86_64-pc-windows-msvc"
    } else {
        "unknown"
    }
}

// ---------------------------------------------------------------------------
// Tauri command surface — thin wrappers over chess_core::commands::*
// ---------------------------------------------------------------------------

#[tauri::command]
#[specta::specta]
async fn new_game(
    session: tauri::State<'_, SessionManager>,
    opts: NewGameOpts,
) -> ApiResult<GameSnapshot> {
    core_cmd::new_game(&session, opts).await
}

#[tauri::command]
#[specta::specta]
async fn legal_moves_from(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
    square: SquareStr,
) -> ApiResult<Vec<SquareStr>> {
    core_cmd::legal_moves_from(&session, game_id, square).await
}

#[tauri::command]
#[specta::specta]
async fn make_move(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
    from: SquareStr,
    to: SquareStr,
    promotion: Option<Promotion>,
) -> ApiResult<MoveResult> {
    core_cmd::make_move(&session, game_id, from, to, promotion).await
}

#[tauri::command]
#[specta::specta]
async fn request_ai_move(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<()> {
    core_cmd::request_ai_move(&session, game_id).await
}

#[tauri::command]
#[specta::specta]
async fn undo_move(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    core_cmd::undo_move(&session, game_id).await
}

#[tauri::command]
#[specta::specta]
async fn resign(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    core_cmd::resign(&session, game_id).await
}

#[tauri::command]
#[specta::specta]
async fn offer_draw(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    core_cmd::offer_draw(&session, game_id).await
}

#[tauri::command]
#[specta::specta]
async fn claim_draw(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    core_cmd::claim_draw(&session, game_id).await
}

#[tauri::command]
#[specta::specta]
async fn load_pgn(
    session: tauri::State<'_, SessionManager>,
    pgn: String,
) -> ApiResult<GameSnapshot> {
    core_cmd::load_pgn(&session, pgn).await
}

#[tauri::command]
#[specta::specta]
async fn export_pgn(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<String> {
    core_cmd::export_pgn(&session, game_id).await
}

#[tauri::command]
#[specta::specta]
async fn set_clock(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
    time_control: TimeControl,
) -> ApiResult<GameSnapshot> {
    core_cmd::set_clock(&session, game_id, time_control).await
}

#[tauri::command]
#[specta::specta]
async fn pause_clock(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    core_cmd::pause_clock(&session, game_id).await
}

#[tauri::command]
#[specta::specta]
async fn resume_clock(
    session: tauri::State<'_, SessionManager>,
    game_id: GameId,
) -> ApiResult<GameSnapshot> {
    core_cmd::resume_clock(&session, game_id).await
}

#[tauri::command]
#[specta::specta]
async fn get_settings(session: tauri::State<'_, SessionManager>) -> ApiResult<Settings> {
    core_cmd::get_settings(&session).await
}

#[tauri::command]
#[specta::specta]
async fn set_settings(
    session: tauri::State<'_, SessionManager>,
    settings: Settings,
) -> ApiResult<Settings> {
    core_cmd::set_settings(&session, settings).await
}

// ---------------------------------------------------------------------------
// specta builder + entrypoint
// ---------------------------------------------------------------------------

pub fn build_specta_builder() -> Builder<tauri::Wry> {
    Builder::<tauri::Wry>::new()
        .commands(collect_commands![
            new_game,
            legal_moves_from,
            make_move,
            request_ai_move,
            undo_move,
            resign,
            offer_draw,
            claim_draw,
            load_pgn,
            export_pgn,
            set_clock,
            pause_clock,
            resume_clock,
            get_settings,
            set_settings,
        ])
        .events(collect_events![
            MoveMadeEvent,
            AiProgressEvent,
            GameOverEvent,
            ClockTickEvent,
        ])
}

pub fn export_typescript_bindings(path: &str) -> Result<(), specta_typescript::Error> {
    let builder = build_specta_builder();
    builder.export(
        specta_typescript::Typescript::default()
            .header("// AUTO-GENERATED by tauri-specta. Do not edit by hand.\n"),
        path,
    )
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let specta_builder = build_specta_builder();

    #[cfg(debug_assertions)]
    specta_builder
        .export(
            specta_typescript::Typescript::default()
                .header("// AUTO-GENERATED by tauri-specta. Do not edit by hand.\n"),
            "../legacy/svelte/lib/api/bindings.ts",
        )
        .ok();

    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(specta_builder.invoke_handler())
        .setup(move |app| {
            let app_handle = app.handle().clone();
            let dirs: ArcDirs = Arc::new(TauriAppDirs { app: app_handle.clone() });
            let sink: ArcSink = Arc::new(TauriEventSink { app: app_handle.clone() });
            let spawner: ArcSpawner = Arc::new(TauriStockfishSpawner { app: app_handle.clone() });
            let session = SessionManager::builder()
                .dirs(dirs)
                .sink(sink)
                .spawner(spawner)
                .build();
            session.hydrate();
            app.manage(session);
            specta_builder.mount_events(app);
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running Chess application");
}

