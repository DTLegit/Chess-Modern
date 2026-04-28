#!/usr/bin/env bash
# Cursor Cloud Agent VM provisioning script for the Chess-Test repo.
#
# Idempotent. Snapshotted by Cursor after first successful run, so
# subsequent agent boots skip almost everything here.
#
# What this installs:
#   - Linux apt deps for: Flutter Linux desktop builds, the legacy Tauri
#     shell (still a workspace member), curl/unzip/git tooling, OpenJDK 17.
#   - Rust stable toolchain (>= 1.77 MSRV from workspace Cargo.toml).
#   - Flutter SDK 3.27.0 stable (matches .github/workflows/ci.yml).
#   - Android SDK cmdline-tools, platform-tools, platform-android-34,
#     build-tools 34.0.0, NDK r26 (for `flutter build apk` and the
#     scripts/build-stockfish-android.sh cross-compile path).
#   - flutter_rust_bridge_codegen v2.12 (matches pubspec.yaml).
#   - Linux Stockfish 17 sidecar (best-effort; missing-binary path is a
#     transparent custom-engine fallback per CLAUDE.md).
#   - Stockfish stub binaries under src-tauri/binaries/ for the legacy
#     Tauri workspace member (`cargo test --workspace` exercises it).
#
# Sets PATH and ANDROID_* env vars in $HOME/.bashrc so subsequent
# interactive shells inherit them. The .cursor/environment.json `start`
# field also exports them for non-interactive invocations.

set -euo pipefail

log() { printf '\n==> %s\n' "$*"; }
warn() { printf '\n[warn] %s\n' "$*" >&2; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# 1. System apt deps
# ---------------------------------------------------------------------------
log "Installing apt packages"
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential cmake ninja-build clang pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev \
  libwebkit2gtk-4.1-dev libjavascriptcoregtk-4.1-dev \
  libsoup-3.0-dev libxdo-dev libglu1-mesa \
  curl git unzip xz-utils zip ca-certificates \
  openjdk-17-jdk-headless

# ---------------------------------------------------------------------------
# 2. Rust toolchain (stable >= MSRV 1.77)
# ---------------------------------------------------------------------------
if ! command -v rustup >/dev/null 2>&1; then
  log "Installing rustup + Rust stable"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable --profile minimal
fi
# shellcheck disable=SC1091
source "$HOME/.cargo/env"
rustup toolchain install stable >/dev/null
rustup default stable

# ---------------------------------------------------------------------------
# 3. Flutter SDK 3.27.0 stable
# ---------------------------------------------------------------------------
FLUTTER_VERSION="${FLUTTER_VERSION:-3.27.0}"
FLUTTER_HOME="$HOME/flutter"
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  log "Cloning Flutter $FLUTTER_VERSION"
  rm -rf "$FLUTTER_HOME"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --disable-analytics >/dev/null
flutter config --no-cli-animations \
  --enable-linux-desktop --enable-android \
  --no-enable-macos-desktop --no-enable-windows-desktop \
  --no-enable-ios --no-enable-web >/dev/null
log "Flutter version"
flutter --version
log "Flutter precache (linux + android)"
flutter precache --linux --android --no-ios --no-macos --no-windows --no-web

# ---------------------------------------------------------------------------
# 4. Android SDK cmdline-tools + platform-tools + platform 34 + NDK r26
# ---------------------------------------------------------------------------
ANDROID_SDK_ROOT="$HOME/android-sdk"
if [ ! -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
  log "Installing Android cmdline-tools"
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
  curl -fsSL -o /tmp/android-cmdline-tools.zip \
    https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip -q /tmp/android-cmdline-tools.zip -d "$ANDROID_SDK_ROOT/cmdline-tools"
  mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  rm -f /tmp/android-cmdline-tools.zip
fi
export ANDROID_SDK_ROOT
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

log "Accepting Android SDK licenses + installing packages"
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager --install \
  "platform-tools" \
  "platforms;android-34" \
  "build-tools;34.0.0" \
  "ndk;26.1.10909125" >/dev/null
export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/26.1.10909125"

# ---------------------------------------------------------------------------
# 5. flutter_rust_bridge_codegen v2.12 (matches pubspec.yaml flutter_rust_bridge: 2.12.0)
# ---------------------------------------------------------------------------
if ! command -v flutter_rust_bridge_codegen >/dev/null 2>&1; then
  log "Installing flutter_rust_bridge_codegen"
  cargo install flutter_rust_bridge_codegen --version 2.12.0 --locked
fi

# ---------------------------------------------------------------------------
# 6. Stockfish stubs for legacy Tauri workspace member
#    (mirrors the pattern in .github/workflows/ci.yml so cargo test --workspace
#    keeps passing without real binaries; legacy/tauri only needs the file
#    to exist for the sidecar resource resolution).
# ---------------------------------------------------------------------------
log "Staging Stockfish stubs for legacy Tauri shell"
mkdir -p src-tauri/binaries
for triple in aarch64-apple-darwin x86_64-apple-darwin x86_64-unknown-linux-gnu; do
  stub="src-tauri/binaries/stockfish-$triple"
  if [ ! -f "$stub" ]; then
    printf '#!/bin/sh\nexit 0\n' > "$stub"
    chmod +x "$stub"
  fi
done
win_stub="src-tauri/binaries/stockfish-x86_64-pc-windows-msvc.exe"
[ -f "$win_stub" ] || printf 'MZ' > "$win_stub"

# ---------------------------------------------------------------------------
# 7. Real Stockfish 17 Linux sidecar (best-effort).
#    The fetch script writes to src-tauri/binaries/ in the legacy naming.
#    Failure is non-fatal: per CLAUDE.md and KNOWN_ISSUES.md, missing binary
#    routes to fallback_custom_level transparently.
# ---------------------------------------------------------------------------
log "Fetching real Stockfish 17 binaries (best-effort)"
if bash scripts/fetch-stockfish.sh; then
  log "Stockfish fetch ok"
else
  warn "Stockfish fetch failed; custom-engine fallback will be used in cloud verification"
fi

# ---------------------------------------------------------------------------
# 8. Flutter package fetch
# ---------------------------------------------------------------------------
log "flutter pub get"
( cd flutter && flutter pub get )

# ---------------------------------------------------------------------------
# 9. Persist env vars across interactive shells
# ---------------------------------------------------------------------------
BASHRC="$HOME/.bashrc"
log "Persisting PATH + ANDROID_* in $BASHRC"
mark_begin="# >>> chess-test cloud agent env >>>"
mark_end="# <<< chess-test cloud agent env <<<"
if ! grep -qF "$mark_begin" "$BASHRC" 2>/dev/null; then
  cat >>"$BASHRC" <<EOF

$mark_begin
[ -f "\$HOME/.cargo/env" ] && . "\$HOME/.cargo/env"
export FLUTTER_HOME="\$HOME/flutter"
export ANDROID_SDK_ROOT="\$HOME/android-sdk"
export ANDROID_HOME="\$ANDROID_SDK_ROOT"
export ANDROID_NDK_ROOT="\$ANDROID_SDK_ROOT/ndk/26.1.10909125"
export PATH="\$FLUTTER_HOME/bin:\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:\$ANDROID_SDK_ROOT/platform-tools:\$PATH"
$mark_end
EOF
fi

log "Cloud agent VM provisioning complete"
