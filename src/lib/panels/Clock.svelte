<script lang="ts">
  import type { Color } from "../api/contract";
  import { game } from "../stores/gameStore.svelte";

  interface Props {
    side: Color;
    label?: string;
  }
  const { side, label }: Props = $props();

  const clock = $derived(game.live?.clock ?? null);
  const ms = $derived<number>(
    clock ? (side === "w" ? clock.white_ms : clock.black_ms) : 0,
  );
  const isActive = $derived(clock?.active === side && !clock?.paused);
  const isLow = $derived(ms < 30_000);

  function fmt(ms: number): string {
    if (ms < 0) ms = 0;
    const totalSec = Math.floor(ms / 1000);
    const m = Math.floor(totalSec / 60);
    const s = totalSec % 60;
    if (m >= 100) return `${m}:${String(s).padStart(2, "0")}`;
    if (m >= 10) return `${m}:${String(s).padStart(2, "0")}`;
    if (m >= 1) {
      return `${m}:${String(s).padStart(2, "0")}`;
    }
    // Under a minute: show with tenths
    const tenths = Math.floor((ms % 1000) / 100);
    return `${s}.${tenths}`;
  }

  const display = $derived(fmt(ms));
</script>

{#if clock}
  <div
    class="clock"
    class:active={isActive}
    class:low={isLow}
    class:white={side === "w"}
    class:black={side === "b"}
  >
    {#if label}<span class="label">{label}</span>{/if}
    <span class="time tabular">{display}</span>
  </div>
{/if}

<style>
  .clock {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    padding: 12px 16px;
    background: var(--c-bg-card);
    border: 1px solid var(--hairline);
    border-radius: 10px;
    transition: all 200ms var(--ease-out);
  }
  .label {
    font-size: 10px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.16em;
    color: var(--c-ink-mute);
  }
  .time {
    font-size: 28px;
    font-weight: 500;
    font-variant-numeric: tabular-nums;
    color: var(--c-ink);
    line-height: 1;
    letter-spacing: -0.01em;
  }
  .clock.active {
    background: linear-gradient(180deg, #fffaef, var(--c-bg-elev));
    border-color: var(--c-gold-soft);
    box-shadow:
      0 0 0 1px var(--c-gold-soft),
      0 0 24px rgba(194, 147, 59, 0.18);
  }
  .clock.active .time {
    color: var(--c-accent-mid);
  }
  .clock.low .time {
    color: var(--c-red-soft);
  }
  .clock.active.low {
    border-color: var(--c-red-soft);
    box-shadow:
      0 0 0 1px var(--c-red-soft),
      0 0 24px rgba(194, 91, 79, 0.22);
  }
</style>
