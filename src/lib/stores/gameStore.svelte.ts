// Central game store. Wraps the API, tracks selection / promotion / scrub,
// keeps a list of per-ply snapshots so history scrubbing is instantaneous,
// and emits hooks (move/capture/check/end) so the audio module can react.

import { chess } from "../api";
import type {
  ClockTickEvent,
  Color,
  GameOverEvent,
  GameSnapshot,
  Move,
  MoveMadeEvent,
  NewGameOpts,
  Piece,
  Promotion,
  SquareStr,
} from "../api/contract";
import { parseFenBoard } from "../util/fen";

type SoundKind = "move" | "capture" | "check" | "castle" | "promote" | "end";
type SoundHandler = (kind: SoundKind) => void;

export interface PendingPromotion {
  from: SquareStr;
  to: SquareStr;
  color: Color;
}

class GameStore {
  /** Live snapshot from the engine (latest). */
  live = $state<GameSnapshot | null>(null);
  /** All snapshots through history; index 0 = starting position. */
  snapshots = $state<GameSnapshot[]>([]);
  /** Index into snapshots when scrubbing; null = live. */
  scrubIndex = $state<number | null>(null);
  /** Selected source square. */
  selected = $state<SquareStr | null>(null);
  /** When set, show the promotion modal at this square. */
  pendingPromotion = $state<PendingPromotion | null>(null);
  /** Board orientation (white at bottom by default). */
  orientation = $state<Color>("w");
  /** True while waiting for AI/network. */
  thinking = $state(false);
  /** Last move (for highlight); null when scrubbing to start. */
  // derived below
  /** Ephemeral hint (e.g. "Illegal move") shown beneath the board. */
  hint = $state<string | null>(null);

  private soundHandlers = new Set<SoundHandler>();
  private moveUnlisten: (() => void) | null = null;
  private overUnlisten: (() => void) | null = null;
  private clockUnlisten: (() => void) | null = null;
  private hintTimer: ReturnType<typeof setTimeout> | null = null;
  /** Local clock interpolation (mock has no clock-tick events). */
  private clockTimer: ReturnType<typeof setInterval> | null = null;
  private clockLastTs = 0;

  /** The snapshot the user is currently viewing (live or scrubbed). */
  view = $derived<GameSnapshot | null>(
    this.live == null
      ? null
      : this.scrubIndex == null
        ? this.live
        : this.snapshots[this.scrubIndex] ?? this.live,
  );

  /** Board pieces from view. */
  board = $derived<Map<SquareStr, Piece>>(
    this.view ? parseFenBoard(this.view.fen) : new Map(),
  );

  /** Last move shown on board (depends on view). */
  lastMove = $derived<Move | null>(this.view?.last_move ?? null);

  /** Legal targets for the currently selected square (live only). */
  legalForSelected = $derived<SquareStr[]>(
    this.selected && this.scrubIndex == null && this.live
      ? this.live.legal_moves[this.selected] ?? []
      : [],
  );

  /** True when board interaction is locked (scrubbing or modal open). */
  inputLocked = $derived(this.scrubIndex != null || this.pendingPromotion != null);

  isAtLive = $derived(this.scrubIndex == null);

  // ------------------------------------------------------------ subscriptions

  async init() {
    if (this.moveUnlisten) return;
    this.moveUnlisten = await chess.onMoveMade((e) => this.onMoveEvent(e));
    this.overUnlisten = await chess.onGameOver((e) => this.onOverEvent(e));
    this.clockUnlisten = await chess.onClockTick((e) => this.onClockEvent(e));
  }

  onSound(h: SoundHandler): () => void {
    this.soundHandlers.add(h);
    return () => this.soundHandlers.delete(h);
  }

  private fire(kind: SoundKind) {
    this.soundHandlers.forEach((h) => h(kind));
  }

  // ------------------------------------------------------------ game lifecycle

