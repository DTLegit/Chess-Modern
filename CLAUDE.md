# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Native cross-platform chess game. **Flutter** UI + **Rust** core, glued by **flutter_rust_bridge 2.12**. Hybrid AI: custom Rust minimax for difficulty 1–3, **Stockfish 17** subprocess for 4–10 on every platform except iOS (sandbox forbids spawning).

The repo is a single-shot migration from the previous **Svelte 5 + Tauri 2** stack. Both old trees still live in `legacy/` and the Tauri shell is still a workspace member; see "Legacy" below.

## Common commands

```bash
# Regenerate Dart bindings — REQUIRED after any edit to crates/chess_bridge/src/api.rs.
# Generated outputs (frb_generated.rs + flutter/lib/src/rust/*.dart) are checked in.
flutter_rust_bridge_codegen generate

# Headless Rust tests across the whole workspace (chess_core + chess_bridge + legacy/tauri).
cargo test --workspace
cargo test --workspace --all-targets   # what CI runs

# Single Rust test (chess_core integration suite is at crates/chess_core/tests/integration.rs).
cargo test -p chess_core <test_name>

# Flutter side.
cd flutter
flutter pub get
flutter analyze
flutter test
flutter test test/illegal_move_test.dart   # single file

# Run the app (desktop or simulator/emulator).
cd flutter && flutter run -d macos        # or windows / linux / <ios sim> / <android emulator>

# Stockfish 17 desktop sidecars (gitignored binaries).
bash scripts/fetch-stockfish.sh

# Stockfish 17 for Android (cross-compile per ABI; needs ANDROID_NDK_ROOT).
bash scripts/build-stockfish-android.sh
```

`cargo build` defaults to `chess_core + chess_bridge` only (`Cargo.toml` `default-members`). The `legacy/tauri` crate is in `members` so `cargo test --workspace` exercises it, but it is not built by default.

## Architecture

### Workspace layout

- `crates/chess_core/` — platform-agnostic Rust core. Submodules: `api` (shared types / `BackendEvent`), `engine`, `pgn`, `clock`, `ai` (`custom`, `stockfish`, `difficulty`), `session`, `commands`, `platform`.
- `crates/chess_bridge/` — `flutter_rust_bridge` crate. `api.rs` is the input the codegen scans; it re-exports `chess_core::api` types via `#[frb(mirror(...))]` so Dart sees concrete classes/enums instead of opaque handles. Holds a process-global `OnceLock<SessionManager>`.
- `flutter/` — Flutter app. Entry: `lib/main.dart` → `lib/src/app.dart` → `lib/src/ui/home_screen.dart`. State: `lib/src/state/{game,settings}_controller.dart`. Generated Dart bindings: `flutter/lib/src/rust/` (do not hand-edit).
- `legacy/{svelte,tauri}/` — archived previous UI and shell, kept for reference / revival.
- `scripts/` — Stockfish fetch/build, plus per-platform packaging scripts.

### Trait seams (the contract that holds the architecture together)

`crates/chess_core/src/platform.rs` defines three traits the core depends on instead of any platform symbol:

- **`AppDirs`** — where to persist settings + last-game JSON. Filled by Dart's `path_provider` and passed to `bridge_init(dataDir)`. `StaticAppDirs` for desktop, `EphemeralAppDirs` for tests.
- **`EventSink`** — push channel for `BackendEvent`. The bridge forwards into a `flutter_rust_bridge::StreamSink<BackendEvent>` exposed to Dart as a single broadcast `Stream` via `subscribeEvents()`. The four legacy event names (`move-made`, `ai-progress`, `game-over`, `clock-tick`) are unified into the `BackendEvent` enum variants.
- **`StockfishSpawner`** — selected at compile time by `cfg(target_os)` in `crates/chess_bridge/src/platform.rs`: desktop uses a bundled sidecar binary, Android extracts a per-ABI binary out of Flutter assets to `dataDir` on first use, iOS uses `NoStockfishSpawner` so AI 4–10 transparently falls back to `chess_core::ai::custom::choose_move(..., fallback_custom_level)` (see `crates/chess_core/src/ai/difficulty.rs`).

`SessionManager::set_spawner` lets the Android plugin install the spawner at runtime, after Dart has copied the per-ABI binary out of `assets/`.

### Backend ↔ frontend contract

15 commands + a single `BackendEvent` broadcast stream — preserved 1:1 from the legacy Tauri build. Commands live in `crates/chess_core/src/commands.rs`; the Dart-facing wrappers (one function per legacy `#[tauri::command]`) live in `crates/chess_bridge/src/api.rs`. Dart calls `bridgeInit(dataDir)` once at startup and `subscribeEvents()` for the broadcast stream.

**Do not change a type's shape on one side without the other.** When you edit `crates/chess_bridge/src/api.rs`, you MUST run `flutter_rust_bridge_codegen generate` — CI re-runs this before the desktop smoke build, but local Flutter compiles will silently see stale bindings until you regenerate.

### AI difficulty routing

`chess_core::ai::stockfish::choose_move` is the single entry point for AI moves. If `StockfishSpawner::is_available()` is false or the spawn fails, it falls back to the custom engine at `fallback_custom_level` automatically. The user sees a slightly weaker opponent at high levels, never an error. Tests should not assume Stockfish is present.

## Native library wiring (per platform)

Only Linux is fully wired right now (`flutter/linux/runner/rust_lib.cmake`). macOS, Windows, iOS, and Android need manual build-step glue documented in `MIGRATION.md`. Running `flutter_rust_bridge_codegen integrate --template app` automates this but is destructive (overwrites runner files) — do not run it casually.

## Persistence

Dart's `path_provider` resolves the data dir per-OS, hands it to Rust through `bridge_init`, and the core writes `chess/{settings,last-game}.json` underneath. Per-OS paths are listed in `MIGRATION.md`.

## Known caveats (read before "fixing")

`KNOWN_ISSUES.md` documents intentional behaviours — most importantly:

- iOS uses the custom engine for every level (sandbox).
- Stockfish desktop binaries and Android ABI binaries are gitignored; missing-binary path is a transparent custom-engine fallback, not an error.
- `session::start_clock_task` no-ops outside a Tokio runtime (only matters for synchronous unit tests).
- The `BackendEvent` broadcast sink does not GC dropped listeners — fine because Flutter subscribes once at startup.
- The Flutter UI dropped Material 3 and rebuilt on `WidgetsApp` with custom primitives (`flutter/lib/src/widgets/primitives/`) and design tokens (`flutter/lib/src/theme/tokens.dart`). Read `AppTheme.of(context)` instead of `Theme.of(context)`. Adding new screens should reuse the `App*` primitives, not Material widgets.

## Legacy

`legacy/tauri/` is still a workspace member (so `cargo test --workspace` covers it) but excluded from `default-members`. `legacy/svelte/` is the archived Svelte 5 UI. CI stages stub Stockfish binaries under `src-tauri/binaries/` so the legacy Tauri tests can build (see `.github/workflows/ci.yml`). Don't delete `legacy/` without removing the workspace member entry first.
