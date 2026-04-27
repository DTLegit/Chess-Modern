# Migration: Svelte 5 + Tauri 2 → Flutter

This document records the single-shot migration of the Chess UI from
Svelte 5 + Tauri 2 to Flutter, while preserving the Rust chess core.

## TL;DR

Old:

- `src/` (Svelte 5 + TypeScript)
- `src-tauri/` (Tauri 2 + Rust 1.77)
- AI was driven by `tauri_plugin_shell` sidecar.

New:

- `flutter/` (Flutter 3.27 app, Material 3, responsive layout for desktop +
  mobile).
- `crates/chess_core/` (platform-agnostic Rust core).
- `crates/chess_bridge/` (flutter_rust_bridge bridge crate).
- AI driven by a `StockfishSpawner` trait, with desktop / Android / iOS
  implementations.

## What moved where

| Was | Now |
| --- | --- |
| `src-tauri/src/api.rs` | `crates/chess_core/src/api.rs` |
| `src-tauri/src/{engine,ai,clock,pgn,session,commands}` | `crates/chess_core/src/{engine,ai,clock,pgn,session,commands}` |
| `src-tauri/tests/integration.rs` | `crates/chess_core/tests/integration.rs` (extended) |
| `src-tauri/src/lib.rs` (Tauri shell) | `legacy/tauri/src/lib.rs` (still buildable, depends on `chess_core` via traits) |
| `src/App.svelte` | `flutter/lib/src/ui/home_screen.dart` |
| `src/lib/stores/gameStore.svelte.ts` | `flutter/lib/src/state/game_controller.dart` |
| `src/lib/stores/settingsStore.svelte.ts` | `flutter/lib/src/state/settings_controller.dart` |
| `src/lib/board/Board.svelte` | `flutter/lib/src/widgets/board/board_widget.dart` |
| `src/lib/audio/synth.ts` | `flutter/lib/src/audio/synth.dart` |
| `src/lib/pieces/merida.ts` | `flutter/lib/src/widgets/board/merida.dart` |

The Svelte `src/` tree moved to `legacy/svelte/` and the Tauri shell moved
to `legacy/tauri/`. Both are excluded from default builds (the workspace
`Cargo.toml` lists `legacy/tauri` as a member, but `default-members` only
includes the new crates, so `cargo test --workspace` exercises everything
while `cargo build` defaults to the chess_core + chess_bridge pair). Neither
legacy tree is removed; revive either by running `cd legacy/tauri && cargo
test` or by re-installing the JS toolchain and pointing Vite at
`legacy/svelte/`.

## Trait seams

The core was decoupled from Tauri behind three traits in
`crates/chess_core/src/platform.rs`:

```rust
pub trait AppDirs        { fn data_dir(&self) -> Option<PathBuf>; }
pub trait EventSink      { fn emit(&self, event: BackendEvent); }
pub trait StockfishSpawner {
    fn is_available(&self) -> bool;
    async fn spawn(&self) -> Result<UciChild, ApiError>;
}
```

Implementations:

| Trait | Tauri shell | Flutter desktop | Flutter mobile |
| --- | --- | --- | --- |
| `AppDirs` | `app.path().app_data_dir()` | `path_provider` from Dart, fed in via `bridge_init(dataDir)` | same |
| `EventSink` | `app.emit(name, payload)` | broadcast to a `flutter_rust_bridge::StreamSink<BackendEvent>` | same |
| `StockfishSpawner` | `tauri_plugin_shell::sidecar` | `BinaryStockfishSpawner` (`tokio::process`) | Android: same after `bridge_provide_external_stockfish` extracts the binary; iOS: `NoStockfishSpawner` (custom engine fallback) |

`SessionManager::set_spawner` lets the Flutter Android plugin install the
spawner at runtime, after copying the per-ABI binary out of `assets/`.

## Stockfish on mobile

- **Android**: per-ABI binaries (`arm64-v8a`, `armeabi-v7a`, `x86_64`) are
  built from source via `scripts/build-stockfish-android.sh` using NDK r26
  clang. They are bundled as Flutter assets, extracted to
  `getApplicationSupportDirectory()` on first launch, and exec'd via
  `tokio::process::Command`.
- **iOS**: `NoStockfishSpawner` always reports unavailable, so AI levels 4–10
  transparently route to `chess_core::ai::custom::choose_move(...,
  fallback_custom_level)`.

## Persistence paths

| OS | Settings + last-game JSON |
| --- | --- |
| macOS | `~/Library/Containers/com.gchavezm.chess/Data/Library/Application Support/com.gchavezm.chess/chess/{settings,last-game}.json` |
| Windows | `%LOCALAPPDATA%\com.gchavezm.chess\chess\{settings,last-game}.json` |
| Linux | `~/.local/share/com.gchavezm.chess/chess/{settings,last-game}.json` |
| iOS | `<App>/Library/Application Support/chess/{settings,last-game}.json` |
| Android | `/data/user/0/com.gchavezm.chess/files/chess/{settings,last-game}.json` |

(All resolved through Dart's `path_provider` ➜ Rust's `StaticAppDirs`.)

## Reviving the legacy Tauri shell

```bash
cd legacy/tauri
# Stockfish sidecar binaries (gitignored)
bash ../../scripts/fetch-stockfish.sh
cargo test
# `tauri dev` requires the Svelte tooling to be reinstalled at legacy/svelte/.
```

The Svelte UI is left alone in `legacy/svelte/`; it has no `package.json`
inside `legacy/svelte/` itself (the original `package.json` lived at the repo
root). To revive it, restore the root `package.json`, `vite.config.ts`,
`svelte.config.js`, and `tsconfig*.json` from git history (commit
`cc34907`) and run `pnpm install && pnpm dev`.
