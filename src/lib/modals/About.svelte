<script lang="ts">
  import Modal from "../ui/Modal.svelte";
  import Button from "../ui/Button.svelte";

  interface Props {
    open: boolean;
    onclose: () => void;
  }
  const { open, onclose }: Props = $props();
</script>

<Modal {open} {onclose} title="About" width="380px">
  <div class="about">
    <div class="logo">
      <svg viewBox="0 0 64 64" aria-hidden="true">
        <defs>
          <linearGradient id="lg" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="#c2933b" />
            <stop offset="100%" stop-color="#7a5018" />
          </linearGradient>
        </defs>
        <rect x="2" y="2" width="60" height="60" rx="14" fill="url(#lg)" />
        <text
          x="32"
          y="44"
          text-anchor="middle"
          font-family="New York, Iowan Old Style, Georgia, serif"
          font-size="40"
          fill="#fffaef"
          font-weight="500"
        >♚</text>
      </svg>
    </div>

    <h2 class="serif name">Chess</h2>
    <p class="version">version 0.1.0 — early preview</p>
    <p class="desc">
      A small, hand-crafted chess application built with care.
      Two boards, two piece sets, no telemetry, no clutter.
    </p>
  </div>

  {#snippet footer()}
    <Button variant="primary" onclick={onclose}>Close</Button>
  {/snippet}
</Modal>

<style>
  .about {
    text-align: center;
    padding: 6px 0;
  }
  .logo {
    width: 64px;
    height: 64px;
    margin: 0 auto 14px;
    box-shadow: var(--shadow-md);
    border-radius: 14px;
    overflow: hidden;
  }
  .name {
    margin: 0;
    font-size: 26px;
    font-weight: 500;
    color: var(--c-ink);
    letter-spacing: -0.012em;
  }
  .version {
    margin: 4px 0 16px;
    font-size: 12px;
    color: var(--c-ink-mute);
  }
  .desc {
    margin: 0;
    font-size: 13px;
    color: var(--c-ink-soft);
    line-height: 1.55;
  }
</style>
