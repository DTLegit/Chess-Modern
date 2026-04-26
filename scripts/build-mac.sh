#!/usr/bin/env bash
# Build a universal macOS .app + .dmg from macOS host.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v cargo >/dev/null; then
  echo "ERROR: cargo not found. Install Rust: https://rustup.rs" >&2
  exit 1
fi

rustup target add aarch64-apple-darwin x86_64-apple-darwin

echo "==> Building universal macOS bundle"
pnpm tauri build --target universal-apple-darwin

OUT="$ROOT/dist/installers/macos"
mkdir -p "$OUT"
cp -R src-tauri/target/universal-apple-darwin/release/bundle/dmg/*.dmg "$OUT/" 2>/dev/null || true
cp -R src-tauri/target/universal-apple-darwin/release/bundle/macos/*.app "$OUT/" 2>/dev/null || true

echo "==> macOS installers in $OUT"
ls -la "$OUT"