  async newGame(opts: NewGameOpts) {
    this.clearHint();
    this.selected = null;
    this.pendingPromotion = null;
    this.scrubIndex = null;
    this.thinking = false;
    const snap = await chess.newGame(opts);
    this.live = snap;
    this.snapshots = [snap];
    this.orientation = snap.human_color ?? "w";
    this.startClockTimerIfNeeded();
    if (snap.mode === "hva" && snap.human_color && snap.turn !== snap.human_color) {
      this.requestAi();
    }
  }

  /** Try a move from `from` -> `to`. Returns true if accepted. */
  async tryMove(from: SquareStr, to: SquareStr): Promise<boolean> {
    if (!this.live || this.inputLocked) return false;
    const piece = this.board.get(from);
    if (!piece) return false;
    if (piece.color !== this.live.turn) return false;
    const legal = this.live.legal_moves[from] ?? [];
    if (!legal.includes(to)) {
      this.flashHint("Illegal move");
      return false;
    }
    // Detect promotion: pawn moves to last rank.
    const isPawn = piece.kind === "p";
    const lastRank = piece.color === "w" ? "8" : "1";
    if (isPawn && to.endsWith(lastRank)) {
      this.pendingPromotion = { from, to, color: piece.color };
      return true;
    }
    await this.commitMove(from, to, null);
    return true;
  }

  async commitPromotion(promo: Promotion) {
    const p = this.pendingPromotion;
    this.pendingPromotion = null;
    if (!p) return;
    await this.commitMove(p.from, p.to, promo);
  }

  cancelPromotion() {
    this.pendingPromotion = null;
  }

  private async commitMove(
    from: SquareStr,
    to: SquareStr,
    promotion: Promotion | null,
  ) {
    if (!this.live) return;
    try {
      await chess.makeMove(this.live.game_id, from, to, promotion);
      // The MoveMade event listener actually updates state.
    } catch (err) {
      this.flashHint("Move rejected");
      console.warn("makeMove failed", err);
    }
  }

  private onMoveEvent(e: MoveMadeEvent) {
    if (!this.live || e.game_id !== this.live.game_id) return;
    this.live = e.snapshot;
    this.snapshots = [...this.snapshots, e.snapshot];
    this.selected = null;
    this.scrubIndex = null;
    // Sounds
    if (e.mv.is_castle) this.fire("castle");
    else if (e.mv.captured) this.fire("capture");
    else this.fire("move");
    if (e.mv.promotion) this.fire("promote");
    if (e.mv.is_check && !e.mv.is_mate) this.fire("check");
    this.startClockTimerIfNeeded();
    // Trigger AI if it's their turn now.
    if (
      e.snapshot.mode === "hva" &&
      e.snapshot.status === "active" &&
      e.snapshot.human_color &&
      e.snapshot.turn !== e.snapshot.human_color
    ) {
      this.requestAi();
    }
  }

  private onOverEvent(e: GameOverEvent) {
    if (!this.live || e.game_id !== this.live.game_id) return;
    this.live = { ...this.live, status: e.reason, result: e.result };
    this.snapshots = [...this.snapshots.slice(0, -1), this.live];
    this.fire("end");
    this.stopClockTimer();
  }

  private onClockEvent(e: ClockTickEvent) {
    if (!this.live || e.game_id !== this.live.game_id || !this.live.clock) return;
    this.live = {
      ...this.live,
      clock: {
        ...this.live.clock,
        white_ms: e.white_ms,
        black_ms: e.black_ms,
        active: e.active,
      },
    };
  }

  // ------------------------------------------------------------ selection

  select(sq: SquareStr | null) {
    if (this.inputLocked) return;
    if (sq == null) {
      this.selected = null;
      return;
    }
    if (this.selected === sq) {
      this.selected = null;
      return;
    }
    if (this.selected) {
      const legal = this.live?.legal_moves[this.selected] ?? [];
      if (legal.includes(sq)) {
        const from = this.selected;
        this.selected = null;
        void this.tryMove(from, sq);
        return;
      }
    }
    const piece = this.board.get(sq);
    if (piece && this.live && piece.color === this.live.turn) {
      this.selected = sq;
    } else {
      this.selected = null;
    }
  }

