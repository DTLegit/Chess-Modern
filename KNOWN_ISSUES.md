# Known issues

This file tracks behavioural caveats discovered during integration
testing and packaging that are intentionally left as-is.

## Build & packaging

- **macOS builds require a macOS host.** Tauri's bundler invokes
  `xcode-select`, codesign hooks, and ad-hoc DMG layout via macOS-only
  tooling (`hdiutil`, `dsymutil`); none of those have a portable
  cross-compile path. `scripts/build-mac.sh` is intentionally only run
  on macOS.
- **MSI is not produced cross-host.** Tauri uses WiX for MSI
  generation, and WiX requires a Windows host. We ship NSIS (`.exe`)
  from cross-compiled hosts instead, which has feature parity for the
  user-facing install flow.
- **Installers are unsigned.** The macOS `.dmg`/`.app`, Windows `.exe`,
  and Linux `.deb`/`.AppImage` all ship without a code-signing cert.
  macOS Gatekeeper and Windows SmartScreen will warn on first launch;
  end users must explicitly bypass.
- **First Windows cross-build is slow.** `cargo-xwin` downloads the
  Windows SDK headers (~500 MB) on first invocation; subsequent builds
  reuse the `~/.cache/cargo-xwin/` cache.
- **The Tauri CLI rejects `--bundles nsis` on non-Windows hosts.**
  The host-side filter only knows about Linux bundle types
  (`deb`, `rpm`, `appimage`). We work around this by relying on
  `bundle.targets="all"` in `tauri.conf.json`, which the Windows
  target's bundler honours and produces NSIS automatically.

## Stockfish

- **Sidecar binaries are gitignored.** `scripts/fetch-stockfish.sh`
  pulls Stockfish 17 from the upstream GitHub release for each of the
  four target triples. They total ~315 MB on disk; the bundle ships
  only the per-target binary (~80 MB).
- **AI difficulty 4–10 transparently falls back to the custom engine**
  when the Stockfish binary is missing or fails to spawn. The
  fallback uses depth=3 of the Rust minimax engine. The user does not
  see an error, only a slightly weaker opponent.

## Backend behaviour

- **`session::start_clock_task` is a no-op when no Tokio runtime is
  current.** This was a hard-panic before; the integration test
  exposed it. Production code paths always run inside a Tauri-managed
  Tokio runtime, so the only callers that hit the no-op branch are
  tests and the bindings-export binary.
- **The integration test cannot exercise the *real* Stockfish path.**
  `ai::stockfish::choose_move` requires a Tauri `AppHandle` (to access
  the shell sidecar). The test invokes `ai::choose_move(None, …)`
  which intentionally falls back to the custom engine. The Stockfish
  path is only reachable from the GUI build, which we cannot launch
  inside a Cloud Agent / CI container without a display.

## Frontend behaviour

- **PGN export uses a browser Blob download**, not the Tauri dialog
  plugin. This means saved PGNs land in the browser's "Downloads"
  directory inside the webview. The Rust `tauri-plugin-fs` and
  `tauri-plugin-dialog` plugins are still initialised in `lib.rs` for
  forward-compatibility but the capabilities file no longer grants
  their command permissions.
- **Audio uses Web Audio synthesis**, not OS audio APIs. The
  `prefers-reduced-motion` media query is honoured globally
  (`src/styles/app.css`); there is no equivalent for sound — disabling
  via Settings → "Sound" remains the user-facing control.
