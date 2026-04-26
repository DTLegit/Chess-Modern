<script lang="ts">
  import type {
    Color,
    Move,
    Piece as PieceData,
    PieceKind,
    SquareStr,
  } from "../api/contract";
  import { game } from "../stores/gameStore.svelte";
  import { settingsStore } from "../stores/settingsStore.svelte";
  import { ALL_SQUARES, FILES, isLightSquare, squareXY } from "../util/squares";
  import Piece from "../pieces/Piece.svelte";
  import Promotion from "../modals/Promotion.svelte";

  interface TrackedPiece {
    id: number;
    color: Color;
    kind: PieceKind;
    square: SquareStr;
    fading?: boolean;
  }

  let nextId = 0;
  let pieces = $state<TrackedPiece[]>([]);
  let lastFen = "";
  let prevHistoryLen = 0;
  let dragging = $state<{ id: number; x: number; y: number } | null>(null);
  let boardEl: HTMLDivElement | undefined = $state();
  let dragStartSq: SquareStr | null = null;
  let dragMoved = false;
  let reconcileTimeout: ReturnType<typeof setTimeout> | null = null;

  const newId = () => ++nextId;

  function clearReconcileTimeout() {
    if (reconcileTimeout) {
      clearTimeout(reconcileTimeout);
      reconcileTimeout = null;
    }
  }

  function rebuildFromBoard(board: Map<SquareStr, PieceData>) {
    clearReconcileTimeout();
    const out: TrackedPiece[] = [];
    for (const [sq, p] of board) {
      out.push({ id: newId(), color: p.color, kind: p.kind, square: sq });
    }
    pieces = out;
  }

  function applyMove(move: Move, board: Map<SquareStr, PieceData>) {
    const moving = pieces.find((p) => p.square === move.from && !p.fading);
    const captured = pieces.find(
      (p) => p.square === move.to && p !== moving && !p.fading,
    );
    const next: TrackedPiece[] = [];
    if (captured) {
      next.push({ ...captured, fading: true });
      setTimeout(() => {
        pieces = pieces.filter((p) => p.id !== captured.id);
      }, 240);
    }
    for (const p of pieces) {
      if (p === captured) continue;
      if (p === moving) {
        next.push({
          ...p,
          square: move.to,
          kind: (move.promotion as PieceKind | null) ?? p.kind,
        });
      } else {
        next.push(p);
      }
    }
    if (move.is_en_passant) {
      const epSq: SquareStr = `${move.to[0]}${move.from[1]}`;
      const epPiece = next.find((p) => p.square === epSq && !p.fading);
      if (epPiece) {
        epPiece.fading = true;
        setTimeout(() => {
          pieces = pieces.filter((p) => p.id !== epPiece.id);
        }, 240);
      }
    }
    if (move.is_castle) {
      const rank = move.from[1];
      const kingside = move.to[0] === "g";
      const rookFrom: SquareStr = kingside ? `h${rank}` : `a${rank}`;
      const rookTo: SquareStr = kingside ? `f${rank}` : `d${rank}`;
      const rook = next.find(
        (p) => p.square === rookFrom && p.kind === "r" && !p.fading,
      );
      if (rook) rook.square = rookTo;
    }
    pieces = next;
    clearReconcileTimeout();
    reconcileTimeout = setTimeout(() => {
      reconcileTimeout = null;
      reconcile(board);
    }, 280);
  }

  function reconcile(board: Map<SquareStr, PieceData>) {
    const occupied = new Set<SquareStr>();
    const next: TrackedPiece[] = [];
    for (const p of pieces) {
      if (p.fading) {
        next.push(p);
        continue;
      }
      const target = board.get(p.square);
      if (
        target &&
        target.color === p.color &&
        target.kind === p.kind &&
        !occupied.has(p.square)
      ) {
        next.push(p);
        occupied.add(p.square);
      }
    }
    for (const [sq, p] of board) {
      if (!occupied.has(sq)) {
        next.push({ id: newId(), color: p.color, kind: p.kind, square: sq });
      }
    }
    pieces = next;
  }

  $effect(() => {
    const view = game.view;
    if (!view) return;
    const board = game.board;
    const fen = view.fen;
    if (fen === lastFen) return;
    const isForwardMove =
      game.scrubIndex == null &&
      view.history.length === prevHistoryLen + 1 &&
      view.last_move != null;
    if (isForwardMove && view.last_move) {
      applyMove(view.last_move, board);
    } else {
      rebuildFromBoard(board);
    }
    lastFen = fen;
    prevHistoryLen = view.history.length;
  });

  const settings = $derived(settingsStore.settings);
  const orientation = $derived(game.orientation);

  function handleSquarePointerDown(e: PointerEvent, sq: SquareStr) {
    if (game.inputLocked || !boardEl) return;
    const piece = pieces.find((p) => p.square === sq && !p.fading);
    const turnPiece =
      piece && game.live && piece.color === game.live.turn ? piece : null;

    if (game.selected && (game.live?.legal_moves[game.selected] ?? []).includes(sq)) {
      const from = game.selected;
      game.deselect();
      void game.tryMove(from, sq);
      return;
    }

    if (!turnPiece) {
      game.select(sq);
      return;
    }

    game.select(sq);
    dragStartSq = sq;
    dragMoved = false;
    const rect = boardEl.getBoundingClientRect();
    dragging = {
      id: turnPiece.id,
      x: ((e.clientX - rect.left) / rect.width) * 100,
      y: ((e.clientY - rect.top) / rect.height) * 100,
    };
    (e.target as Element).setPointerCapture?.(e.pointerId);
    e.preventDefault();
  }

  function pointerMove(e: PointerEvent) {
    if (!dragging || !boardEl) return;
    const rect = boardEl.getBoundingClientRect();
    const xPct = ((e.clientX - rect.left) / rect.width) * 100;
    const yPct = ((e.clientY - rect.top) / rect.height) * 100;
    if (
      Math.abs(xPct - dragging.x) > 0.6 ||
      Math.abs(yPct - dragging.y) > 0.6
    ) {
      dragMoved = true;
    }
    dragging = { ...dragging, x: xPct, y: yPct };
  }

  function pointerUp(e: PointerEvent) {
    if (!dragging || !boardEl) return;
    const rect = boardEl.getBoundingClientRect();
    const xPct = (e.clientX - rect.left) / rect.width;
    const yPct = (e.clientY - rect.top) / rect.height;
    const o = orientation;
    let target: SquareStr | null = null;
    if (xPct >= 0 && xPct <= 1 && yPct >= 0 && yPct <= 1) {
      const col = Math.floor(xPct * 8);
      const row = Math.floor(yPct * 8);
      const f = o === "w" ? col : 7 - col;
      const r = o === "w" ? 7 - row : row;
      target = `${FILES[f]}${r + 1}` as SquareStr;
    }
    const from = dragStartSq;
    dragging = null;
    dragStartSq = null;
    if (dragMoved && from && target && from !== target) {
      void game.tryMove(from, target);
    }
  }

  function pieceTransform(p: TrackedPiece) {
    if (dragging && dragging.id === p.id) {
      return `translate(${dragging.x - 6.25}%, ${dragging.y - 6.25}%) scale(1.08)`;
    }
    const { col, row } = squareXY(p.square, orientation);
    return `translate(${col * 100}%, ${row * 100}%)`;
  }

  function isLegalDest(sq: SquareStr): boolean {
    return game.legalForSelected.includes(sq);
  }

  function isCheckSquare(sq: SquareStr): boolean {
    if (!game.view?.in_check) return false;
    const piece = game.board.get(sq);
    return !!piece && piece.kind === "k" && piece.color === game.view.turn;
  }
