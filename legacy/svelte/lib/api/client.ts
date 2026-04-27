// Real Tauri-backed implementation of the API contract.
// The frontend subagent imports `chess` from `./index.ts` which selects
// between this client and the mock client based on `import.meta.env`.

import { invoke } from "@tauri-apps/api/core";
import { listen, type UnlistenFn } from "@tauri-apps/api/event";

import type {
  AiProgressEvent,
  ClockTickEvent,
  GameId,
  GameOverEvent,
  GameSnapshot,
  MoveMadeEvent,
  MoveResult,
  NewGameOpts,
  Promotion,
  Settings,
  SquareStr,
  TimeControl,
} from "./contract";

export interface ChessApi {
  newGame(opts: NewGameOpts): Promise<GameSnapshot>;
  legalMovesFrom(gameId: GameId, square: SquareStr): Promise<SquareStr[]>;
  makeMove(
    gameId: GameId,
    from: SquareStr,
    to: SquareStr,
    promotion?: Promotion | null,
  ): Promise<MoveResult>;
  requestAiMove(gameId: GameId): Promise<void>;
  undoMove(gameId: GameId): Promise<GameSnapshot>;
  resign(gameId: GameId): Promise<GameSnapshot>;
  offerDraw(gameId: GameId): Promise<GameSnapshot>;
  claimDraw(gameId: GameId): Promise<GameSnapshot>;
  loadPgn(pgn: string): Promise<GameSnapshot>;
  exportPgn(gameId: GameId): Promise<string>;
  setClock(gameId: GameId, tc: TimeControl): Promise<GameSnapshot>;
  pauseClock(gameId: GameId): Promise<GameSnapshot>;
  resumeClock(gameId: GameId): Promise<GameSnapshot>;
  getSettings(): Promise<Settings>;
  setSettings(settings: Settings): Promise<Settings>;
  onMoveMade(handler: (e: MoveMadeEvent) => void): Promise<UnlistenFn>;
  onAiProgress(handler: (e: AiProgressEvent) => void): Promise<UnlistenFn>;
  onGameOver(handler: (e: GameOverEvent) => void): Promise<UnlistenFn>;
  onClockTick(handler: (e: ClockTickEvent) => void): Promise<UnlistenFn>;
}

export const tauriApi: ChessApi = {
  newGame: (opts) => invoke("new_game", { opts }),
  legalMovesFrom: (gameId, square) =>
    invoke("legal_moves_from", { gameId, square }),
  makeMove: (gameId, from, to, promotion = null) =>
    invoke("make_move", { gameId, from, to, promotion }),
  requestAiMove: (gameId) => invoke("request_ai_move", { gameId }),
  undoMove: (gameId) => invoke("undo_move", { gameId }),
  resign: (gameId) => invoke("resign", { gameId }),
  offerDraw: (gameId) => invoke("offer_draw", { gameId }),
  claimDraw: (gameId) => invoke("claim_draw", { gameId }),
  loadPgn: (pgn) => invoke("load_pgn", { pgn }),
  exportPgn: (gameId) => invoke("export_pgn", { gameId }),
  setClock: (gameId, timeControl) =>
    invoke("set_clock", { gameId, timeControl }),
  pauseClock: (gameId) => invoke("pause_clock", { gameId }),
  resumeClock: (gameId) => invoke("resume_clock", { gameId }),
  getSettings: () => invoke("get_settings"),
  setSettings: (settings) => invoke("set_settings", { settings }),
  onMoveMade: (h) => listen<MoveMadeEvent>("move-made", (e) => h(e.payload)),
  onAiProgress: (h) =>
    listen<AiProgressEvent>("ai-progress", (e) => h(e.payload)),
  onGameOver: (h) => listen<GameOverEvent>("game-over", (e) => h(e.payload)),
  onClockTick: (h) =>
    listen<ClockTickEvent>("clock-tick", (e) => h(e.payload)),
};
