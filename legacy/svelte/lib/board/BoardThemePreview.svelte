<script lang="ts">
  import type { BoardTheme } from "../api/contract";
  import { ALL_SQUARES, isLightSquare } from "../util/squares";

  interface Props {
    /** Board surface theme (matches main board CSS class suffix). */
    theme: BoardTheme;
  }
  const { theme }: Props = $props();

  const themeClass = $derived(theme.replace(/_/g, "-"));
</script>

<!-- Filters use unique IDs so they do not clash with the main board. -->
<svg width="0" height="0" class="defs" aria-hidden="true">
  <defs>
    <filter id="wood-grain-preview" x="0" y="0" width="100%" height="100%">
      <feTurbulence type="fractalNoise" baseFrequency="0.04 0.8" numOctaves="3" result="noise" />
      <feColorMatrix
        type="matrix"
        values="1 0 0 0 0  0 0.8 0 0 0  0 0.5 0 0 0  0 0 0 0.15 0"
        in="noise"
        result="coloredNoise"
      />
      <feBlend in="SourceGraphic" in2="coloredNoise" mode="multiply" />
    </filter>
    <filter id="slate-noise-preview" x="0" y="0" width="100%" height="100%">
      <feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="4" result="noise" />
      <feColorMatrix
        type="matrix"
        values="1 0 0 0 0  0 1 0 0 0  0 1 0 0 0  0 0 0 0.08 0"
        in="noise"
        result="coloredNoise"
      />
      <feBlend in="SourceGraphic" in2="coloredNoise" mode="multiply" />
    </filter>
  </defs>
</svg>