</script>

<svelte:window onpointermove={pointerMove} onpointerup={pointerUp} />

<!-- SVG Definitions for Procedural Textures -->
<svg width="0" height="0" style="position: absolute; pointer-events: none;">
  <defs>
    <!-- Wood grain filter -->
    <filter id="wood-grain" x="0" y="0" width="100%" height="100%">
      <feTurbulence type="fractalNoise" baseFrequency="0.04 0.8" numOctaves="3" result="noise" />
      <feColorMatrix type="matrix" values="1 0 0 0 0  0 0.8 0 0 0  0 0.5 0 0 0  0 0 0 0.15 0" in="noise" result="coloredNoise" />
      <feBlend in="SourceGraphic" in2="coloredNoise" mode="multiply" />
    </filter>
    
    <!-- Slate noise filter -->
    <filter id="slate-noise" x="0" y="0" width="100%" height="100%">
      <feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="4" result="noise" />
      <feColorMatrix type="matrix" values="1 0 0 0 0  0 1 0 0 0  0 1 0 0 0  0 0 0 0.08 0" in="noise" result="coloredNoise" />
      <feBlend in="SourceGraphic" in2="coloredNoise" mode="multiply" />
    </filter>
  </defs>
</svg>

<div class="board-frame theme-{settings.board_theme.replace('_', '-')}" class:flipped={orientation === "b"}>
  <div class="board-outer">
    <div
      bind:this={boardEl}
      class="board"
      class:dragging={!!dragging}
      class:locked={game.inputLocked}
    >
      {#each ALL_SQUARES as sq (sq)}
        {@const xy = squareXY(sq, orientation)}
        {@const light = isLightSquare(sq)}
        {@const lastFromSq = settings.show_last_move && game.lastMove?.from === sq}
        {@const lastToSq = settings.show_last_move && game.lastMove?.to === sq}
        <button
          type="button"
          class="square"
          class:light
          class:dark={!light}
          class:selected={game.selected === sq}
          class:last-move={lastFromSq || lastToSq}
          class:check={isCheckSquare(sq)}
          style:transform="translate({xy.col * 100}%, {xy.row * 100}%)"
          onpointerdown={(e) => handleSquarePointerDown(e, sq)}
          aria-label={sq}
        >
          {#if settings.show_coordinates && xy.col === 0}
            <span class="coord coord-rank">{sq[1]}</span>
          {/if}
          {#if settings.show_coordinates && xy.row === 7}
            <span class="coord coord-file">{sq[0]}</span>
          {/if}
        </button>
      {/each}

      <!-- Pieces above squares -->
      {#each pieces as p (p.id)}
        <div
          class="piece-wrap"
          class:fading={p.fading}
          class:dragging={dragging?.id === p.id}
          style:transform={pieceTransform(p)}
        >
          <Piece kind={p.kind} color={p.color} set={settings.piece_set} />
        </div>
      {/each}

      <!-- Move hints above pieces (so capture rings stay visible) -->
      {#if settings.show_legal_moves && game.selected}
        {#each game.legalForSelected as sq (sq)}
          {@const xy = squareXY(sq, orientation)}
          <div
            class="hint-layer"
            style:transform="translate({xy.col * 100}%, {xy.row * 100}%)"
          >
            {#if game.board.get(sq)}
              <span class="hint-ring"></span>
            {:else}
              <span class="hint-dot"></span>
            {/if}
          </div>
        {/each}
      {/if}

      <!-- Promotion picker — positioned in board coordinates -->
      <Promotion />
    </div>
  </div>
</div>

<style>
  .board-frame {
    --board-bezel: clamp(8px, 1.4vw, 18px);
    width: min(72vh, 92vmin, 720px);
    align-self: center;
    justify-self: center;
    perspective: 1400px;
  }

  .board-outer {
    padding: var(--board-bezel);
    background:
      radial-gradient(ellipse at 30% 0%, rgba(255, 220, 170, 0.06), transparent 60%),
      linear-gradient(155deg, var(--c-walnut) 0%, var(--c-walnut-deep) 100%);
    border-radius: 14px;
    box-shadow: var(--shadow-board);
    position: relative;
    transform-style: preserve-3d;
    transition: transform 520ms var(--ease-out), background 300ms ease;
  }
  .theme-slate .board-outer {
    background:
      radial-gradient(ellipse at 30% 0%, rgba(255, 255, 255, 0.04), transparent 60%),
      linear-gradient(155deg, #4a525d 0%, #2a2f36 100%);
  }
  .theme-wood-realistic .board-outer {
    background:
      linear-gradient(135deg, rgba(255,255,255,0.1) 0%, transparent 40%),
      linear-gradient(155deg, #4a2f1a 0%, #2a180c 100%);
    box-shadow: 
      inset 0 2px 4px rgba(255,255,255,0.1),
      inset 0 -2px 4px rgba(0,0,0,0.4),
      var(--shadow-board);
  }
  .theme-slate-realistic .board-outer {
    background:
      linear-gradient(135deg, rgba(255,255,255,0.1) 0%, transparent 40%),
      linear-gradient(155deg, #3a4049 0%, #22262b 100%);
    box-shadow: 
      inset 0 2px 4px rgba(255,255,255,0.1),
      inset 0 -2px 4px rgba(0,0,0,0.4),
      var(--shadow-board);
  }
  .board-outer::after {
    content: "";
    position: absolute;
    inset: 0;
    border-radius: 14px;
    border: 1px solid rgba(255, 240, 210, 0.06);
    pointer-events: none;
  }

  .board {
    position: relative;
    width: 100%;
    aspect-ratio: 1;
    border-radius: 4px;
    overflow: hidden;
    box-shadow:
      inset 0 0 0 1px rgba(0, 0, 0, 0.3),
      inset 0 0 28px rgba(0, 0, 0, 0.18);
    background: var(--c-bg);
  }

  .square {
    position: absolute;
    top: 0;
    left: 0;
    width: 12.5%;
    height: 12.5%;
    margin: 0;
    padding: 0;
    border: none;
    background: transparent;
    cursor: pointer;
    overflow: hidden;
  }
  .square::before {
    content: "";
    position: absolute;
    inset: 0;
    background: var(--sq-fill, transparent);
    background-image: var(--sq-grain, none);
    filter: var(--sq-filter, none);
  }
  .square::after {
    content: "";
    position: absolute;
    inset: 0;
    pointer-events: none;
    transition: background 160ms ease;
  }

  .theme-wood .square.light {
    --sq-fill: var(--sq-light-wood);
    --sq-grain:
      radial-gradient(
        ellipse at 30% 20%,
        rgba(255, 255, 255, 0.18) 0,
        transparent 40%
      ),
      repeating-linear-gradient(
        92deg,
        rgba(110, 74, 42, 0.06) 0 1px,
        transparent 1px 6px
      );
  }
  .theme-wood .square.dark {
    --sq-fill: var(--sq-dark-wood);
    --sq-grain:
      radial-gradient(
        ellipse at 30% 20%,
        rgba(255, 240, 200, 0.08) 0,
        transparent 40%
      ),
      repeating-linear-gradient(
        88deg,
        rgba(0, 0, 0, 0.08) 0 1px,
        transparent 1px 7px
      );
  }
  .theme-slate .square.light {
    --sq-fill: var(--sq-light-slate);
    --sq-grain: linear-gradient(
      155deg,
      rgba(255, 255, 255, 0.18),
      rgba(0, 0, 0, 0.02)
    );
  }
  .theme-slate .square.dark {
    --sq-fill: var(--sq-dark-slate);
    --sq-grain: linear-gradient(
      155deg,
      rgba(255, 255, 255, 0.05),
      rgba(0, 0, 0, 0.16)
    );
  }

  .theme-wood-realistic .square.light {
    --sq-fill: var(--sq-light-wood);
    --sq-filter: url(#wood-grain);
  }
  .theme-wood-realistic .square.dark {
    --sq-fill: var(--sq-dark-wood);
    --sq-filter: url(#wood-grain);
  }
  
  .theme-slate-realistic .square.light {
    --sq-fill: var(--sq-light-slate);
    --sq-filter: url(#slate-noise);
  }
  .theme-slate-realistic .square.dark {
    --sq-fill: var(--sq-dark-slate);
    --sq-filter: url(#slate-noise);
  }

  .square.last-move::after {
    background: var(--hi-last);
    mix-blend-mode: multiply;
  }
  .theme-slate .square.last-move::after,
  .theme-slate-realistic .square.last-move::after {
    mix-blend-mode: normal;
    background: rgba(204, 162, 56, 0.32);
  }
  .square.selected::after {
    background: var(--hi-select);
    mix-blend-mode: multiply;
  }
  .theme-slate .square.selected::after,
  .theme-slate-realistic .square.selected::after {
    mix-blend-mode: normal;
    background: rgba(120, 153, 82, 0.42);
  }
  .square.check::after {
    background: radial-gradient(
      circle,
      rgba(194, 91, 79, 0.85) 0%,
      rgba(194, 91, 79, 0.0) 65%
    );
    animation: check-pulse 1.4s ease-in-out infinite;
  }
  @keyframes check-pulse {
    0%, 100% { opacity: 0.85; }
    50% { opacity: 0.5; }
  }

  .coord {
    position: absolute;
    font-family: var(--font-sans);
    font-size: 0.62em;
    font-weight: 600;
    letter-spacing: 0.04em;
    pointer-events: none;
    line-height: 1;
    opacity: 0.7;
    z-index: 2;
  }
  .coord-rank {
    top: 3px;
    left: 4px;
  }
  .coord-file {
    bottom: 3px;
    right: 5px;
  }
  .theme-wood .square.light .coord,
  .theme-wood-realistic .square.light .coord { color: var(--sq-dark-wood-2); }
  .theme-wood .square.dark .coord,
  .theme-wood-realistic .square.dark .coord { color: var(--sq-light-wood); }
  
  .theme-slate .square.light .coord,
  .theme-slate-realistic .square.light .coord { color: var(--sq-dark-slate-2); }
  .theme-slate .square.dark .coord,
  .theme-slate-realistic .square.dark .coord { color: var(--sq-light-slate); }

  .piece-wrap {
    position: absolute;
    top: 0;
    left: 0;
    width: 12.5%;
    height: 12.5%;
    pointer-events: none;
    will-change: transform, opacity;
    transition:
      transform 240ms cubic-bezier(0.22, 1, 0.36, 1),
      opacity 220ms ease;
    z-index: 5;
  }
  .piece-wrap.dragging {
    transition: none;
    z-index: 30;
    filter: drop-shadow(0 12px 22px rgba(0, 0, 0, 0.36));
  }
  .piece-wrap.fading {
    opacity: 0;
    transition:
      opacity 220ms ease,
      transform 240ms cubic-bezier(0.5, -0.4, 0.55, 1.4);
    pointer-events: none;
  }

  .hint-layer {
    position: absolute;
    top: 0;
    left: 0;
    width: 12.5%;
    height: 12.5%;
    pointer-events: none;
    z-index: 10;
    display: grid;
    place-items: center;
  }
  .hint-dot {
    width: 26%;
    height: 26%;
    border-radius: 50%;
    background: var(--hi-dot);
    box-shadow: 0 1px 1px rgba(0, 0, 0, 0.08);
  }
  .hint-ring {
    width: 92%;
    height: 92%;
    border-radius: 50%;
    border: 4px solid var(--hi-dot-cap);
    background: transparent;
  }

  .board.locked .square {
    cursor: default;
  }

  @media (prefers-reduced-motion: reduce) {
    .piece-wrap {
      transition: none;
    }
    .square.check::after {
      animation: none;
    }
  }
</style>
