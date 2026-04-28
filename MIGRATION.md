# Migration: Svelte 5 + Tauri 2 → Flutter

This document records the single-shot migration of the Chess UI from
Svelte 5 + Tauri 2 to Flutter, while preserving the Rust chess core.

## TL;DR

Old:

- `src/` (Svelte 5 + TypeScript)
- `src-tauri/` (Tauri 2 + Rust 1.77)
- AI was driven by `tauri_plugin_shell` sidecar.

New:

- `flutter/` (Flutter 3.27 app, custom design system rooted in `WidgetsApp`,
  responsive layout for desktop + mobile).
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

## Per-platform native-library wiring

Each Flutter target needs to know how to build and link the
`libchess_bridge` dynamic library produced by `cargo build`. The Linux
desktop runner already does this via
`flutter/linux/runner/rust_lib.cmake`, included from
`flutter/linux/CMakeLists.txt`.

| Platform | Status | Where it lands |
| --- | --- | --- |
| **Linux** | wired ✅ | `flutter/linux/runner/rust_lib.cmake` builds via `cargo build`, installs `target/{debug,release}/libchess_bridge.so` into `bundle/lib/`. |
| **macOS** | manual ⚠️ | Add a "Run Script" build phase that runs `cargo build --manifest-path crates/chess_bridge/Cargo.toml --release --target=$(uname -m)-apple-darwin` and copy `libchess_bridge.dylib` into `Frameworks/` of the .app. |
| **Windows** | manual ⚠️ | Add a `add_custom_target` in `flutter/windows/CMakeLists.txt` mirroring the Linux file; install `target/release/chess_bridge.dll` next to `chess.exe`. |
| **iOS** | manual ⚠️ | Build a static `.a` (`cargo build --target aarch64-apple-ios{-sim,}`) and wrap as an XCFramework; reference from `flutter/ios/Runner.xcodeproj`. |
| **Android** | manual ⚠️ | Add a Gradle `task` invoking `cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 build --release` and place the resulting `libchess_bridge.so` per ABI under `flutter/android/app/src/main/jniLibs/<abi>/`. The `cargo-ndk` crate or `flutter_rust_bridge_codegen integrate` automates this. |

The `flutter_rust_bridge_codegen integrate --template app` command writes
all of the above for you, but it's destructive (it overwrites runner
files); we ship the Linux wiring by hand for now and document the
others as one-liners.

## Visual parity pass

The first Flutter migration shipped on Material 3 with default chrome
(ripples, M3 surface tints, blue ColorScheme). A follow-up pass dropped
Material entirely and rebuilt the UI as a faithful clone of the legacy
Svelte design that lives in `legacy/svelte/`.

### What changed

- **App shell:** `MaterialApp` → `WidgetsApp` (`flutter/lib/src/app.dart`).
  Localization delegates kept (`DefaultMaterialLocalizations`,
  `DefaultWidgetsLocalizations`, `DefaultCupertinoLocalizations`) but no
  Material widgets remain in `flutter/lib/`.
- **Design tokens:** all colors, spacing, radii, shadows, durations, and
  easing curves extracted from `legacy/svelte/styles/app.css` into
  `flutter/lib/src/theme/tokens.dart` (palettes for light/dark/blue, five
  accent presets, nine board palettes, motion tokens). Typography in
  `flutter/lib/src/theme/typography.dart`. The data is exposed via an
  `AppTheme` `InheritedWidget` (`flutter/lib/src/theme/app_theme.dart`);
  read it with `AppTheme.of(context)` in place of `Theme.of(context)`.
- **Bundled fonts:** Inter (sans), EB Garamond (serif, regular + italic),
  JetBrains Mono (mono) — all variable .ttf files in
  `flutter/assets/fonts/`. Declared in `pubspec.yaml`.
- **Primitive widget library:** `flutter/lib/src/widgets/primitives/`
  contains `AppButton`, `AppIconButton`, `AppDialog` (+ `showAppDialog`),
  `AppPanel`, `AppListRow`, `AppLabel`, `AppDivider`, `AppSwitch`,
  `AppCheckbox`, `AppRadio`, `AppSlider`, `AppSegmented`, `AppTextField`,
  `AppScaffold`, plus a CustomPainter icon set in `app_icons.dart`. None of
  these import `flutter/material.dart`.
- **Restored product divergences** from the original Svelte UI:
  - In-board promotion picker overlay
    (`flutter/lib/src/widgets/board/promotion_overlay.dart`), positioned
    on the destination square with directional stacking, replacing the
    centered Material dialog.
  - Real file-save PGN export via the `file_selector` package (desktop);
    mobile keeps the "Copy PGN" fallback.
  - Drag-to-move added to the board widget alongside tap-to-select
    (`flutter/lib/src/widgets/board/board_widget.dart`), with a 0.6%
    threshold, 1.08 piece scale + drop-shadow during drag, and snap-to-square
    on release.
- **Backend untouched:** the 15-command + 4-event bridge contract
  (`crates/chess_bridge/src/api.rs`) and all Rust crates are unchanged.
  Only the `pubspec.yaml` deps grew by one entry (`file_selector ^1.0.3`).

### Verification

- `flutter analyze` should be clean.
- `flutter test` covers the new primitives via
  `flutter/test/widgets/primitives/primitives_test.dart`.
- `cargo test --workspace --all-targets` is unchanged from before this pass.

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
