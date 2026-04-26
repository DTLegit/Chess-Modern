<script lang="ts">
  import type { NewGameOpts } from "./lib/api/contract";
  import Board from "./lib/board/Board.svelte";
  import MoveHistory from "./lib/panels/MoveHistory.svelte";
  import Captures from "./lib/panels/Captures.svelte";
  import Clock from "./lib/panels/Clock.svelte";
  import NewGame from "./lib/modals/NewGame.svelte";
  import GameOver from "./lib/modals/GameOver.svelte";
  import Settings from "./lib/modals/Settings.svelte";
  import About from "./lib/modals/About.svelte";
  import Modal from "./lib/ui/Modal.svelte";
  import Button from "./lib/ui/Button.svelte";
  import { game } from "./lib/stores/gameStore.svelte";
  import { settingsStore } from "./lib/stores/settingsStore.svelte";
  import { playSound, unlockAudioOnGesture } from "./lib/audio/synth";

  let showNewGame = $state(false);
  let showSettings = $state(false);
  let showAbout = $state(false);
  let showGameOver = $state(false);
  let dismissedGameOverFor = $state<string | null>(null);

  $effect(() => {
    void settingsStore.init();
    void game.init();
    unlockAudioOnGesture();
    const off = game.onSound((kind) => playSound(kind));

    // Auto-start a casual HvH game so the board renders on first launch.
    void game.newGame({
      mode: "hvh",
      ai_difficulty: null,
      human_color: "w",
      time_control: null,
    });

    return () => off();
  });

  // Game over auto-pop
  $effect(() => {
    const live = game.live;
    if (
      live &&
      live.status !== "active" &&
      live.result !== "ongoing" &&
      live.game_id !== dismissedGameOverFor
    ) {
      showGameOver = true;
    }
  });

  // Keyboard shortcuts
  $effect(() => {
    function key(e: KeyboardEvent) {
      const target = e.target as HTMLElement | null;
      const inField =
        target && (target.tagName === "INPUT" || target.tagName === "TEXTAREA");
      if (inField) return;
      if (e.metaKey || e.ctrlKey || e.altKey) return;

      if (e.key === "Escape") {
        if (game.illegalMoveNotice) {
          game.clearIllegalMoveNotice();
          return;
        }
        if (game.pendingPromotion) {
          game.cancelPromotion();
          return;
        }
        if (showNewGame) { showNewGame = false; return; }
        if (showSettings) { showSettings = false; return; }
        if (showAbout) { showAbout = false; return; }
        if (showGameOver) { showGameOver = false; return; }
        game.deselect();
        if (!game.isAtLive) game.scrubLive();
        return;
      }
      if (e.key.toLowerCase() === "n") {
        showNewGame = true;
        e.preventDefault();
      } else if (e.key.toLowerCase() === "u") {
        void game.undo();
        e.preventDefault();
      } else if (e.key.toLowerCase() === "f") {
        game.flip();
        e.preventDefault();
      } else if (e.key === "ArrowLeft") {
        game.scrubStep(-1);
        e.preventDefault();
      } else if (e.key === "ArrowRight") {
        game.scrubStep(1);
        e.preventDefault();
      } else if (e.key === "Home") {
        game.scrubTo(0);
        e.preventDefault();
      } else if (e.key === "End") {
        game.scrubLive();
        e.preventDefault();
      }
    }
    window.addEventListener("keydown", key);
    return () => window.removeEventListener("keydown", key);
  });

  function startNewGame(opts: NewGameOpts) {
    showNewGame = false;
    showGameOver = false;
    dismissedGameOverFor = null;
    void game.newGame(opts);
  }

  function dismissGameOver() {
    showGameOver = false;
    if (game.live) dismissedGameOverFor = game.live.game_id;
  }

  const turnLabel = $derived.by(() => {
    if (!game.live) return "";
    if (game.live.status !== "active") return "Game over";
    return game.live.turn === "w" ? "White to move" : "Black to move";
  });
</script>

