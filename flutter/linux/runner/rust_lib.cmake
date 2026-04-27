# Build the chess_bridge Rust crate as a cdylib and link it into the
# Linux runner. flutter_rust_bridge requires the dynamic library to be
# present alongside the runner binary at runtime; we copy it into
# bundle/lib/ during install.

# CMAKE_CURRENT_SOURCE_DIR here is .../flutter/linux when this file
# is included from the top-level CMakeLists.txt. The Rust workspace
# lives two directories up from there.
get_filename_component(REPO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
set(RUST_CRATE_DIR "${REPO_ROOT}/crates/chess_bridge")
set(RUST_TARGET_DIR "${REPO_ROOT}/target")

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(CARGO_PROFILE_FLAG "")
  set(CARGO_PROFILE_DIR "debug")
else()
  set(CARGO_PROFILE_FLAG "--release")
  set(CARGO_PROFILE_DIR "release")
endif()

add_custom_target(rust_lib ALL
  COMMAND cargo build --manifest-path "${RUST_CRATE_DIR}/Cargo.toml" ${CARGO_PROFILE_FLAG}
  WORKING_DIRECTORY "${REPO_ROOT}"
  COMMENT "Building chess_bridge cdylib in ${CARGO_PROFILE_DIR}"
)

set(RUST_LIB_PATH "${RUST_TARGET_DIR}/${CARGO_PROFILE_DIR}/libchess_bridge.so")
