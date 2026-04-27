<script lang="ts">
  interface Props {
    size?: number;
    showWordmark?: boolean;
    compact?: boolean;
  }

  const {
    size = 40,
    showWordmark = true,
    compact = false,
  }: Props = $props();
</script>

<div class="logo-wrap" class:compact>
  <div
    class="logo-icon"
    style:width={`${size}px`}
    style:height={`${size}px`}
    style:--logo-bg-top={compact ? "#4f3321" : "var(--c-walnut)"}
    style:--logo-bg-bottom={compact ? "#28170d" : "var(--c-walnut-deep)"}
    aria-hidden="true"
  >
    <svg viewBox="0 0 64 64" focusable="false">
      <rect x="0" y="0" width="64" height="64" rx="20" fill="transparent" />
      <text
        x="32"
        y="44"
        text-anchor="middle"
        font-family="var(--font-serif)"
        font-size="40"
        fill={compact ? "#f5e0b5" : "var(--c-accent-mid)"}
        font-weight="500"
      >♛</text>
    </svg>
  </div>
  {#if showWordmark}
    <span class="wordmark serif">Chess</span>
  {/if}
</div>

<style>
  .logo-wrap {
    display: inline-flex;
    align-items: center;
    gap: 10px;
  }

  .logo-icon {
    border-radius: 30%;
    overflow: hidden;
    box-shadow: var(--shadow-sm);
    position: relative;
    isolation: isolate;
    background: linear-gradient(180deg, var(--logo-bg-top), var(--logo-bg-bottom));
  }

  .logo-icon::before {
    content: "";
    position: absolute;
    inset: 0;
    border-radius: inherit;
    box-shadow:
      inset 0 0 0 1px rgba(0, 0, 0, 0.2),
      inset 0 1px 1px rgba(255, 255, 255, 0.18);
    pointer-events: none;
    z-index: 1;
  }

  .logo-icon svg {
    display: block;
    width: 100%;
    height: 100%;
  }

  .logo-icon rect {
    fill: transparent;
  }

  .wordmark {
    font-size: 20px;
    font-weight: 500;
    letter-spacing: -0.012em;
    color: var(--c-ink);
    line-height: 1;
  }

  .compact .wordmark {
    color: #fff8eb;
    text-shadow: 0 1px 8px rgba(0, 0, 0, 0.5);
  }
</style>