  deselect() {
    this.selected = null;
  }

  // ------------------------------------------------------------ history scrub

  scrubTo(index: number | null) {
    if (index == null) {
      this.scrubIndex = null;
      return;
    }
    if (index < 0) index = 0;
    if (index >= this.snapshots.length) index = this.snapshots.length - 1;
    this.scrubIndex = index === this.snapshots.length - 1 ? null : index;
    this.selected = null;
  }

  scrubStep(delta: number) {
    const cur = this.scrubIndex ?? this.snapshots.length - 1;
    this.scrubTo(cur + delta);
  }

  scrubLive() {
    this.scrubIndex = null;
  }

  // ------------------------------------------------------------ misc actions

  async undo() {
    if (!this.live) return;
    if (this.snapshots.length <= 1) return;
    try {
      const snap = await chess.undoMove(this.live.game_id);
      // Optimistic local pop too in case backend is a stub.
      this.snapshots = this.snapshots.slice(0, -1);
      const last = this.snapshots[this.snapshots.length - 1] ?? snap;
      this.live = last;
      this.scrubIndex = null;
      this.selected = null;
    } catch (err) {
      console.warn("undo failed", err);
    }
  }

  async resign() {
    if (!this.live) return;
    try {
      await chess.resign(this.live.game_id);
    } catch (err) {
      console.warn("resign failed", err);
    }
  }

  async exportPgn(): Promise<string> {
    if (!this.live) return "";
    try {
      return await chess.exportPgn(this.live.game_id);
    } catch {
      return this.live.history.map((m) => m.san).join(" ");
    }
  }

  flip() {
    this.orientation = this.orientation === "w" ? "b" : "w";
  }

  setOrientation(c: Color) {
    this.orientation = c;
  }

  flashHint(message: string) {
    this.hint = message;
    if (this.hintTimer) clearTimeout(this.hintTimer);
    this.hintTimer = setTimeout(() => {
      this.hint = null;
    }, 1600);
  }

  clearHint() {
    if (this.hintTimer) clearTimeout(this.hintTimer);
    this.hint = null;
  }

  private async requestAi() {
    if (!this.live) return;
    this.thinking = true;
    try {
      await chess.requestAiMove(this.live.game_id);
    } catch (err) {
      console.warn("requestAi failed", err);
    } finally {
      // The actual move arrives async; clear after a short tick.
      setTimeout(() => (this.thinking = false), 600);
    }
  }

  // ------------------------------------------------------------ clock interpolation
  // The mock doesn't fire clock-tick events. We do a lightweight local tick
  // so the UI clock visibly counts down. The real backend will overwrite
  // with authoritative values via onClockEvent.

  private startClockTimerIfNeeded() {
    this.stopClockTimer();
    if (!this.live?.clock) return;
    if (this.live.status !== "active") return;
    this.clockLastTs = performance.now();
    this.clockTimer = setInterval(() => this.tickLocalClock(), 100);
  }

  private stopClockTimer() {
    if (this.clockTimer) clearInterval(this.clockTimer);
    this.clockTimer = null;
  }

  private tickLocalClock() {
    const live = this.live;
    if (!live || !live.clock || live.clock.paused || !live.clock.active) return;
    if (live.status !== "active") {
      this.stopClockTimer();
      return;
    }
    const now = performance.now();
    const delta = Math.max(0, now - this.clockLastTs);
    this.clockLastTs = now;
    const c = live.clock;
    const white_ms = c.active === "w" ? Math.max(0, c.white_ms - delta) : c.white_ms;
    const black_ms = c.active === "b" ? Math.max(0, c.black_ms - delta) : c.black_ms;
    this.live = { ...live, clock: { ...c, white_ms, black_ms } };
  }
}

export const game = new GameStore();
