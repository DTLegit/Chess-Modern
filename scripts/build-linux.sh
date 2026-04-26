#!/usr/bin/env bash
# Build a Linux x86_64 .AppImage and .deb. When run on a Linux host, this
# uses the system Tauri toolchain directly (fastest path). On macOS it
# falls back to building inside the Ubuntu 22.04 container defined by
# scripts/linux.Dockerfile.
#
# Prerequisites (one-time):
#   Linux host:
#     sudo apt-get install -y build-essential curl wget file libssl-dev \
#       pkg-config libgtk-3-dev libwebkit2gtk-4.1-dev \
#       libayatana-appindicator3-dev librsvg2-dev
#     rustup target add x86_64-unknown-linux-gnu
#   macOS host:
#     brew install --cask docker  (and start Docker.app)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT="$ROOT/dist/installers/linux"
mkdir -p "$OUT"

case "$(uname -s)" in
  Linux)
    echo "==> Building Linux installers natively"
    pnpm tauri build \
      --bundles deb,appimage \
      --target x86_64-unknown-linux-gnu

    cp src-tauri/target/x86_64-unknown-linux-gnu/release/bundle/appimage/*.AppImage "$OUT/" 2>/dev/null || true
    cp src-tauri/target/x86_64-unknown-linux-gnu/release/bundle/deb/*.deb           "$OUT/" 2>/dev/null || true
    ;;

  Darwin)
    if ! command -v docker >/dev/null; then
      echo "ERROR: Docker not found. Install Docker Desktop: brew install --cask docker" >&2
      exit 1
    fi

    IMAGE="chess-linux-builder:latest"
    echo "==> Building Linux builder image"
    docker build -f scripts/linux.Dockerfile -t "$IMAGE" scripts

    echo "==> Building Linux .AppImage and .deb inside container"
    # Mount the project read-write so the container reuses host caches.
    docker run --rm \
      -v "$ROOT":/work \
      -w /work \
      "$IMAGE" \
      bash -lc 'pnpm install --frozen-lockfile=false && pnpm tauri build --bundles appimage,deb'

    cp src-tauri/target/release/bundle/appimage/*.AppImage "$OUT/" 2>/dev/null || true
    cp src-tauri/target/release/bundle/deb/*.deb           "$OUT/" 2>/dev/null || true
    ;;

  *)
    echo "ERROR: unsupported host OS: $(uname -s)" >&2
    exit 1
    ;;
esac

echo "==> Linux installers in $OUT"
ls -la "$OUT"
