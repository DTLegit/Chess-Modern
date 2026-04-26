#!/usr/bin/env bash
# Build a Windows x86_64 NSIS installer from any non-Windows host (macOS or
# Linux) using cargo-xwin. The Tauri CLI's --bundles flag on a non-Windows
# host filters out NSIS, but it falls back to `bundle.targets = "all"` from
# tauri.conf.json when no --bundles is passed — which on a Windows target
# produces NSIS + MSI (we keep just NSIS afterwards).
#
# Prerequisites (one-time):
#   Linux:
#     sudo apt-get install -y nsis llvm clang lld
#     rustup target add x86_64-pc-windows-msvc
#     cargo install --locked cargo-xwin
#   macOS:
#     brew install nsis llvm
#     export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
#     rustup target add x86_64-pc-windows-msvc
#     cargo install --locked cargo-xwin
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v makensis >/dev/null; then
  echo "ERROR: NSIS not found. Linux: 'sudo apt-get install nsis'. macOS: 'brew install nsis'." >&2
  exit 1
fi
if ! command -v lld-link >/dev/null; then
  echo "ERROR: lld-link not found. Linux: 'sudo apt-get install lld'. macOS: 'brew install llvm'." >&2
  exit 1
fi
if ! cargo xwin --help >/dev/null 2>&1; then
  echo "ERROR: cargo-xwin not installed. Run: cargo install --locked cargo-xwin" >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    if [ -d /opt/homebrew/opt/llvm/bin ]; then
      export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
    fi
    ;;
esac

rustup target add x86_64-pc-windows-msvc

echo "==> Building Windows x64 installer (.exe) via cargo-xwin"
# Note: --bundles nsis is rejected by the Tauri CLI on non-Windows hosts.
# Omitting the flag lets the bundler honor `tauri.conf.json` targets (=all)
# which includes NSIS for Windows targets.
pnpm tauri build \
  --runner cargo-xwin \
  --target x86_64-pc-windows-msvc

OUT="$ROOT/dist/installers/windows"
mkdir -p "$OUT"
cp src-tauri/target/x86_64-pc-windows-msvc/release/bundle/nsis/*.exe "$OUT/" 2>/dev/null || true

echo "==> Windows installer(s) in $OUT"
ls -la "$OUT"
