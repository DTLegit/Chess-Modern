# AGENTS.md

Guidance for AI coding agents working on this repository, with a focus
on **Cursor Cloud Agents** running in the orchestrated four-phase
refactor.

For local-IDE agents, the canonical short brief is [CLAUDE.md](CLAUDE.md).
For the orchestration plan and phase ownership, see
[FULL_MASTER_AGENT_INSTRUCTIONS.md](FULL_MASTER_AGENT_INSTRUCTIONS.md).
For the Phase 1 visual-parity spec, see
[VISUAL_PARITY_AGENT_PROMPT.md](VISUAL_PARITY_AGENT_PROMPT.md).
For the parent cloud agent's kickoff prompt, see
[CLOUD_PARENT_AGENT_PROMPT.md](CLOUD_PARENT_AGENT_PROMPT.md).

## Non-negotiable architecture rule

**Rust `GameSession` (in `crates/chess_core/`) is the only source of
truth.** Flutter renders state and sends commands. **No chess logic in
Flutter, ever.** This rule is invariant across all four phases. The
moment a frontend agent is tempted to validate a move, compute legality,
or hold game state outside the Rust core, stop and ask.

## Phase boundaries

| Phase | Owner agent | Branch | What it can touch |
| --- | --- | --- | --- |
| 1 — Visual parity | Frontend (`claude-4.6-sonnet-medium-thinking`) | `phase-1-visual-parity` | Flutter UI only. Zero changes to `crates/`, `flutter/lib/src/rust/`, or `crates/chess_bridge/src/api.rs`. |
| 2 — Backend refactor | Backend (`gpt-5.3-codex-high-fast`) | `phase-2-backend-refactor` | Rust internals (`crates/chess_core/`). Bridge API (`crates/chess_bridge/src/api.rs` exported types + 15 commands + `BackendEvent` variants) MUST stay byte-stable. |
| 3 — Integration | Backend then Frontend | `phase-3-integration` | Bridge API evolution allowed. Codegen MUST be re-run (`flutter_rust_bridge_codegen generate`). Flutter consumes new bindings in the same phase before merge. |
| 4 — Polish | Frontend (Backend on demand) | `phase-4-polish` | UX, perf, bug fixes from Phase 3 smoke. |

Models chosen for cost-efficiency on a tight token budget. The parent
MAY upgrade individual subagent runs to `claude-opus-4-7-thinking-xhigh`
or `gpt-5.5-extra-high` on a per-run basis if reasoning quality
demands it, with explicit justification.

A subagent that catches itself drifting outside its phase's scope must
stop and post a comment on the working branch instead of expanding
scope.

## Cloud agent constraints (Linux x86_64 only)

Cloud agents run in Ubuntu Linux x86_64 VMs provisioned by
[`.cursor/install.sh`](.cursor/install.sh). The VM has Rust stable +
Flutter 3.27.0 + Android SDK + NDK r26 + flutter_rust_bridge_codegen
v2.12 + Stockfish stubs for the legacy Tauri shell.

**What cloud agents can verify:**

- `cargo test --workspace --all-targets`
- `flutter analyze`
- `flutter test`
- `flutter build linux --debug` (Linux desktop is the only fully-wired
  platform per `[CLAUDE.md](CLAUDE.md)`'s "Native library wiring" note)
- `flutter build apk --debug` (build-only; emulator runs are not
  available — no nested virtualization in cloud VMs)

**What cloud agents cannot verify; defer to a final local pass on a
developer machine:**

- macOS desktop launch (`flutter build macos`, manual visual review)
- Windows desktop builds (no Windows VM in Cursor cloud)
- iOS simulator runs (no Xcode in cloud)
- Real Android emulator behavior

If you're a cloud agent and your acceptance gate would have required
one of these, mark the gate as "deferred to local pass" in your final
status comment instead of failing.

## Branching policy (cloud)

- One branch per phase, branched from current `master`. Names follow
  the table above.
- Cloud agents auto-push their working branches. Do NOT auto-create PRs
  (`target.autoCreatePr: false`); the parent orchestrator merges to
  `master` after the phase gate passes.
- Commit per logical milestone with clear messages. Cursor signs commits
  with HSM Ed25519 keys; verified badges appear automatically.

## Bridge contract is the contract

Outside Phase 3 the bridge API is byte-stable. The contract:

- `crates/chess_bridge/src/api.rs` — 15 command functions + `subscribeEvents()` + `bridgeInit(dataDir)` + `bridgeProvideExternalStockfish(binaryPath)` and the exported types (mostly `#[frb(mirror)]` of `chess_core::api`).
- The four legacy Tauri event names, unified under `BackendEvent` variants. Generated Dart bindings under `flutter/lib/src/rust/` are a function of `api.rs`.

Self-check before committing:

```bash
git diff origin/master -- crates/chess_bridge/src/api.rs flutter/lib/src/rust/
```

In Phases 1, 2, 4 this diff MUST be empty. In Phase 3 it MUST be
non-empty AND the codegen MUST have re-run successfully (the
`afterFileEdit` hook at [.cursor/hooks/regen-frb-bindings.sh](.cursor/hooks/regen-frb-bindings.sh)
runs it automatically; verify via `git status flutter/lib/src/rust/`).

## Codegen rules

- After ANY edit to `crates/chess_bridge/src/api.rs`, the
  `afterFileEdit` hook automatically runs
  `flutter_rust_bridge_codegen generate`. Verify the regenerated files
  are part of your commit.
- **NEVER** run `flutter_rust_bridge_codegen integrate`. It is
  destructive — it overwrites runner files for every platform. The
  bindings are already integrated; only `... codegen generate` is
  ever needed.

## Stockfish

Per [KNOWN_ISSUES.md](KNOWN_ISSUES.md):

- Desktop sidecars are gitignored. The install script attempts a
  best-effort fetch via `scripts/fetch-stockfish.sh`. Failure is
  non-fatal — the missing-binary path falls back to the custom Rust
  engine transparently.
- Android per-ABI binaries are NDK source-built via
  `scripts/build-stockfish-android.sh`. The cloud agent has the NDK
  installed and `ANDROID_NDK_ROOT` set, so this script will run if
  invoked. Same fallback applies on missing binaries.
- iOS uses the custom engine for all levels (sandbox forbids spawning).
  This code path cannot be exercised in cloud — trust its unit tests.

## Tests must stay green

`cargo test --workspace --all-targets` exercises the legacy Tauri shell
because it's still a workspace member. The install script stages
Stockfish stub binaries under `src-tauri/binaries/` so this passes
without real binaries (mirrors the pattern in
`.github/workflows/ci.yml`).

`flutter test` and `flutter analyze` must stay clean at every commit.

## Failure handling

If you hit a hard blocker:

1. Stop. Do not expand scope to "fix it anyway."
2. Commit a status comment to your working branch documenting:
   - what you were trying to do
   - what blocked you
   - the smallest safe partial state you've left behind
   - 2–3 options for how to proceed
3. End your run. The parent orchestrator (or the human) will resume
   you with direction via a follow-up message.

The four global failure conditions from
[FULL_MASTER_AGENT_INSTRUCTIONS.md](FULL_MASTER_AGENT_INSTRUCTIONS.md)
are hard-stop triggers regardless of phase:

- frontend adds chess rule logic
- backend breaks the bridge API outside Phase 3
- tests fail
- duplicate logic appears in both layers
