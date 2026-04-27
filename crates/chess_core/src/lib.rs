//! Platform-agnostic chess core.
//!
//! Provides:
//! - [`api`]: shared types and events (Rust↔UI contract).
//! - [`engine`], [`pgn`], [`clock`], [`ai`]: rules, persistence, AI.
//! - [`session::SessionManager`]: per-game state with persistence and clock tasks.
//! - [`commands`]: high-level entrypoints called by the Tauri shell and the
//!   Flutter `flutter_rust_bridge` bridge.
//! - [`platform`]: trait seams (`AppDirs`, `EventSink`, `StockfishSpawner`)
//!   that let the embedding choose how to persist data, deliver push
//!   events, and run the Stockfish subprocess.

pub mod api;
pub mod ai;
pub mod clock;
pub mod commands;
pub mod engine;
pub mod pgn;
pub mod platform;
pub mod session;
