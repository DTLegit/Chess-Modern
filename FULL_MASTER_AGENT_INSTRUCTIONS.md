# 🧠 MASTER_AGENT_INSTRUCTIONS.md
# Full System Orchestration Spec — Chess App Refactor

---

## 🎯 PURPOSE

This document defines the COMPLETE execution plan for refactoring the chess application.

You (Parent Agent: Claude Opus 4.7) will orchestrate:

1. Frontend Subagent (Claude Opus 4.7)
2. Backend Subagent (GPT-5.5)

You DO NOT implement code directly.
You coordinate, validate, and enforce architecture.

---

# 🧭 CORE ARCHITECTURE RULE (NON-NEGOTIABLE)

Rust GameSession is the ONLY source of truth.
Flutter renders state and sends commands.
No chess logic exists in Flutter.

---

# 🧩 SYSTEM ARCHITECTURE

Flutter UI
↓
flutter_rust_bridge
↓
Rust GameSession (rules engine)
↓
AiProvider system

---

# ⚠️ GLOBAL CONSTRAINTS

- Do NOT modify Rust bridge unless planned
- No duplicated logic across layers
- Maintain:
  - cargo test --workspace
  - flutter analyze
  - flutter test
- No frontend rule validation
- Backend must own all state transitions

---

# 📦 EXECUTION PHASES

## Phase 1 — Frontend Visual Parity (STRICT)
- Follow VISUAL_PARITY_AGENT_PROMPT.md
- NO backend changes allowed

## Phase 2 — Backend Refactor
- Implement GameSession + rules + AI

## Phase 3 — Integration
- Update API if needed
- Sync frontend/backend

## Phase 4 — Polish
- UX, animations, bug fixes

---

# 🎨 FRONTEND SUBAGENT SPEC (CLAUDE)

## Visual Parity
- Legacy Svelte UI = source of truth
- Match:
  - colors
  - typography
  - spacing
  - layout
  - animations

## Remove Material
- Replace MaterialApp → WidgetsApp
- No Material widgets

## Design System
- tokens.dart
- typography.dart
- app_theme.dart

## Primitives
- AppButton
- AppDialog
- AppPanel
- AppListRow
- AppScaffold
- AppControls (slider/switch/etc.)

## Board UX
- drag-to-move
- tap-to-move
- highlights
- in-board promotion

## Restore Features
- PGN save dialog
- promotion overlay
- drag support

## State Management
- Riverpod

Flow:
UI → Controller → Rust → GameUpdate → UI

---

# 🧠 BACKEND SUBAGENT SPEC (GPT-5.5)

## GameSession

Central authority:

struct GameSession {
    position
    history
    clocks
    state
    result
}

---

## Commands

enum GameCommand {
    MakeMove,
    Resign,
    OfferDraw,
    AcceptDraw,
    ClaimThreefold,
    ClaimFiftyMove,
    UndoMove,
}

---

## Rules (FULL)

- legal moves
- castling
- en passant
- promotion
- check/checkmate
- stalemate
- threefold repetition
- fifty-move rule
- insufficient material

---

## AI System

trait AiProvider {
    fn choose_move(...)
}

Providers:
- BuiltInEngineProvider (default)
- StockfishProvider (optional)

Features:
- weighted randomness
- difficulty tiers
- personalities
- opening variation
- anti-pattern memory

---

## Additional Systems

- save/load
- replay
- undo/redo
- Zobrist hashing
- clock system
- move history
- error model

---

## Testing

- perft
- edge cases
- FEN/SAN/PGN
- AI legality

---

# 🔄 COORDINATION RULES

## Phase 1
Frontend ONLY

## Phase 2
Backend refactor

## Phase 3
API evolution allowed

---

# 🛑 FAILURE CONDITIONS

- frontend adds rule logic
- backend breaks API early
- tests fail
- duplicate logic appears

---

# ✅ SUCCESS CRITERIA

- UI matches Svelte
- rules correct
- AI non-deterministic
- cross-platform consistent
- no desync possible

---

# 🧭 FINAL DIRECTIVE

You are the orchestrator.

Prioritize:

system integrity > speed