<div class="app">
  <header class="topbar">
    <div class="brand">
      <div class="logo-mark" aria-hidden="true">
        <svg viewBox="0 0 32 32">
          <rect x="1" y="1" width="30" height="30" rx="7" fill="#3a2515" />
          <text
            x="16"
            y="23"
            text-anchor="middle"
            font-family="New York, Iowan Old Style, Georgia, serif"
            font-size="20"
            fill="#c2933b"
            font-weight="500"
          >♛</text>
        </svg>
      </div>
      <h1 class="serif wordmark">Chess</h1>
      <span class="dot">·</span>
      <span class="turn">{turnLabel}</span>
    </div>

    <nav class="actions">
      <Button variant="ghost" size="sm" onclick={() => (showNewGame = true)} title="New game (N)">
        New game
      </Button>
      <Button
        variant="subtle"
        size="sm"
        onclick={() => game.undo()}
        title="Undo (U)"
        disabled={(game.live?.history.length ?? 0) === 0}
      >
        Undo
      </Button>
      <Button variant="subtle" size="sm" onclick={() => game.flip()} title="Flip board (F)">
        Flip
      </Button>
      <Button
        variant="subtle"
        size="sm"
        onclick={() => (showSettings = true)}
        title="Settings"
      >
        Settings
      </Button>
      <Button variant="subtle" size="sm" onclick={() => (showAbout = true)} title="About">
        About
      </Button>
    </nav>
  </header>

  <main class="layout">
    <div class="board-column">
      <div class="player player-opp">
        <div class="player-name">
          <span class="dot-color black"></span>
          <span>{game.live?.mode === "hva" && game.live.human_color === "w" ? "Computer" : "Black"}</span>
          {#if game.live?.mode === "hva" && game.live.human_color === "w"}
            <span class="badge">AI · {game.live.ai_difficulty}</span>
          {/if}
          {#if game.thinking && game.live?.turn === "b"}
            <span class="thinking">thinking…</span>
          {/if}
        </div>
        <div class="player-meta">
          <Captures side="b" />
          <Clock side="b" />
        </div>
      </div>

      <section class="board-area">
        <Board />
        {#if !game.isAtLive}
          <div class="scrub-banner">
            Viewing past position
            <button class="link" onclick={() => game.scrubLive()}>← back to live</button>
          </div>
        {/if}
      </section>

      <div class="player player-self">
        <div class="player-name">
          <span class="dot-color white"></span>
          <span>{game.live?.mode === "hva" && game.live.human_color === "b" ? "Computer" : "White"}</span>
          {#if game.live?.mode === "hva" && game.live.human_color === "b"}
            <span class="badge">AI · {game.live.ai_difficulty}</span>
          {/if}
          {#if game.thinking && game.live?.turn === "w"}
            <span class="thinking">thinking…</span>
          {/if}
        </div>
        <div class="player-meta">
          <Captures side="w" />
          <Clock side="w" />
        </div>
      </div>
    </div>

    <aside class="side-panel">
      <MoveHistory />
    </aside>
  </main>

  <footer class="statusbar">
    <span>
      {#if game.live}
        {#if game.live.mode === "hva"}
          Human vs AI · level {game.live.ai_difficulty}
        {:else}
          Human vs Human
        {/if}
      {/if}
    </span>
    <span class="hotkeys">
      <kbd>N</kbd> new · <kbd>U</kbd> undo · <kbd>F</kbd> flip · <kbd>←</kbd>/<kbd>→</kbd> scrub · <kbd>Esc</kbd> close
    </span>
  </footer>
</div>

<NewGame
  open={showNewGame}
  onclose={() => (showNewGame = false)}
  onstart={startNewGame}
/>
<Settings open={showSettings} onclose={() => (showSettings = false)} />
<About open={showAbout} onclose={() => (showAbout = false)} />
<GameOver
  open={showGameOver}
  onclose={dismissGameOver}
  onnewgame={() => { dismissGameOver(); showNewGame = true; }}
  onrematch={(opts) => { dismissGameOver(); void game.newGame(opts); }}
/>

<Modal
  open={!!game.illegalMoveNotice}
  onclose={() => game.clearIllegalMoveNotice()}
  title={game.illegalMoveNotice?.title ?? "Illegal move"}
  width="420px"
>
  <p class="illegal-body">{game.illegalMoveNotice?.detail ?? ""}</p>
  {#snippet footer()}
    <Button variant="primary" onclick={() => game.clearIllegalMoveNotice()}>
      OK
    </Button>
  {/snippet}
</Modal>

<style>
  .app {
    min-height: 100vh;
    display: grid;
    grid-template-rows: auto 1fr auto;
  }

  .topbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 10px 22px;
    border-bottom: 1px solid var(--hairline);
    background: linear-gradient(
      180deg,
      rgba(255, 250, 240, 0.7),
      rgba(255, 250, 240, 0.4)
    );
    backdrop-filter: blur(10px);
    position: sticky;
    top: 0;
    z-index: 50;
  }
  .brand {
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .logo-mark {
    width: 28px;
    height: 28px;
    border-radius: 7px;
    overflow: hidden;
    box-shadow: var(--shadow-sm);
  }
  .logo-mark svg { display: block; width: 100%; height: 100%; }
  .wordmark {
    margin: 0;
    font-family: var(--font-serif);
    font-size: 20px;
    font-weight: 500;
    letter-spacing: -0.012em;
    color: var(--c-ink);
  }
  .dot {
    color: var(--c-ink-faint);
  }
  .turn {
    font-size: 12px;
    color: var(--c-ink-mute);
    font-weight: 500;
    letter-spacing: 0.02em;
  }

  .actions {
    display: flex;
    gap: 4px;
  }

  .layout {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto auto minmax(0, 1fr);
    gap: 22px;
    padding: 22px 24px;
    width: 100%;
    align-items: stretch;
    flex: 1;
  }
  .board-column {
    grid-column: 2;
    display: flex;
    flex-direction: column;
    gap: 10px;
    align-self: center;
  }
  .board-area {
    position: relative;
    display: grid;
    place-items: center;
  }
  .side-panel {
    grid-column: 3;
    width: 320px;
    display: flex;
    flex-direction: column;
    align-self: stretch;
    min-height: 0;
  }
  .side-panel :global(section.panel) {
    flex: 1;
    min-height: 0;
  }

  .player {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    background: var(--c-bg-card);
    border: 1px solid var(--hairline);
    border-radius: 10px;
    padding: 8px 14px;
    width: min(72vh, 92vmin, 720px);
    align-self: center;
  }
  .player-meta {
    display: flex;
    align-items: center;
    gap: 12px;
    min-width: 0;
    flex: 1;
    justify-content: flex-end;
  }
  .player-meta :global(.captures) {
    flex: 1;
    min-width: 0;
  }
  .player-meta :global(.clock) {
    padding: 6px 14px;
  }
  .player-meta :global(.clock .time) {
    font-size: 22px;
  }
  .player-name {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 13px;
    font-weight: 500;
    color: var(--c-ink);
    flex-shrink: 0;
  }
  .thinking {
    font-size: 11px;
    color: var(--c-ink-mute);
    font-style: italic;
    margin-left: 6px;
  }
  .dot-color {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    border: 1px solid rgba(0, 0, 0, 0.2);
  }
  .dot-color.white { background: #f7eedb; }
  .dot-color.black { background: #1f1813; }
  .badge {
    margin-left: auto;
    background: var(--c-walnut-deep);
    color: var(--c-bg-elev);
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    padding: 2px 6px;
    border-radius: 4px;
  }

  .illegal-body {
    margin: 0;
    font-size: 14px;
    line-height: 1.5;
    color: var(--c-ink-soft);
  }
  .scrub-banner {
    position: absolute;
    top: -34px;
    left: 50%;
    transform: translateX(-50%);
    padding: 4px 12px;
    background: rgba(110, 74, 42, 0.92);
    color: var(--c-bg-elev);
    border-radius: 6px;
    font-size: 12px;
    display: flex;
    gap: 8px;
    align-items: center;
  }
  .link {
    color: var(--c-gold-soft);
    font-size: 12px;
    text-decoration: underline;
    text-underline-offset: 2px;
  }

  .statusbar {
    display: flex;
    justify-content: space-between;
    padding: 8px 22px;
    color: var(--c-ink-mute);
    font-size: 11px;
    border-top: 1px solid var(--hairline);
  }
  .hotkeys kbd {
    font-family: var(--font-mono);
    font-size: 10px;
    background: var(--c-bg-card);
    border: 1px solid var(--hairline);
    border-bottom-width: 2px;
    padding: 1px 5px;
    border-radius: 4px;
    color: var(--c-ink-soft);
    margin: 0 2px;
  }

  @media (max-width: 1080px) {
    .layout {
      grid-template-columns: 1fr;
      padding: 16px;
      gap: 14px;
    }
    .board-column { grid-column: 1; }
    .side-panel {
      grid-column: 1;
      width: min(72vh, 92vmin, 720px);
      align-self: center;
      min-height: 320px;
    }
  }
</style>
