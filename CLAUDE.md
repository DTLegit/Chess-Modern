# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Native cross-platform chess game. **Flutter** UI + **Rust** core, glued by **flutter_rust_bridge 2.12**. Hybrid AI: custom Rust minimax for difficulty 1–3, **Stockfish 17** subprocess for 4–10 on every platform except iOS (sandbox forbids spawning).

## Common commands

```bash
# Regenerate Dart bindings — REQUIRED after any edit to crates/chess_bridge/src/api.rs.
# Generated outputs (frb_generated.rs + flutter/lib/src/rust/*.dart) are checked in.
flutter_rust_bridge_codegen generate

# Rust tests (chess_core + chess_bridge).
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

# Stockfish 17 desktop sidecars (gitignored binaries — lands in crates/chess_bridge/binaries/).
bash scripts/fetch-stockfish.sh

# Stockfish 17 for Android (cross-compile per ABI; needs ANDROID_NDK_ROOT).
bash scripts/build-stockfish-android.sh
```

## Architecture

### Workspace layout

- `crates/chess_core/` — platform-agnostic Rust core. Submodules: `api` (shared types / `BackendEvent`), `engine`, `pgn`, `clock`, `ai` (`custom`, `stockfish`, `difficulty`), `session`, `commands`, `platform`.
- `crates/chess_bridge/` — `flutter_rust_bridge` crate. `api.rs` is the input the codegen scans; it re-exports `chess_core::api` types via `#[frb(mirror(...))]` so Dart sees concrete classes/enums instead of opaque handles. Holds a process-global `OnceLock<SessionManager>`.
- `flutter/` — Flutter app. Entry: `lib/main.dart` → `lib/src/app.dart` → `lib/src/ui/home_screen.dart`. State: `lib/src/state/{game,settings}_controller.dart`. Generated Dart bindings: `flutter/lib/src/rust/` (do not hand-edit).
- `scripts/` — Stockfish fetch/build scripts.

### Trait seams (the contract that holds the architecture together)

`crates/chess_core/src/platform.rs` defines three traits the core depends on instead of any platform symbol:

- **`AppDirs`** — where to persist settings + last-game JSON. Filled by Dart's `path_provider` and passed to `bridge_init(dataDir)`. `StaticAppDirs` for desktop, `EphemeralAppDirs` for tests.
- **`EventSink`** — push channel for `BackendEvent`. The bridge forwards into a `flutter_rust_bridge::StreamSink<BackendEvent>` exposed to Dart as a single broadcast `Stream` via `subscribeEvents()`.
- **`StockfishSpawner`** — selected at compile time by `cfg(target_os)` in `crates/chess_bridge/src/platform.rs`: desktop uses a bundled sidecar binary, Android extracts a per-ABI binary out of Flutter assets to `dataDir` on first use, iOS uses `NoStockfishSpawner` so AI 4–10 transparently falls back to `chess_core::ai::custom::choose_move(..., fallback_custom_level)` (see `crates/chess_core/src/ai/difficulty.rs`).

`SessionManager::set_spawner` lets the Android plugin install the spawner at runtime, after Dart has copied the per-ABI binary out of `assets/`.

### Backend ↔ frontend contract

15 commands + a single `BackendEvent` broadcast stream. Commands live in `crates/chess_core/src/commands.rs`; the Dart-facing wrappers live in `crates/chess_bridge/src/api.rs`. Dart calls `bridgeInit(dataDir)` once at startup and `subscribeEvents()` for the broadcast stream.

**Do not change a type's shape on one side without the other.** When you edit `crates/chess_bridge/src/api.rs`, you MUST run `flutter_rust_bridge_codegen generate` — CI re-runs this before the desktop smoke build, but local Flutter compiles will silently see stale bindings until you regenerate.

### AI difficulty routing

`chess_core::ai::stockfish::choose_move` is the single entry point for AI moves. If `StockfishSpawner::is_available()` is false or the spawn fails, it falls back to the custom engine at `fallback_custom_level` automatically. The user sees a slightly weaker opponent at high levels, never an error. Tests should not assume Stockfish is present.

## Native library wiring (per platform)

macOS: Xcode build phase in `flutter/macos/Runner.xcodeproj` invokes `flutter/macos/Runner/Scripts/build_rust.sh`, which compiles `crates/chess_bridge` and embeds the resulting framework + Stockfish sidecar into the `.app` bundle.

Linux: `flutter/linux/runner/rust_lib.cmake`.

Windows, iOS, and Android need additional build-step glue; see each platform's runner directory.

## Persistence

Dart's `path_provider` resolves the data dir per-OS, hands it to Rust through `bridge_init`, and the core writes `chess/{settings,last-game}.json` underneath.

## Known caveats (read before "fixing")

`KNOWN_ISSUES.md` documents intentional behaviours — most importantly:

- iOS uses the custom engine for every level (sandbox).
- Stockfish desktop binaries and Android ABI binaries are gitignored; missing-binary path is a transparent custom-engine fallback, not an error. Run `scripts/fetch-stockfish.sh` to download desktop binaries into `crates/chess_bridge/binaries/`.
- `session::start_clock_task` no-ops outside a Tokio runtime (only matters for synchronous unit tests).
- The `BackendEvent` broadcast sink does not GC dropped listeners — fine because Flutter subscribes once at startup.
- The Flutter UI dropped Material 3 and rebuilt on `WidgetsApp` with custom primitives (`flutter/lib/src/widgets/primitives/`) and design tokens (`flutter/lib/src/theme/tokens.dart`). Read `AppTheme.of(context)` instead of `Theme.of(context)`. Adding new screens should reuse the `App*` primitives, not Material widgets.
