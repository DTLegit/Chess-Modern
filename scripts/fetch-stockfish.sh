#!/usr/bin/env bash
# Download Stockfish 17 binaries for desktop targets and place them in
# crates/chess_bridge/binaries/ where the macOS Flutter build script picks
# them up to embed as app sidecars:
#
#   stockfish-aarch64-apple-darwin
#   stockfish-x86_64-apple-darwin
#   stockfish-x86_64-pc-windows-msvc.exe
#   stockfish-x86_64-unknown-linux-gnu
#
# Stockfish 17 official builds: https://stockfishchess.org/files/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/crates/chess_bridge/binaries"
mkdir -p "$DEST"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

SF_VER="stockfish-17"
BASE="https://github.com/official-stockfish/Stockfish/releases/download/sf_17"

fetch() {
  local archive="$1" out="$2" inner="$3"
  echo "==> $archive"
  curl -L --fail --output "$WORK/$archive" "$BASE/$archive"
  case "$archive" in
    *.zip) (cd "$WORK" && unzip -o "$archive" >/dev/null) ;;
    *.tar)  (cd "$WORK" && tar -xf "$archive") ;;
  esac
  install -m 0755 "$WORK/$inner" "$DEST/$out"
}

# macOS arm64
fetch "stockfish-macos-m1-apple-silicon.tar"  "stockfish-aarch64-apple-darwin"      "stockfish/stockfish-macos-m1-apple-silicon"
# macOS x86_64
fetch "stockfish-macos-x86-64-avx2.tar"       "stockfish-x86_64-apple-darwin"       "stockfish/stockfish-macos-x86-64-avx2"
# Windows x64
fetch "stockfish-windows-x86-64-avx2.zip"     "stockfish-x86_64-pc-windows-msvc.exe" "stockfish/stockfish-windows-x86-64-avx2.exe"
# Linux x64
fetch "stockfish-ubuntu-x86-64-avx2.tar"      "stockfish-x86_64-unknown-linux-gnu"  "stockfish/stockfish-ubuntu-x86-64-avx2"

echo "==> Done. Binaries in $DEST:"
ls -la "$DEST"