<div class="preview-frame theme-{themeClass}">
  <div class="preview-bezel">
    <div class="preview-grid">
      {#each ALL_SQUARES as sq (sq)}
        {@const light = isLightSquare(sq)}
        <div class="cell" class:light class:dark={!light}></div>
      {/each}
    </div>
  </div>
</div>

<style>
  .preview-frame {
    width: 100%;
    max-width: min(100%, 320px);
    margin-inline: auto;
  }
  .preview-bezel {
    padding: clamp(6px, 1.2vw, 12px);
    background:
      radial-gradient(ellipse at 30% 0%, rgba(255, 220, 170, 0.06), transparent 60%),
      linear-gradient(155deg, var(--c-walnut) 0%, var(--c-walnut-deep) 100%);
    border-radius: 12px;
    box-shadow: var(--shadow-md);
  }
  .theme-slate .preview-bezel {
    background:
      radial-gradient(ellipse at 30% 0%, rgba(255, 255, 255, 0.04), transparent 60%),
      linear-gradient(155deg, #4a525d 0%, #2a2f36 100%);
  }
  .theme-marble .preview-bezel {
    background:
      radial-gradient(ellipse at 30% 0%, rgba(255, 255, 255, 0.14), transparent 60%),
      linear-gradient(155deg, #919cac 0%, #5e6878 100%);
  }
  .theme-emerald .preview-bezel {
    background:
      radial-gradient(ellipse at 30% 0%, rgba(255, 255, 255, 0.08), transparent 60%),
      linear-gradient(155deg, #245343 0%, #13362b 100%);
  }
  .theme-obsidian .preview-bezel {
    background:
      radial-gradient(ellipse at 30% 0%, rgba(255, 255, 255, 0.05), transparent 60%),
      linear-gradient(155deg, #2e3542 0%, #131820 100%);
  }
  .theme-sandstone .preview-bezel {
    background:
      radial-gradient(ellipse at 30% 0%, rgba(255, 250, 235, 0.2), transparent 60%),
      linear-gradient(155deg, #b4885a 0%, #7a5738 100%);
  }
  .theme-midnight .preview-bezel {
    background:
      radial-gradient(ellipse at 30% 0%, rgba(124, 151, 210, 0.18), transparent 60%),
      linear-gradient(155deg, #1c2d50 0%, #0b1323 100%);
  }
  .theme-wood-realistic .preview-bezel {
    background:
      linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, transparent 40%),
      linear-gradient(155deg, #4a2f1a 0%, #2a180c 100%);
    box-shadow:
      inset 0 1px 2px rgba(255, 255, 255, 0.1),
      inset 0 -1px 2px rgba(0, 0, 0, 0.35),
      var(--shadow-md);
  }
  .theme-slate-realistic .preview-bezel {
    background:
      linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, transparent 40%),
      linear-gradient(155deg, #3a4049 0%, #22262b 100%);
    box-shadow:
      inset 0 1px 2px rgba(255, 255, 255, 0.1),
      inset 0 -1px 2px rgba(0, 0, 0, 0.35),
      var(--shadow-md);
  }

  .preview-grid {
    position: relative;
    width: 100%;
    aspect-ratio: 1;
    border-radius: 3px;
    overflow: hidden;
    display: grid;
    grid-template-columns: repeat(8, 1fr);
    grid-template-rows: repeat(8, 1fr);
    box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.25);
  }

  .cell {
    position: relative;
    overflow: hidden;
  }
  .cell::before {
    content: "";
    position: absolute;
    inset: 0;
    background: var(--sq-fill, transparent);
    background-image: var(--sq-grain, none);
    filter: var(--sq-filter, none);
  }

  .theme-wood .cell.light {
    --sq-fill: var(--sq-light-wood);
    --sq-grain:
      radial-gradient(ellipse at 30% 20%, rgba(255, 255, 255, 0.18) 0, transparent 40%),
      repeating-linear-gradient(92deg, rgba(110, 74, 42, 0.06) 0 1px, transparent 1px 6px);
  }
  .theme-wood .cell.dark {
    --sq-fill: var(--sq-dark-wood);
    --sq-grain:
      radial-gradient(ellipse at 30% 20%, rgba(255, 240, 200, 0.08) 0, transparent 40%),
      repeating-linear-gradient(88deg, rgba(0, 0, 0, 0.08) 0 1px, transparent 1px 7px);
  }
  .theme-slate .cell.light {
    --sq-fill: var(--sq-light-slate);
    --sq-grain: linear-gradient(155deg, rgba(255, 255, 255, 0.18), rgba(0, 0, 0, 0.02));
  }
  .theme-slate .cell.dark {
    --sq-fill: var(--sq-dark-slate);
    --sq-grain: linear-gradient(155deg, rgba(255, 255, 255, 0.05), rgba(0, 0, 0, 0.16));
  }
  .theme-marble .cell.light {
    --sq-fill: #eceff3;
    --sq-grain:
      radial-gradient(circle at 18% 25%, rgba(255, 255, 255, 0.5), transparent 35%),
      repeating-linear-gradient(130deg, rgba(120, 130, 145, 0.09) 0 2px, transparent 2px 8px);
  }
  .theme-marble .cell.dark {
    --sq-fill: #8b939f;
    --sq-grain:
      radial-gradient(circle at 22% 20%, rgba(255, 255, 255, 0.12), transparent 45%),
      repeating-linear-gradient(130deg, rgba(25, 30, 40, 0.16) 0 2px, transparent 2px 9px);
  }
  .theme-emerald .cell.light {
    --sq-fill: #d8efe3;
    --sq-grain:
      linear-gradient(145deg, rgba(255, 255, 255, 0.22), rgba(0, 0, 0, 0.03)),
      repeating-linear-gradient(90deg, rgba(45, 111, 86, 0.08) 0 1px, transparent 1px 6px);
  }
  .theme-emerald .cell.dark {
    --sq-fill: #2f6f56;
    --sq-grain:
      linear-gradient(155deg, rgba(255, 255, 255, 0.06), rgba(0, 0, 0, 0.2)),
      repeating-linear-gradient(90deg, rgba(0, 0, 0, 0.1) 0 1px, transparent 1px 7px);
  }
  .theme-obsidian .cell.light {
    --sq-fill: #7b8797;
    --sq-grain: linear-gradient(155deg, rgba(255, 255, 255, 0.1), rgba(0, 0, 0, 0.08));
  }
  .theme-obsidian .cell.dark {
    --sq-fill: #151b26;
    --sq-grain: linear-gradient(155deg, rgba(255, 255, 255, 0.04), rgba(0, 0, 0, 0.28));
  }
  .theme-sandstone .cell.light {
    --sq-fill: #efd8b8;
    --sq-grain:
      radial-gradient(circle at 20% 22%, rgba(255, 250, 240, 0.24), transparent 42%),
      repeating-linear-gradient(95deg, rgba(125, 90, 45, 0.08) 0 1px, transparent 1px 6px);
  }
  .theme-sandstone .cell.dark {
    --sq-fill: #b58959;
    --sq-grain:
      radial-gradient(circle at 20% 22%, rgba(255, 238, 205, 0.1), transparent 42%),
      repeating-linear-gradient(95deg, rgba(75, 45, 20, 0.14) 0 1px, transparent 1px 7px);
  }
  .theme-midnight .cell.light {
    --sq-fill: #4b5f86;
    --sq-grain: linear-gradient(150deg, rgba(185, 208, 255, 0.2), rgba(7, 14, 24, 0.05));
  }
  .theme-midnight .cell.dark {
    --sq-fill: #101a30;
    --sq-grain: linear-gradient(150deg, rgba(169, 201, 255, 0.07), rgba(0, 0, 0, 0.34));
  }
  .theme-wood-realistic .cell.light {
    --sq-fill: var(--sq-light-wood);
    --sq-filter: url(#wood-grain-preview);
  }
  .theme-wood-realistic .cell.dark {
    --sq-fill: var(--sq-dark-wood);
    --sq-filter: url(#wood-grain-preview);
  }
  .theme-slate-realistic .cell.light {
    --sq-fill: var(--sq-light-slate);
    --sq-filter: url(#slate-noise-preview);
  }
  .theme-slate-realistic .cell.dark {
    --sq-fill: var(--sq-dark-slate);
    --sq-filter: url(#slate-noise-preview);
  }
</style>
