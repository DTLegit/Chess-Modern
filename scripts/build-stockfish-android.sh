#!/usr/bin/env bash
# Cross-compile Stockfish 17 for Android (arm64-v8a, armeabi-v7a, x86_64)
# using the Android NDK clang toolchain.
#
# Output:  flutter/android/app/src/main/assets/stockfish/<abi>/stockfish
#          (one binary per ABI; Flutter packages them into the APK and the
#          Rust bridge extracts them to filesDir on first AI request.)
#
# Requirements:
# - ANDROID_NDK_ROOT  : path to NDK r26 or newer (older r-versions also work
#                       but have been less tested).
# - bash, curl, tar, make.
#
# Usage:
#   export ANDROID_NDK_ROOT=$HOME/Android/Sdk/ndk/26.1.10909125
#   bash scripts/build-stockfish-android.sh
#
# The script is idempotent; it will skip work if the resulting binaries
# already exist.

set -euo pipefail

if [[ -z "${ANDROID_NDK_ROOT:-}" ]]; then
  echo "error: ANDROID_NDK_ROOT must be set to your Android NDK install path." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SF_VERSION="${SF_VERSION:-17.1}"
SF_TARBALL_URL="https://github.com/official-stockfish/Stockfish/archive/refs/tags/sf_${SF_VERSION}.tar.gz"
WORK_DIR="${WORK_DIR:-${REPO_ROOT}/.cache/stockfish-android}"
ASSETS_DIR="${REPO_ROOT}/flutter/assets/stockfish"
mkdir -p "${WORK_DIR}" "${ASSETS_DIR}"

SRC_DIR="${WORK_DIR}/Stockfish-sf_${SF_VERSION}"
if [[ ! -d "${SRC_DIR}" ]]; then
  echo "==> downloading Stockfish ${SF_VERSION}"
  curl -L -o "${WORK_DIR}/sf.tgz" "${SF_TARBALL_URL}"
  tar -xzf "${WORK_DIR}/sf.tgz" -C "${WORK_DIR}"
fi

# NDK toolchain selection. Detect the host triple.
HOST_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "${HOST_OS}" in
  darwin) HOST_TAG="darwin-x86_64" ;;
  linux)  HOST_TAG="linux-x86_64" ;;
  *) echo "error: unsupported host OS: ${HOST_OS}" >&2; exit 1 ;;
esac
TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${HOST_TAG}"
if [[ ! -d "${TOOLCHAIN}/bin" ]]; then
  echo "error: ndk toolchain not found at ${TOOLCHAIN}" >&2
  exit 1
fi

# Per-ABI matrix: clang triple, Stockfish ARCH value, output dir name.
# Stockfish supports plain `armv8`, `armv7`, `x86-64-modern` ARCH values.
build_abi() {
  local abi="$1" triple="$2" sf_arch="$3" cxx_extra="${4:-}"
  local out="${ASSETS_DIR}/${abi}/stockfish"
  if [[ -f "${out}" ]]; then
    echo "==> ${abi}: already built (delete to rebuild)"
    return
  fi
  echo "==> building ${abi} (triple=${triple}, ARCH=${sf_arch})"
  local api=21
  local cc="${TOOLCHAIN}/bin/${triple}${api}-clang"
  local cxx="${TOOLCHAIN}/bin/${triple}${api}-clang++"
  if [[ ! -x "${cc}" || ! -x "${cxx}" ]]; then
    echo "error: missing ${cc} or ${cxx}" >&2
    exit 1
  fi
  pushd "${SRC_DIR}/src" >/dev/null
  make clean
  make -j build \
    ARCH="${sf_arch}" \
    COMP=clang \
    CXX="${cxx}" \
    CXXFLAGS="-fPIC ${cxx_extra}" \
    LDFLAGS="-fPIC -static-libstdc++"
  mkdir -p "$(dirname "${out}")"
  cp ./stockfish "${out}"
  chmod 0755 "${out}"
  popd >/dev/null
}

# ABI list:
#   - arm64-v8a:    aarch64-linux-android, ARCH=armv8
#   - armeabi-v7a:  armv7a-linux-androideabi, ARCH=armv7
#   - x86_64:       x86_64-linux-android, ARCH=x86-64-modern
build_abi "arm64-v8a"     "aarch64-linux-android"    "armv8"
build_abi "armeabi-v7a"   "armv7a-linux-androideabi" "armv7"  "-march=armv7-a"
build_abi "x86_64"        "x86_64-linux-android"     "x86-64-modern"

echo
echo "==> Stockfish binaries written under ${ASSETS_DIR}/<abi>/stockfish"
echo "    flutter/pubspec.yaml already declares assets/stockfish/, so a"
echo "    subsequent 'flutter build apk' bundles them. The Rust bridge"
echo "    extracts the matching ABI to getApplicationSupportDirectory()"
echo "    and spawns it on first AI request."
