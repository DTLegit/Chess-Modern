// Browser-only mock implementation of `ChessApi`. Lets the frontend subagent
// build and exercise the entire UI before the Rust backend is finished.
//
// The mock plays *legal-shaped* but extremely shallow chess: it accepts any
// "looks plausible" move so the UI's interaction flow can be tested. The
// real engine replaces this in Phase 2.

import type { UnlistenFn } from "@tauri-apps/api/event";
import type {
  AiProgressEvent,
  ClockTickEvent,
  Color,
  GameId,
  GameOverEvent,
  GameSnapshot,
  MoveMadeEvent,
  MoveResult,
  NewGameOpts,
  Piece,
  PieceKind,
  Promotion,
  Settings,
  SquareStr,
  TimeControl,
} from "./contract";
import type { ChessApi } from "./client";

const FILES = ["a", "b", "c", "d", "e", "f", "g", "h"] as const;

function uuid(): string {
  return crypto.randomUUID();
}

function startingBoard(): Map<SquareStr, Piece> {
  const board = new Map<SquareStr, Piece>();
  const back: PieceKind[] = ["r", "n", "b", "q", "k", "b", "n", "r"];
  for (let i = 0; i < 8; i++) {
    board.set(`${FILES[i]}1`, { color: "w", kind: back[i] });
    board.set(`${FILES[i]}2`, { color: "w", kind: "p" });
    board.set(`${FILES[i]}7`, { color: "b", kind: "p" });
    board.set(`${FILES[i]}8`, { color: "b", kind: back[i] });
  }
  return board;
}

function pseudoLegal(
  board: Map<SquareStr, Piece>,
  turn: Color,
): Record<SquareStr, SquareStr[]> {
  const out: Record<SquareStr, SquareStr[]> = {};
  for (const [sq, piece] of board) {
    if (piece.color !== turn) continue;
    out[sq] = [];
    for (let f = 0; f < 8; f++) {
      for (let r = 1; r <= 8; r++) {
        const t = `${FILES[f]}${r}`;
        if (t === sq) continue;
        const target = board.get(t);
        if (target && target.color === piece.color) continue;
        out[sq].push(t);
      }
    }
  }
  return out;
}

function fenFromBoard(board: Map<SquareStr, Piece>, turn: Color): string {
  const rows: string[] = [];
  for (let r = 8; r >= 1; r--) {
    let row = "";
    let empty = 0;
    for (let f = 0; f < 8; f++) {
      const p = board.get(`${FILES[f]}${r}`);
      if (!p) {
        empty++;
        continue;
      }
      if (empty) {
        row += String(empty);
        empty = 0;
      }
      const c = p.kind;
      row += p.color === "w" ? c.toUpperCase() : c;
    }
    if (empty) row += String(empty);
    rows.push(row);
  }
  return `${rows.join("/")} ${turn} - - 0 1`;
}

interface MockGame {
  id: GameId;
  board: Map<SquareStr, Piece>;
  turn: Color;
  history: MoveResult["mv"][];
  snapshot: GameSnapshot;
  opts: NewGameOpts;
}

const games = new Map<GameId, MockGame>();
const settings: Settings = {
  app_theme: "light",
  board_theme: "wood",
  piece_set: "merida",
  accent: "walnut",
  sound_enabled: true,
  sound_volume: 0.6,
  show_legal_moves: true,
  show_coordinates: true,
  show_last_move: true,
};

function snapshotOf(g: MockGame): GameSnapshot {
  return {
    game_id: g.id,
    fen: fenFromBoard(g.board, g.turn),
    turn: g.turn,
    in_check: false,
    status: "active",
    result: "ongoing",
    history: g.history,
    legal_moves: pseudoLegal(g.board, g.turn),
    clock: g.snapshot.clock,
    mode: g.opts.mode,
    ai_difficulty: g.opts.ai_difficulty,
    human_color:
      g.opts.human_color === "b" ? "b" : g.opts.human_color === "random"
        ? Math.random() < 0.5 ? "w" : "b"
        : "w",
    last_move: g.history.at(-1) ?? null,
  };
}

type Listener<T> = (e: T) => void;
const moveListeners = new Set<Listener<MoveMadeEvent>>();
const aiListeners = new Set<Listener<AiProgressEvent>>();
const overListeners = new Set<Listener<GameOverEvent>>();
const clockListeners = new Set<Listener<ClockTickEvent>>();

function unlisten<T>(set: Set<Listener<T>>, l: Listener<T>): UnlistenFn {
  return () => {
    set.delete(l);
  };
}

