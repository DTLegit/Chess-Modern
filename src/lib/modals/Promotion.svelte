<script lang="ts">
  import type { Color, PieceKind, Promotion as Promo } from "../api/contract";
  import { game } from "../stores/gameStore.svelte";
  import { settingsStore } from "../stores/settingsStore.svelte";
  import { squareXY } from "../util/squares";
  import Piece from "../pieces/Piece.svelte";

  const pending = $derived(game.pendingPromotion);
  const orientation = $derived(game.orientation);

  // Compute on-board placement (% of board) so the picker drops over the
  // promotion square. Stack 4 pieces vertically extending toward the player.
  const PIECES: { kind: PieceKind; promo: Promo }[] = [
    { kind: "q", promo: "q" },
    { kind: "n", promo: "n" },
    { kind: "r", promo: "r" },
    { kind: "b", promo: "b" },
  ];

  const placement = $derived.by(() => {
    if (!pending) return null;
    const { col, row } = squareXY(pending.to, orientation);
    // direction: if the promotion square is at the top of board (row 0),
    // stack downwards; otherwise stack upwards.
    const direction = row === 0 ? 1 : -1;
    return { col, row, direction };
  });

  function pick(p: Promo) {
    void game.commitPromotion(p);
  }

  function cancel() {
    game.cancelPromotion();
  }
</script>

{#if pending && placement}
  <div
    class="promo-overlay"
    role="presentation"
    onmousedown={(e) => {
      if (e.target === e.currentTarget) cancel();
    }}
  >
    <div
      class="picker"
      style:left="{placement.col * 12.5}%"
      style:top="{placement.row * 12.5 + (placement.direction === 1 ? 0 : -37.5)}%"
    >
      {#each PIECES as p, i}
        <button
          type="button"
          class="choice"
          style:order={placement.direction === 1 ? i : 3 - i}
          onclick={() => pick(p.promo)}
          aria-label={p.kind}
        >
          <Piece
            kind={p.kind}
            color={pending.color as Color}
            set={settingsStore.settings.piece_set}
          />
        </button>
      {/each}
    </div>
  </div>
{/if}

<style>
  .promo-overlay {
    position: absolute;
    inset: 0;
    z-index: 50;
    background: rgba(20, 14, 8, 0.18);
    backdrop-filter: blur(1px);
    /* Anchor coords relative to the inner board */
    pointer-events: auto;
  }
  .picker {
    position: absolute;
    width: 12.5%;
    display: flex;
    flex-direction: column;
    background: var(--c-bg-elev);
    border: 1px solid var(--hairline);
    border-radius: 8px;
    box-shadow: var(--shadow-lg);
    overflow: hidden;
    animation: picker-in 160ms var(--ease-out);
  }
  .choice {
    aspect-ratio: 1;
    width: 100%;
    background: var(--c-bg-elev);
    transition: background-color 120ms ease, transform 120ms ease;
    padding: 4px;
    border-bottom: 1px solid var(--hairline);
  }
  .choice:last-child { border-bottom: none; }
  .choice:hover {
    background: var(--c-gold-soft);
  }
  @keyframes picker-in {
    from { opacity: 0; transform: scale(0.94); }
    to   { opacity: 1; transform: scale(1); }
  }
</style>
