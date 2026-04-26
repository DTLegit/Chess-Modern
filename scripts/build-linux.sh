#!/usr/bin/env bash
# Build a Linux x86_64 .AppImage and .deb from a macOS host using Docker.
# Tauri's CLI does not natively support cross-compiling Linux bundles from
# macOS, so we run the build *inside* an Ubuntu 22.04 container.
#
# Prerequisites (one-time setup):
#   brew install --cask docker
#   open -a Docker            # start Docker Desktop, wait for it to be ready
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v docker >/dev/null; then
  echo "ERROR: Docker not found. Install Docker Desktop: brew install --cask docker" >&2
  exit 1
fi

IMAGE="chess-linux-builder:latest"
echo "==> Building Linux builder image"
docker build -f scripts/linux.Dockerfile -t "$IMAGE" scripts

OUT="$ROOT/dist/installers/linux"
mkdir -p "$OUT"

echo "==> Building Linux .AppImage and .deb inside container"
# We mount the project read-write so the container's pnpm/cargo caches reuse
# host space. node_modules and target are inside the project dir so they
# persist between runs — but we ignore them in .gitignore.
docker run --rm \
  -v "$ROOT":/work \
  -w /work \
  "$IMAGE" \
  bash -lc 'pnpm install --frozen-lockfile=false && pnpm tauri build --bundles appimage,deb'

cp src-tauri/target/release/bundle/appimage/*.AppImage "$OUT/" 2>/dev/null || true
cp src-tauri/target/release/bundle/deb/*.deb           "$OUT/" 2>/dev/null || true

echo "==> Linux installers in $OUT"
ls -la "$OUT"
