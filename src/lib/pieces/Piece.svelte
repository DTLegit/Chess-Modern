{#if shape}
  <svg
    class="piece-svg piece-{color} set-{set}"
    viewBox="0 0 100 100"
    aria-hidden="true"
    style:--piece-fill={fill}
    style:--piece-stroke={stroke}
    style:--piece-bg={bg}
    style:--piece-hi={highlight}
    style:--piece-eye={eye}
  >
    <!-- Soft drop shadow under the piece -->
    <ellipse
      cx="50"
      cy="92"
      rx="28"
      ry="3.5"
      fill="rgba(0,0,0,0.18)"
      class="piece-shadow"
    />
    <g
      class="piece-body"
      fill={fill}
      stroke={stroke}
      stroke-width="2"
      stroke-linejoin="round"
      stroke-linecap="round"
    >
      {@html shape}
    </g>
  </svg>
{/if}

<script lang="ts">
  import type { Color, PieceKind, PieceSet } from "../api/contract";
  import { CLASSIC } from "./classic";
  import { MODERN } from "./modern";

  interface Props {
    kind: PieceKind;
    color: Color;
    set?: PieceSet;
  }
  const { kind, color, set = "classic" }: Props = $props();

  const shapes = $derived(set === "classic" ? CLASSIC : MODERN);
  const shape = $derived(shapes[kind]);

  // Color tokens. White pieces use a warm cream fill with a deep walnut
  // outline; black pieces invert that for crisp contrast on either theme.
  const fill = $derived(color === "w" ? "#f7eedb" : "#1f1813");
  const stroke = $derived(color === "w" ? "#3a2515" : "#0c0805");
  const bg = $derived(color === "w" ? "#f7eedb" : "#1f1813");
  const highlight = $derived(
    color === "w" ? "rgba(255, 255, 255, 0.42)" : "rgba(220, 195, 145, 0.22)",
  );
  const eye = $derived(color === "w" ? "#3a2515" : "#d6b06b");
</script>

<style>
  .piece-svg {
    width: 100%;
    height: 100%;
    display: block;
    pointer-events: none;
    overflow: visible;
  }
  .piece-shadow {
    transform-origin: center 92%;
    transform: scaleY(0.7);
    transition: opacity 180ms ease;
  }
  .piece-body :global(.hi) {
    fill: var(--piece-hi);
    stroke: none;
    pointer-events: none;
    mix-blend-mode: screen;
  }
  .piece-svg.piece-b :global(.hi) {
    mix-blend-mode: normal;
  }
  /* Subtle inner-shadow simulation via a second outline */
  .piece-svg.piece-w .piece-body {
    filter: drop-shadow(0 1px 0 rgba(255, 255, 255, 0.6));
  }
  .piece-svg.piece-b .piece-body {
    filter: drop-shadow(0 1px 0 rgba(255, 255, 255, 0.06));
  }
</style>