export const mockApi: ChessApi = {
  async newGame(opts) {
    const id = uuid();
    const board = startingBoard();
    const game: MockGame = {
      id,
      board,
      turn: "w",
      history: [],
      opts,
      snapshot: {
        game_id: id,
        fen: "",
        turn: "w",
        in_check: false,
        status: "active",
        result: "ongoing",
        history: [],
        legal_moves: {},
        clock: opts.time_control
          ? {
              white_ms: opts.time_control.initial_ms,
              black_ms: opts.time_control.initial_ms,
              active: "w",
              paused: false,
            }
          : null,
        mode: opts.mode,
        ai_difficulty: opts.ai_difficulty,
        human_color: opts.human_color === "b" ? "b" : "w",
        last_move: null,
      },
    };
    game.snapshot = snapshotOf(game);
    games.set(id, game);
    return game.snapshot;
  },

  async legalMovesFrom(gameId, square) {
    const g = games.get(gameId);
    if (!g) throw { kind: "GameNotFound", message: gameId };
    return g.snapshot.legal_moves[square] ?? [];
  },

  async makeMove(gameId, from, to, promotion: Promotion | null = null) {
    const g = games.get(gameId);
    if (!g) throw { kind: "GameNotFound", message: gameId };
    const piece = g.board.get(from);
    if (!piece || piece.color !== g.turn) {
      throw { kind: "IllegalMove", message: `${from}->${to}` };
    }
    const captured = g.board.get(to) ?? null;
    g.board.delete(from);
    g.board.set(to, promotion ? { color: piece.color, kind: promotion } : piece);
    g.turn = g.turn === "w" ? "b" : "w";
    const mv = {
      from,
      to,
      promotion,
      san: `${piece.kind === "p" ? "" : piece.kind.toUpperCase()}${to}`,
      uci: `${from}${to}${promotion ?? ""}`,
      captured,
      is_check: false,
      is_mate: false,
      is_castle: false,
      is_en_passant: false,
    };
    g.history.push(mv);
    g.snapshot = snapshotOf(g);
    moveListeners.forEach((l) =>
      l({ game_id: gameId, mv, snapshot: g.snapshot }),
    );
    return { mv, snapshot: g.snapshot };
  },

  async requestAiMove(gameId) {
    const g = games.get(gameId);
    if (!g) throw { kind: "GameNotFound", message: gameId };
    aiListeners.forEach((l) =>
      l({ game_id: gameId, depth: 4, eval_cp: 0, pv_san: ["e4"] }),
    );
    const moves = Object.entries(g.snapshot.legal_moves).filter(
      ([_, ts]) => ts.length > 0,
    );
    if (moves.length === 0) return;
    const [from, ts] = moves[Math.floor(Math.random() * moves.length)];
    const to = ts[Math.floor(Math.random() * ts.length)];
    setTimeout(() => {
      void this.makeMove(gameId, from, to);
    }, 350);
  },

  async undoMove(gameId) {
    const g = games.get(gameId);
    if (!g) throw { kind: "GameNotFound", message: gameId };
    return g.snapshot;
  },
  async resign(gameId) {
    const g = games.get(gameId)!;
    g.snapshot = { ...g.snapshot, status: "resigned", result: g.turn === "w" ? "black" : "white" };
    overListeners.forEach((l) => l({ game_id: gameId, result: g.snapshot.result, reason: "resigned" }));
    return g.snapshot;
  },
  async offerDraw(gameId) {
    return games.get(gameId)!.snapshot;
  },
  async claimDraw(gameId) {
    return games.get(gameId)!.snapshot;
  },
  async loadPgn(_pgn) {
    return this.newGame({ mode: "hvh", ai_difficulty: null, human_color: "w", time_control: null });
  },
  async exportPgn(gameId) {
    const g = games.get(gameId)!;
    return g.history.map((m) => m.san).join(" ");
  },
  async setClock(gameId, tc: TimeControl) {
    const g = games.get(gameId)!;
    g.snapshot = { ...g.snapshot, clock: { white_ms: tc.initial_ms, black_ms: tc.initial_ms, active: g.turn, paused: false } };
    return g.snapshot;
  },
  async pauseClock(gameId) {
    const g = games.get(gameId)!;
    if (g.snapshot.clock) g.snapshot = { ...g.snapshot, clock: { ...g.snapshot.clock, paused: true } };
    return g.snapshot;
  },
  async resumeClock(gameId) {
    const g = games.get(gameId)!;
    if (g.snapshot.clock) g.snapshot = { ...g.snapshot, clock: { ...g.snapshot.clock, paused: false } };
    return g.snapshot;
  },
  async getSettings() {
    return settings;
  },
  async setSettings(s) {
    Object.assign(settings, s);
    settings.piece_set = "merida";
    if (!settings.accent) settings.accent = "walnut";
    return settings;
  },
  async onMoveMade(h) {
    moveListeners.add(h);
    return unlisten(moveListeners, h);
  },
  async onAiProgress(h) {
    aiListeners.add(h);
    return unlisten(aiListeners, h);
  },
  async onGameOver(h) {
    overListeners.add(h);
    return unlisten(overListeners, h);
  },
  async onClockTick(h) {
    clockListeners.add(h);
    return unlisten(clockListeners, h);
  },
};
