<script lang="ts">
  import { game } from "../stores/gameStore.svelte";

  const moves = $derived(game.live?.history ?? []);
  /** Pair moves into rows: [white, black?] per move number. */
  const rows = $derived.by(() => {
    const out: { number: number; white?: string; black?: string }[] = [];
    for (let i = 0; i < moves.length; i++) {
      const idx = i >> 1;
      const isWhite = i % 2 === 0;
      if (isWhite) {
        out.push({ number: idx + 1, white: moves[i].san });
      } else {
        out[out.length - 1].black = moves[i].san;
      }
    }
    return out;
  });

  const activePly = $derived(
    game.scrubIndex == null
      ? moves.length - 1
      : game.scrubIndex - 1, // snapshot 0 = no moves yet
  );

  function isActive(ply: number) {
    return ply === activePly;
  }

  function scrubToPly(ply: number) {
    // snapshots[0] = start, [n] = after nth move; ply -1 = start.
    game.scrubTo(ply + 1);
  }

  let scroller: HTMLDivElement | undefined = $state();
  $effect(() => {
    if (!scroller) return;
    // Keep latest visible
    if (game.scrubIndex == null) {
      scroller.scrollTop = scroller.scrollHeight;
    }
    void rows.length; // depend on rows
  });
</script>

<section class="panel">
  <header class="panel-head">
    <h2 class="panel-title">Moves</h2>
    <div class="scrub">
      <button
        class="scrub-btn"
        title="Start"
        onclick={() => game.scrubTo(0)}
        aria-label="Jump to start"
      ><span aria-hidden="true">⏮</span></button>
      <button
        class="scrub-btn"
        title="Previous"
        onclick={() => game.scrubStep(-1)}
        aria-label="Previous move"
      ><span aria-hidden="true">◀</span></button>
      <button
        class="scrub-btn"
        title="Next"
        onclick={() => game.scrubStep(1)}
        aria-label="Next move"
      ><span aria-hidden="true">▶</span></button>
      <button
        class="scrub-btn"
        title="Live"
        onclick={() => game.scrubLive()}
        aria-label="Jump to live"
      ><span aria-hidden="true">⏭</span></button>
    </div>
  </header>

  <div class="moves" bind:this={scroller}>
    {#if rows.length === 0}
      <p class="empty">No moves yet. The game begins with white.</p>
    {:else}
      <ol class="move-list tabular">
        {#each rows as row, ri}
          <li class="row">
            <span class="num">{row.number}.</span>
            <button
              class="ply"
              class:active={isActive(ri * 2)}
              disabled={!row.white}
              onclick={() => scrubToPly(ri * 2)}
            >
              {row.white ?? ""}
            </button>
            <button
              class="ply"
              class:active={isActive(ri * 2 + 1)}
              disabled={!row.black}
              onclick={() => row.black && scrubToPly(ri * 2 + 1)}
            >
              {row.black ?? "…"}
            </button>
          </li>
        {/each}
      </ol>
    {/if}
  </div>
</section>

<style>
  .panel {
    display: flex;
    flex-direction: column;
    background: var(--c-bg-card);
    border: 1px solid var(--hairline);
    border-radius: 12px;
    box-shadow: var(--shadow-sm);
    overflow: hidden;
    min-height: 0;
  }
  .panel-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 10px 14px;
    border-bottom: 1px solid var(--hairline);
    background: linear-gradient(180deg, var(--c-bg-elev), var(--c-bg-card));
  }
  .panel-title {
    margin: 0;
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--c-ink-mute);
  }
  .scrub {
    display: flex;
    gap: 2px;
  }
  .scrub-btn {
    width: 24px;
    height: 24px;
    display: grid;
    place-items: center;
    color: var(--c-ink-soft);
    border-radius: 6px;
    font-size: 11px;
    transition: all 120ms ease;
  }
  .scrub-btn:hover {
    background: color-mix(in oklab, var(--c-accent-mid) 12%, transparent);
    color: var(--c-ink);
  }
  .scrub-btn:active {
    transform: translateY(1px);
  }

  .moves {
    flex: 1;
    overflow-y: auto;
    padding: 6px 0;
  }
  .empty {
    padding: 14px;
    color: var(--c-ink-mute);
    font-size: 13px;
    font-style: italic;
  }
  .move-list {
    list-style: none;
    margin: 0;
    padding: 0;
  }
  .row {
    display: grid;
    grid-template-columns: 36px 1fr 1fr;
    align-items: stretch;
    border-bottom: 1px solid color-mix(in oklab, var(--c-accent-mid) 8%, var(--hairline));
  }
  .row:nth-child(even) {
    background: color-mix(in oklab, var(--c-accent-mid) 5%, transparent);
  }
  .num {
    display: grid;
    place-items: center;
    color: var(--c-ink-faint);
    font-size: 11px;
    font-weight: 600;
  }
  .ply {
    text-align: left;
    padding: 6px 10px;
    color: var(--c-ink);
    font-family: var(--font-sans);
    font-size: 13px;
    font-weight: 500;
    border-radius: 4px;
    transition: background-color 100ms ease;
  }
  .ply:hover:not(:disabled) {
    background: color-mix(in oklab, var(--c-accent-mid) 14%, transparent);
  }
  .ply.active {
    background: linear-gradient(180deg, var(--c-accent-mid) 0%, var(--c-accent) 100%);
    color: var(--c-accent-ink);
    box-shadow: inset 0 -2px 0 rgba(0, 0, 0, 0.18);
  }
  .ply:disabled {
    cursor: default;
    color: var(--c-ink-faint);
  }
</style>
