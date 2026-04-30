#!/usr/bin/env bash
# Build crates/chess_bridge as a cdylib for the host macOS arch and embed
# the resulting libchess_bridge.dylib into the Flutter .app bundle.
# Also embeds a matching Stockfish 17 sidecar binary, if available, so AI
# levels 4-10 use the real engine. Falls back to the custom Rust engine
# silently when no binary is present.
#
# Invoked as a Run Script build phase by flutter/macos/Runner.xcodeproj.
# Reads $CONFIGURATION, $ARCHS, $TARGET_BUILD_DIR, $PRODUCT_NAME from Xcode.
set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve repo root and Cargo profile
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "${SRCROOT}/../.." && pwd)"
MANIFEST="${REPO_ROOT}/crates/chess_bridge/Cargo.toml"

case "${CONFIGURATION}" in
  Debug)
    CARGO_PROFILE="dev"
    CARGO_TARGET_DIR_LEAF="debug"
    CARGO_FLAGS=""
    ;;
  Release|Profile)
    CARGO_PROFILE="release"
    CARGO_TARGET_DIR_LEAF="release"
    CARGO_FLAGS="--release"
    ;;
  *)
    echo "build_rust.sh: unknown CONFIGURATION='${CONFIGURATION}'" >&2
    exit 1
    ;;
esac

# ---------------------------------------------------------------------------
# Pick a single arch. Universal builds: rerun once per arch and lipo.
# ---------------------------------------------------------------------------
ARCHS_LIST=(${ARCHS:-$(uname -m)})
DYLIB_NAME="libchess_bridge.dylib"
APP_FRAMEWORKS="${TARGET_BUILD_DIR}/${PRODUCT_NAME}.app/Contents/Frameworks"
APP_RESOURCES="${TARGET_BUILD_DIR}/${PRODUCT_NAME}.app/Contents/Resources"
mkdir -p "${APP_FRAMEWORKS}" "${APP_RESOURCES}"

# Make sure cargo is on PATH when invoked from Xcode.
if ! command -v cargo >/dev/null 2>&1; then
  for candidate in "${HOME}/.cargo/bin" "/opt/homebrew/bin" "/usr/local/bin"; do
    if [ -x "${candidate}/cargo" ]; then
      export PATH="${candidate}:${PATH}"
      break
    fi
  done
fi
if ! command -v cargo >/dev/null 2>&1; then
  echo "build_rust.sh: cargo not found on PATH. Install rustup." >&2
  exit 1
fi

declare -a BUILT_DYLIBS=()
for ARCH in "${ARCHS_LIST[@]}"; do
  case "${ARCH}" in
    arm64)  RUST_TARGET="aarch64-apple-darwin" ;;
    x86_64) RUST_TARGET="x86_64-apple-darwin"  ;;
    *) echo "build_rust.sh: unsupported ARCH='${ARCH}'" >&2; exit 1 ;;
  esac

  rustup target add "${RUST_TARGET}" >/dev/null 2>&1 || true

  echo "==> cargo build (${RUST_TARGET}, ${CARGO_PROFILE})"
  cargo build \
    --manifest-path "${MANIFEST}" \
    --target "${RUST_TARGET}" \
    ${CARGO_FLAGS}

  BUILT_DYLIBS+=("${REPO_ROOT}/target/${RUST_TARGET}/${CARGO_TARGET_DIR_LEAF}/${DYLIB_NAME}")
done

# ---------------------------------------------------------------------------
# Wrap the dylib in a versioned macOS framework bundle. flutter_rust_bridge's
# loader on macOS dlopen()s `chess_bridge.framework/chess_bridge` (NOT a bare
# .dylib), so we have to ship a real framework structure even though we only
# carry one binary inside.
# ---------------------------------------------------------------------------
FRAMEWORK_NAME="chess_bridge"
FRAMEWORK_DIR="${APP_FRAMEWORKS}/${FRAMEWORK_NAME}.framework"
FW_VERSION="A"
FW_VERSION_DIR="${FRAMEWORK_DIR}/Versions/${FW_VERSION}"
FW_BINARY="${FW_VERSION_DIR}/${FRAMEWORK_NAME}"
FW_RESOURCES="${FW_VERSION_DIR}/Resources"

rm -rf "${FRAMEWORK_DIR}"
mkdir -p "${FW_VERSION_DIR}" "${FW_RESOURCES}"

if [ "${#BUILT_DYLIBS[@]}" -eq 1 ]; then
  cp -f "${BUILT_DYLIBS[0]}" "${FW_BINARY}"
else
  lipo -create -output "${FW_BINARY}" "${BUILT_DYLIBS[@]}"
fi
chmod 755 "${FW_BINARY}"

# Symlinks for the standard versioned framework layout.
ln -sf "${FW_VERSION}" "${FRAMEWORK_DIR}/Versions/Current"
ln -sf "Versions/Current/${FRAMEWORK_NAME}" "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
ln -sf "Versions/Current/Resources" "${FRAMEWORK_DIR}/Resources"

cat > "${FW_RESOURCES}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>${FRAMEWORK_NAME}</string>
  <key>CFBundleIdentifier</key><string>com.gchavezm.chess.${FRAMEWORK_NAME}</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>${FRAMEWORK_NAME}</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
</dict>
</plist>
PLIST

# Set install name to the canonical framework path so dyld can locate it
# via the runner's @executable_path/../Frameworks rpath.
install_name_tool -id "@rpath/${FRAMEWORK_NAME}.framework/Versions/${FW_VERSION}/${FRAMEWORK_NAME}" "${FW_BINARY}"

# Ad-hoc sign so Gatekeeper / App Sandbox accept the embedded framework.
codesign --force --sign - "${FW_BINARY}"
codesign --force --sign - "${FRAMEWORK_DIR}"

# ---------------------------------------------------------------------------
# Embed a host-arch Stockfish binary (optional — discover_desktop_path()
# checks Contents/Resources/stockfish; missing binary means custom engine).
# ---------------------------------------------------------------------------
HOST_ARCH="$(uname -m)"
case "${HOST_ARCH}" in
  arm64)  SF_SOURCE_NAME="stockfish-aarch64-apple-darwin" ;;
  x86_64) SF_SOURCE_NAME="stockfish-x86_64-apple-darwin"  ;;
  *)      SF_SOURCE_NAME="" ;;
esac

# Look for a Stockfish binary. scripts/fetch-stockfish.sh writes to
# crates/chess_bridge/binaries/; run that script to enable AI levels 4-10.
SF_CANDIDATES=(
  "${REPO_ROOT}/crates/chess_bridge/binaries/${SF_SOURCE_NAME}"
)
SF_FOUND=""
if [ -n "${SF_SOURCE_NAME}" ]; then
  for c in "${SF_CANDIDATES[@]}"; do
    if [ -x "${c}" ]; then SF_FOUND="${c}"; break; fi
  done
fi

if [ -n "${SF_FOUND}" ]; then
  cp -f "${SF_FOUND}" "${APP_RESOURCES}/stockfish"
  chmod +x "${APP_RESOURCES}/stockfish"
  codesign --force --sign - "${APP_RESOURCES}/stockfish" 2>/dev/null || true
  echo "==> Embedded Stockfish from ${SF_FOUND}"
else
  echo "==> No Stockfish binary found for ${HOST_ARCH}; AI 4-10 will fall back to the custom engine."
  echo "    (Run scripts/fetch-stockfish.sh to download official builds.)"
fi
