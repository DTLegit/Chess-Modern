<script lang="ts">
  import type { Snippet } from "svelte";

  interface Props {
    open: boolean;
    title?: string;
    width?: string;
    onclose?: () => void;
    /** When false, clicking the backdrop does NOT close. */
    closeOnBackdrop?: boolean;
    children: Snippet;
    footer?: Snippet;
  }

  const {
    open,
    title,
    width = "440px",
    onclose,
    closeOnBackdrop = true,
    children,
    footer,
  }: Props = $props();

  function handleBackdropDown(e: MouseEvent) {
    if (!closeOnBackdrop) return;
    if (e.target === e.currentTarget) onclose?.();
  }

  $effect(() => {
    if (!open) return;
    function key(e: KeyboardEvent) {
      if (e.key === "Escape") {
        e.preventDefault();
        onclose?.();
      }
    }
    window.addEventListener("keydown", key);
    return () => window.removeEventListener("keydown", key);
  });
</script>

{#if open}
  <div
    class="backdrop"
    role="presentation"
    onmousedown={handleBackdropDown}
  >
    <div
      class="modal"
      role="dialog"
      aria-modal="true"
      aria-label={title ?? "Dialog"}
      style:max-width={width}
    >
      {#if title}
        <header class="modal-head">
          <h2 class="modal-title serif">{title}</h2>
          {#if onclose}
            <button
              class="close"
              type="button"
              onclick={onclose}
              aria-label="Close"
            >×</button>
          {/if}
        </header>
      {/if}
      <div class="modal-body">
        {@render children()}
      </div>
      {#if footer}
        <footer class="modal-foot">
          {@render footer()}
        </footer>
      {/if}
    </div>
  </div>
{/if}

<style>
  .backdrop {
    position: fixed;
    inset: 0;
    background: rgba(20, 14, 8, 0.42);
    backdrop-filter: blur(2px);
    display: grid;
    place-items: center;
    z-index: 220;
    padding: 24px;
    animation: fade-in 180ms var(--ease-out);
  }
  .modal {
    width: 100%;
    background: var(--c-bg-elev);
    border-radius: 14px;
    box-shadow: var(--shadow-lg);
    border: 1px solid var(--hairline);
    overflow: hidden;
    transform-origin: center;
    animation: pop-in 180ms var(--ease-out);
    display: flex;
    flex-direction: column;
    max-height: 88vh;
  }
  .modal-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 18px 22px 12px;
    border-bottom: 1px solid var(--hairline);
  }
  .modal-title {
    margin: 0;
    font-size: 22px;
    font-weight: 500;
    color: var(--c-ink);
    letter-spacing: -0.012em;
  }
  .close {
    width: 28px;
    height: 28px;
    border-radius: 8px;
    color: var(--c-ink-mute);
    font-size: 22px;
    line-height: 1;
    transition: all 120ms ease;
  }
  .close:hover {
    background: color-mix(in oklab, var(--c-accent-mid) 14%, transparent);
    color: var(--c-ink);
  }
  .modal-body {
    padding: 18px 22px;
    overflow-y: auto;
  }
  .modal-foot {
    padding: 14px 22px;
    border-top: 1px solid var(--hairline);
    display: flex;
    gap: 8px;
    justify-content: flex-end;
    background: var(--c-bg-card);
  }
  @keyframes fade-in {
    from { opacity: 0; }
    to   { opacity: 1; }
  }
  @keyframes pop-in {
    from { opacity: 0; transform: translateY(6px) scale(0.98); }
    to   { opacity: 1; transform: translateY(0) scale(1); }
  }
  @media (prefers-reduced-motion: reduce) {
    .backdrop, .modal { animation: none; }
  }
</style>
