<script lang="ts">
  import Modal from "../ui/Modal.svelte";
  import Button from "../ui/Button.svelte";
  import GameLogo from "../ui/GameLogo.svelte";

  interface Props {
    open: boolean;
    onclose: () => void;
  }
  const { open, onclose }: Props = $props();
</script>

<Modal {open} {onclose} title="About" width="380px">
  <div class="about">
    <GameLogo size={64} showWordmark={false} />

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
  .about :global(.logo-wrap) {
    margin-bottom: 14px;
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
