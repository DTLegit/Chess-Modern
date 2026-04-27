//! Platform-agnostic seams for the chess core.
//!
//! The core does not import `tauri::*` or any platform-specific symbol.
//! Instead it talks to three small traits that the embedding shell
//! (Tauri desktop, Flutter desktop, Flutter mobile) implements.

use std::path::PathBuf;
use std::pin::Pin;
use std::sync::Arc;

use async_trait::async_trait;
use tokio::io::{AsyncRead, AsyncWrite};

use crate::api::{ApiError, BackendEvent};

// ---------------------------------------------------------------------------
// AppDirs — where to persist settings + last-game JSON
// ---------------------------------------------------------------------------

/// Resolves the directory the core uses for persistent JSON state.
///
/// Tauri provides this through `AppHandle::path().app_data_dir()`.
/// flutter_rust_bridge fills it from Dart's `path_provider`.
/// Tests pass a `PathBuf` directly via [`StaticAppDirs`].
pub trait AppDirs: Send + Sync + 'static {
    /// Root directory for chess persistence (must be writable). The core
    /// joins `chess/{settings,last-game}.json` underneath it, mirroring
    /// the legacy Tauri layout.
    fn data_dir(&self) -> Option<PathBuf>;
}

/// Convenience impl that always returns the same configured directory.
#[derive(Debug, Clone)]
pub struct StaticAppDirs {
    pub root: PathBuf,
}

impl StaticAppDirs {
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }
}

impl AppDirs for StaticAppDirs {
    fn data_dir(&self) -> Option<PathBuf> {
        Some(self.root.clone())
    }
}

/// In-process default that disables persistence (useful for tests / mocks).
#[derive(Debug, Default, Clone, Copy)]
pub struct EphemeralAppDirs;

impl AppDirs for EphemeralAppDirs {
    fn data_dir(&self) -> Option<PathBuf> {
        None
    }
}

// ---------------------------------------------------------------------------
// EventSink — push-channel for the four backend events
// ---------------------------------------------------------------------------

/// Sink that receives [`BackendEvent`]s from the core.
///
/// The Tauri shell forwards each call to `AppHandle::emit(name, payload)`
/// using the original event names. The Flutter bridge forwards to a
/// `flutter_rust_bridge::StreamSink<BackendEvent>` so Dart sees a single
/// broadcast `Stream`.
pub trait EventSink: Send + Sync + 'static {
    fn emit(&self, event: BackendEvent);
}

/// Discards every emitted event. Useful when the core is being driven
/// purely synchronously (smoke tests, headless CI).
#[derive(Debug, Default, Clone, Copy)]
pub struct NullEventSink;

impl EventSink for NullEventSink {
    fn emit(&self, _: BackendEvent) {}
}

/// Test impl that captures every event for later assertions.
#[derive(Debug, Default)]
pub struct CapturingEventSink {
    pub events: parking_lot::Mutex<Vec<BackendEvent>>,
}

impl CapturingEventSink {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn drain(&self) -> Vec<BackendEvent> {
        std::mem::take(&mut *self.events.lock())
    }
}

impl EventSink for CapturingEventSink {
    fn emit(&self, event: BackendEvent) {
        self.events.lock().push(event);
    }
}

// ---------------------------------------------------------------------------
// StockfishSpawner — UCI subprocess provider
// ---------------------------------------------------------------------------

/// A handle to a spawned Stockfish process.
///
/// The core only needs three things: write a UCI line, read the next
/// stdout/stderr line, and tear it down. This abstraction lets us swap
/// the desktop sidecar implementation (via `tauri_plugin_shell` or plain
/// `tokio::process`) for the Android implementation (which copies the
/// binary out of Flutter assets first), or for a "no Stockfish" stub on
/// iOS which transparently falls back to the custom Rust engine.
pub struct UciChild {
    pub stdin: Pin<Box<dyn AsyncWrite + Send>>,
    pub stdout: Pin<Box<dyn AsyncRead + Send>>,
    /// Optional stderr channel; if `None`, stderr is discarded.
    pub stderr: Option<Pin<Box<dyn AsyncRead + Send>>>,
    /// Best-effort terminator. Returning an error is logged but not fatal.
    pub kill: Box<dyn FnOnce() + Send>,
}

#[async_trait]
pub trait StockfishSpawner: Send + Sync + 'static {
    /// `false` short-circuits the AI module to the custom engine fallback.
    fn is_available(&self) -> bool;

    /// Launch the engine; only called when `is_available()` returned `true`.
    async fn spawn(&self) -> Result<UciChild, ApiError>;
}

/// Stub spawner used on iOS (and in tests) — Stockfish is unavailable
/// and the custom Rust engine handles every level.
#[derive(Debug, Default, Clone, Copy)]
pub struct NoStockfishSpawner;

#[async_trait]
impl StockfishSpawner for NoStockfishSpawner {
    fn is_available(&self) -> bool {
        false
    }

    async fn spawn(&self) -> Result<UciChild, ApiError> {
        Err(ApiError::Engine("stockfish unavailable on this platform".into()))
    }
}

// ---------------------------------------------------------------------------
// Convenience type alias
// ---------------------------------------------------------------------------

pub type ArcDirs = Arc<dyn AppDirs>;
pub type ArcSink = Arc<dyn EventSink>;
pub type ArcSpawner = Arc<dyn StockfishSpawner>;
