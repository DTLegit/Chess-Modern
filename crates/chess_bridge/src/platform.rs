//! Platform-specific [`StockfishSpawner`] selection and the spawner used
//! by Flutter on host platforms (macOS, Windows, Linux, Android).

use std::path::PathBuf;
use std::pin::Pin;
use std::process::Stdio;
use std::sync::Arc;

use async_trait::async_trait;
use chess_core::api::ApiError;
use chess_core::platform::{ArcSpawner, NoStockfishSpawner, StockfishSpawner, UciChild};
use tokio::io::{AsyncRead, AsyncWrite};

/// Choose the [`StockfishSpawner`] for the current target.
///
/// Desktop: spawn the bundled sidecar binary discovered next to the
///          Flutter app at runtime (set via `bridge_provide_external_stockfish`
///          or auto-discovered by `discover_desktop_path`).
/// Android: same shape as desktop, but the binary is extracted out of
///          assets by Dart before [`bridge_provide_external_stockfish`]
///          installs the path.
/// iOS:     no Stockfish (sandbox forbids spawning child processes).
pub fn default_spawner() -> ArcSpawner {
    if cfg!(target_os = "ios") {
        return Arc::new(NoStockfishSpawner);
    }
    if let Some(path) = discover_desktop_path() {
        return Arc::new(BinaryStockfishSpawner { path });
    }
    Arc::new(NoStockfishSpawner)
}

/// Returns a spawner pointed at the supplied binary. Used by Android
/// after extracting the per-ABI binary out of Flutter assets.
pub fn external_spawner(path: PathBuf) -> ArcSpawner {
    Arc::new(BinaryStockfishSpawner { path })
}

/// Best-effort discovery of the Stockfish sidecar next to the Flutter
/// app bundle. Falls back to `None` when nothing executable is found;
/// the AI module then routes to the custom Rust engine.
fn discover_desktop_path() -> Option<PathBuf> {
    let exe = std::env::current_exe().ok()?;
    let dir = exe.parent()?;
    let candidates = [
        dir.join(if cfg!(windows) { "stockfish.exe" } else { "stockfish" }),
        dir.join("data").join(if cfg!(windows) { "stockfish.exe" } else { "stockfish" }),
        dir.join("..").join("Resources").join("stockfish"),
    ];
    candidates.into_iter().find(|p| p.exists())
}

/// Spawns a Stockfish executable at a known on-disk path.
pub struct BinaryStockfishSpawner {
    path: PathBuf,
}

#[async_trait]
impl StockfishSpawner for BinaryStockfishSpawner {
    fn is_available(&self) -> bool {
        // We trust whoever installed the path; AI module will fall back
        // gracefully if the spawn itself fails.
        self.path.is_file()
    }

    async fn spawn(&self) -> Result<UciChild, ApiError> {
        let mut child = tokio::process::Command::new(&self.path)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .kill_on_drop(true)
            .spawn()
            .map_err(|e| ApiError::Engine(format!("stockfish spawn: {e}")))?;

        let stdin = child
            .stdin
            .take()
            .ok_or_else(|| ApiError::Engine("stockfish stdin missing".into()))?;
        let stdout = child
            .stdout
            .take()
            .ok_or_else(|| ApiError::Engine("stockfish stdout missing".into()))?;
        let stderr = child.stderr.take();

        let stdin: Pin<Box<dyn AsyncWrite + Send>> = Box::pin(stdin);
        let stdout: Pin<Box<dyn AsyncRead + Send>> = Box::pin(stdout);
        let stderr: Option<Pin<Box<dyn AsyncRead + Send>>> =
            stderr.map(|s| Box::pin(s) as Pin<Box<dyn AsyncRead + Send>>);

        let kill_handle = parking_lot::Mutex::new(Some(child));
        let kill_handle = Arc::new(kill_handle);
        let kill_handle_for_box = kill_handle.clone();

        Ok(UciChild {
            stdin,
            stdout,
            stderr,
            kill: Box::new(move || {
                if let Some(mut child) = kill_handle_for_box.lock().take() {
                    let _ = child.start_kill();
                }
            }),
        })
    }
}
