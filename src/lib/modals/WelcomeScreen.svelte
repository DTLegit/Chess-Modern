<script lang="ts">
  import GameLogo from "../ui/GameLogo.svelte";

  interface Props {
    open: boolean;
    onopennewgame: () => void;
    onopensettings: () => void;
  }
  const { open, onopennewgame, onopensettings }: Props = $props();
</script>

{#if open}
  <div class="welcome" role="dialog" aria-modal="true" aria-labelledby="welcome-title">
    <div class="backdrop board-ghost" aria-hidden="true"></div>
    <div class="backdrop grid-glow" aria-hidden="true"></div>
    <div class="backdrop noise" aria-hidden="true"></div>

    <main class="content">
      <header class="hero">
        <GameLogo size={56} compact={true} />
        <p class="subtitle">Main Menu</p>
      </header>

      <section class="menu-panel" aria-labelledby="welcome-title">
        <h1 id="welcome-title" class="panel-title">Chess</h1>
        <div class="actions">
          <button type="button" class="action primary" onclick={onopennewgame}>
            Start game
          </button>
          <button type="button" class="action" onclick={onopensettings}>Options</button>
        </div>
        <p class="hint">
          Configure mode, AI difficulty, board appearance, and game rules in the setup screen.
        </p>
      </section>
    </main>
  </div>
{/if}

<style>
  .welcome {
    position: fixed;
    inset: 0;
    z-index: 140;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: clamp(16px, 4vw, 40px);
    color: var(--c-ink);
    background:
      radial-gradient(circle at 50% 110%, rgba(13, 16, 21, 0.92), rgba(9, 10, 13, 0.96)),
      linear-gradient(145deg, #0d1218, #080b10);
    overflow: hidden;
  }

  .backdrop {
    position: absolute;
    inset: 0;
    pointer-events: none;
  }

  .board-ghost {
    background:
      radial-gradient(circle at 50% 48%, rgba(255, 255, 255, 0.07), transparent 52%),
      linear-gradient(35deg, rgba(255, 255, 255, 0.02), transparent 38% 62%, rgba(255, 255, 255, 0.02));
    filter: blur(1px);
  }

  .grid-glow {
    background-image:
      linear-gradient(transparent 95%, rgba(153, 200, 255, 0.07) 100%),
      linear-gradient(90deg, transparent 95%, rgba(153, 200, 255, 0.06) 100%);
    background-size: 24px 24px, 24px 24px;
    opacity: 0.18;
    mask-image: radial-gradient(ellipse 70% 55% at 50% 55%, black, transparent 80%);
  }

  .noise {
    background-image:
      radial-gradient(1px 1px at 20% 25%, rgba(255, 255, 255, 0.22), transparent),
      radial-gradient(1px 1px at 70% 18%, rgba(255, 255, 255, 0.2), transparent),
      radial-gradient(1px 1px at 35% 78%, rgba(255, 255, 255, 0.16), transparent),
      radial-gradient(1px 1px at 85% 63%, rgba(255, 255, 255, 0.18), transparent);
    opacity: 0.18;
  }

  .content {
    position: relative;
    z-index: 1;
    width: min(430px, 100%);
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
  }

  .hero {
    display: grid;
    place-items: center;
    gap: 6px;
  }
  .subtitle {
    margin: 0;
    font-family: var(--font-sans);
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: rgba(210, 228, 255, 0.66);
  }

  .menu-panel {
    width: 100%;
    max-width: 340px;
    border-radius: 12px;
    border: 1px solid rgba(193, 221, 255, 0.3);
    background:
      linear-gradient(180deg, rgba(20, 32, 46, 0.86), rgba(13, 21, 30, 0.88)),
      linear-gradient(130deg, rgba(255, 255, 255, 0.08), transparent 50%);
    box-shadow:
      0 20px 40px rgba(0, 0, 0, 0.45),
      inset 0 0 0 1px rgba(255, 255, 255, 0.12);
    padding: 14px 14px 12px;
    backdrop-filter: blur(5px);
  }

  .panel-title {
    margin: 0 0 10px;
    text-align: center;
    font-size: 28px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: #f2f7ff;
    text-shadow: 0 0 16px rgba(165, 208, 255, 0.35);
  }

  .actions {
    margin-top: 8px;
    display: grid;
    gap: 6px;
  }

  .action {
    height: 34px;
    border-radius: 8px;
    border: 1px solid rgba(164, 198, 237, 0.35);
    background: rgba(12, 22, 33, 0.7);
    color: rgba(235, 245, 255, 0.95);
    text-transform: uppercase;
    letter-spacing: 0.12em;
    font-size: 12px;
    font-weight: 600;
    font-family: var(--font-sans);
    cursor: pointer;
    transition: all 140ms ease;
  }
  .action:hover {
    border-color: rgba(198, 229, 255, 0.7);
    transform: translateY(-1px);
  }
  .action.primary {
    background: linear-gradient(
      180deg,
      color-mix(in oklab, var(--c-accent-mid) 65%, #b9dfff),
      color-mix(in oklab, var(--c-accent) 65%, #5b92c6)
    );
    color: #09121b;
    border-color: color-mix(in oklab, var(--c-accent-mid) 55%, #b2dbff);
  }

  .hint {
    margin: 8px 2px 0;
    text-align: center;
    font-family: var(--font-sans);
    font-size: 11px;
    line-height: 1.45;
    color: rgba(189, 211, 236, 0.75);
  }

  @media (prefers-reduced-motion: reduce) {
    .action:hover {
      transform: none;
    }
  }
</style>
