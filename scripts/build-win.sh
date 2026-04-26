#!/usr/bin/env bash
# Build a Windows x86_64 NSIS installer from a macOS host using cargo-xwin.
#
# Prerequisites (one-time setup):
#   brew install nsis llvm
#   export PATH="/opt/homebrew/opt/llvm/bin:$PATH"   # add to ~/.zshrc
#   rustup target add x86_64-pc-windows-msvc
#   cargo install --locked cargo-xwin
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v makensis >/dev/null; then
  echo "ERROR: NSIS not found. Run: brew install nsis" >&2
  exit 1
fi
if ! command -v llvm-rc >/dev/null && ! [ -x /opt/homebrew/opt/llvm/bin/llvm-rc ]; then
  echo "ERROR: llvm-rc not found. Run: brew install llvm and add /opt/homebrew/opt/llvm/bin to PATH" >&2
  exit 1
fi
if ! cargo xwin --help >/dev/null 2>&1; then
  echo "ERROR: cargo-xwin not installed. Run: cargo install --locked cargo-xwin" >&2
  exit 1
fi

export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
rustup target add x86_64-pc-windows-msvc

echo "==> Building Windows x64 NSIS installer (.exe)"
pnpm tauri build \
  --runner cargo-xwin \
  --target x86_64-pc-windows-msvc \
  --bundles nsis

OUT="$ROOT/dist/installers/windows"
mkdir -p "$OUT"
cp src-tauri/target/x86_64-pc-windows-msvc/release/bundle/nsis/*.exe "$OUT/" 2>/dev/null || true

echo "==> Windows installer in $OUT"
ls -la "$OUT"
