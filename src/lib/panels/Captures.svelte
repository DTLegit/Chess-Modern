<script lang="ts">
  import type { Color, PieceKind } from "../api/contract";
  import { game } from "../stores/gameStore.svelte";
  import { settingsStore } from "../stores/settingsStore.svelte";
  import Piece from "../pieces/Piece.svelte";

  interface Props {
    /** "w" panel = white captures = pieces white has captured (so black). */
    side: Color;
  }
  const { side }: Props = $props();

  const moves = $derived(game.live?.history ?? []);

  /** All pieces captured BY this side (i.e. of the opposite color). */
  const captured = $derived.by<PieceKind[]>(() => {
    const opp: Color = side === "w" ? "b" : "w";
    const out: PieceKind[] = [];
    for (const m of moves) {
      if (m.captured && m.captured.color === opp) {
        out.push(m.captured.kind);
      }
    }
    // Sort: q, r, b, n, p (heaviest first)
    const order: Record<PieceKind, number> = {
      q: 0, r: 1, b: 2, n: 3, p: 4, k: 5,
    };
    out.sort((a, b) => order[a] - order[b]);
    return out;
  });

  const VALUES: Record<PieceKind, number> = {
    p: 1, n: 3, b: 3, r: 5, q: 9, k: 0,
  };

  const myValue = $derived(
    captured.reduce((s, k) => s + VALUES[k], 0),
  );
  const oppValue = $derived.by(() => {
    const myColor: Color = side; // me = side
    const opp: Color = side === "w" ? "b" : "w";
    let v = 0;
    for (const m of moves) {
      if (m.captured && m.captured.color === myColor) v += VALUES[m.captured.kind];
    }
    return v;
  });
  const delta = $derived(myValue - oppValue);

  const set = $derived(settingsStore.settings.piece_set);
  const oppColor = $derived<Color>(side === "w" ? "b" : "w");
</script>

<div class="captures" data-side={side}>
  <div class="row">
    {#each captured as k, i (i + "-" + k)}
      <span class="cap"><Piece kind={k} color={oppColor} {set} /></span>
    {/each}
    {#if delta > 0}
      <span class="delta">+{delta}</span>
    {/if}
  </div>
</div>

<style>
  .captures {
    min-height: 26px;
    padding: 4px 8px;
  }
  .row {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 1px;
    min-height: 22px;
  }
  .cap {
    width: 22px;
    height: 22px;
    display: inline-block;
    margin-left: -8px;
    filter: drop-shadow(0 1px 1px rgba(0, 0, 0, 0.08));
  }
  .cap:first-child {
    margin-left: 0;
  }
  .delta {
    margin-left: 8px;
    font-size: 11px;
    font-weight: 600;
    color: var(--c-gold);
    letter-spacing: 0.04em;
    font-variant-numeric: tabular-nums;
  }
</style>
