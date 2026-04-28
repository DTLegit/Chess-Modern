#!/usr/bin/env bash
# afterFileEdit hook: when crates/chess_bridge/src/api.rs is modified,
# automatically run `flutter_rust_bridge_codegen generate` so the Dart
# bindings under flutter/lib/src/rust/ stay in sync.
#
# Enforces the workspace rule from CLAUDE.md:
#   "When you edit crates/chess_bridge/src/api.rs, you MUST run
#    `flutter_rust_bridge_codegen generate`."
#
# Reads the hook event JSON on stdin, filters on the edited file path,
# and runs codegen only when api.rs changed. Exit 0 always (fail-open) so
# a missing toolchain on a contributor machine doesn't block edits.

set -uo pipefail

input="$(cat)"

# Extract the edited file path from the hook input. Cursor hook payloads
# put it under `tool_input.file_path` for Write / afterFileEdit.
file_path=""
if command -v jq >/dev/null 2>&1; then
  file_path=$(printf '%s' "$input" | jq -r '
    .tool_input.file_path
    // .tool_input.target_file
    // .tool_input.path
    // .tool_input.notebook_path
    // empty
  ')
else
  file_path=$(printf '%s' "$input" \
    | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n1)
fi

case "$file_path" in
  */crates/chess_bridge/src/api.rs|crates/chess_bridge/src/api.rs)
    ;;
  *)
    exit 0
    ;;
esac

if ! command -v flutter_rust_bridge_codegen >/dev/null 2>&1; then
  printf '{"agent_message":"flutter_rust_bridge_codegen not found on PATH; skipping auto-regen. Install with: cargo install flutter_rust_bridge_codegen --version 2.12.0 --locked"}\n'
  exit 0
fi

if flutter_rust_bridge_codegen generate >/tmp/frb-codegen.log 2>&1; then
  printf '{"additional_context":"flutter_rust_bridge_codegen generate ran successfully after edit to %s. Generated files (frb_generated.rs + flutter/lib/src/rust/*.dart) are now refreshed."}\n' "$file_path"
else
  log_excerpt=$(tail -c 800 /tmp/frb-codegen.log | sed 's/"/\\"/g' | tr '\n' ' ')
  printf '{"agent_message":"flutter_rust_bridge_codegen generate FAILED after edit to %s. Last log: %s. The Dart bindings are now stale; do not commit until you fix and re-run codegen."}\n' "$file_path" "$log_excerpt"
fi

exit 0
