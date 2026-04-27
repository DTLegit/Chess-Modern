<script lang="ts">
  import Modal from "../ui/Modal.svelte";
  import Button from "../ui/Button.svelte";
  import BoardThemePreview from "../board/BoardThemePreview.svelte";
  import { settingsStore } from "../stores/settingsStore.svelte";
  import type { Accent, AppTheme, BoardTheme } from "../api/contract";

  interface Props {
    open: boolean;
    onclose: () => void;
  }
  const { open, onclose }: Props = $props();

  const s = $derived(settingsStore.settings);
  const accent = $derived(s.accent ?? "walnut");

  let hoverBoard = $state<BoardTheme | null>(null);
  const previewBoard = $derived(hoverBoard ?? s.board_theme);

  function setAppTheme(t: AppTheme) {
    void settingsStore.update({ app_theme: t });
  }
  function setTheme(t: BoardTheme) {
    hoverBoard = null;
    void settingsStore.update({ board_theme: t });
  }
  function setAccent(a: Accent) {
    void settingsStore.update({ accent: a });
  }
  function setSound(v: boolean) {
    void settingsStore.update({ sound_enabled: v });
  }
  function setVolume(v: number) {
    void settingsStore.update({ sound_volume: v });
  }
  function setBool(key: keyof typeof s, v: boolean) {
    void settingsStore.update({ [key]: v } as Partial<typeof s>);
  }
</script>

<Modal {open} {onclose} title="Settings" width="780px">
  <div class="grid">
    <section class="row">
      <div class="row-head">
        <h3>App theme</h3>
        <p>Choose the overall color scheme for the application.</p>
      </div>
      <div class="seg">
        <label class:active={s.app_theme === "light"}>
          <input type="radio" name="app_theme" checked={s.app_theme === "light"} onchange={() => setAppTheme("light")} />
          Light
        </label>
        <label class:active={s.app_theme === "dark"}>
          <input type="radio" name="app_theme" checked={s.app_theme === "dark"} onchange={() => setAppTheme("dark")} />
          Dark
        </label>
        <label class:active={s.app_theme === "blue"}>
          <input type="radio" name="app_theme" checked={s.app_theme === "blue"} onchange={() => setAppTheme("blue")} />
          Blue
        </label>
      </div>
    </section>

    <section class="row">
      <div class="row-head">
        <h3>Accent color</h3>
        <p>Buttons, toggles, and focus rings follow this accent.</p>
      </div>
      <div class="seg accent-row">
        <label class:active={accent === "walnut"}>
          <input type="radio" name="accent" checked={accent === "walnut"} onchange={() => setAccent("walnut")} />
          Walnut
        </label>
        <label class:active={accent === "forest"}>
          <input type="radio" name="accent" checked={accent === "forest"} onchange={() => setAccent("forest")} />
          Forest
        </label>
        <label class:active={accent === "violet"}>
          <input type="radio" name="accent" checked={accent === "violet"} onchange={() => setAccent("violet")} />
          Violet
        </label>
        <label class:active={accent === "teal"}>
          <input type="radio" name="accent" checked={accent === "teal"} onchange={() => setAccent("teal")} />
          Teal
        </label>
        <label class:active={accent === "rose"}>
          <input type="radio" name="accent" checked={accent === "rose"} onchange={() => setAccent("rose")} />
          Rose
        </label>
      </div>
    </section>

    <section class="row board-section">
      <div class="row-head">
        <h3>Board theme</h3>
        <p>Preview updates as you point at a style; click to apply.</p>
      </div>
      <div
        class="preview-wrap"
        role="presentation"
        onmouseleave={() => {
          hoverBoard = null;
        }}
      >
        <BoardThemePreview theme={previewBoard} />
      </div>
      <div class="theme-pickers">
        <button
          type="button"
          class="theme-card theme-wood"
          class:active={s.board_theme === "wood"}
          onmouseenter={() => (hoverBoard = "wood")}
          onclick={() => setTheme("wood")}
        >
          <div class="swatch sw-wood">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Wood (Stylized)</span>
        </button>
        <button
          type="button"
          class="theme-card theme-wood-realistic"
          class:active={s.board_theme === "wood_realistic"}
          onmouseenter={() => (hoverBoard = "wood_realistic")}
          onclick={() => setTheme("wood_realistic")}
        >
          <div class="swatch sw-wood-realistic">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Wood (Realistic)</span>
        </button>
        <button
          type="button"
          class="theme-card theme-slate"
          class:active={s.board_theme === "slate"}
          onmouseenter={() => (hoverBoard = "slate")}
          onclick={() => setTheme("slate")}
        >
          <div class="swatch sw-slate">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Slate (Stylized)</span>
        </button>
        <button
          type="button"
          class="theme-card theme-slate-realistic"
          class:active={s.board_theme === "slate_realistic"}
          onmouseenter={() => (hoverBoard = "slate_realistic")}
          onclick={() => setTheme("slate_realistic")}
        >
          <div class="swatch sw-slate-realistic">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Slate (Realistic)</span>
        </button>
        <button
          type="button"
          class="theme-card theme-marble"
          class:active={s.board_theme === "marble"}
          onmouseenter={() => (hoverBoard = "marble")}
          onclick={() => setTheme("marble")}
        >
          <div class="swatch sw-marble">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Marble</span>
        </button>
        <button
          type="button"
          class="theme-card theme-emerald"
          class:active={s.board_theme === "emerald"}
          onmouseenter={() => (hoverBoard = "emerald")}
          onclick={() => setTheme("emerald")}
        >
          <div class="swatch sw-emerald">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Emerald</span>
        </button>
        <button
          type="button"
          class="theme-card theme-obsidian"
          class:active={s.board_theme === "obsidian"}
          onmouseenter={() => (hoverBoard = "obsidian")}
          onclick={() => setTheme("obsidian")}
        >
          <div class="swatch sw-obsidian">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Obsidian</span>
        </button>
        <button
          type="button"
          class="theme-card theme-sandstone"
          class:active={s.board_theme === "sandstone"}
          onmouseenter={() => (hoverBoard = "sandstone")}
          onclick={() => setTheme("sandstone")}
        >
          <div class="swatch sw-sandstone">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Sandstone</span>
        </button>
        <button
          type="button"
          class="theme-card theme-midnight"
          class:active={s.board_theme === "midnight"}
          onmouseenter={() => (hoverBoard = "midnight")}
          onclick={() => setTheme("midnight")}
        >
          <div class="swatch sw-midnight">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Midnight</span>
        </button>
      </div>
    </section>

    <section class="row">
      <div class="row-head">
        <h3>Sound</h3>
        <p>Procedural woody clicks and quiet chimes.</p>
      </div>
      <div class="sound-row">
        <label class="switch">
          <input
            type="checkbox"
            checked={s.sound_enabled}
            onchange={(e) => setSound((e.target as HTMLInputElement).checked)}
          />
          <span class="track"><span class="thumb"></span></span>
        </label>
        <input
          type="range"
          min="0"
          max="1"
          step="0.05"
          value={s.sound_volume}
          disabled={!s.sound_enabled}
          oninput={(e) => setVolume(parseFloat((e.target as HTMLInputElement).value))}
          class="vol"
        />
      </div>
    </section>

    <section class="row">
      <div class="row-head">
        <h3>Board hints</h3>
      </div>
      <div class="checks">
        <label>
          <input
            type="checkbox"
            checked={s.show_legal_moves}
            onchange={(e) => setBool("show_legal_moves", (e.target as HTMLInputElement).checked)}
          />
          <span>Show legal moves</span>
        </label>
        <label>
          <input
            type="checkbox"
            checked={s.show_coordinates}
            onchange={(e) => setBool("show_coordinates", (e.target as HTMLInputElement).checked)}
          />
          <span>Show coordinates</span>
        </label>
        <label>
          <input
            type="checkbox"
            checked={s.show_last_move}
            onchange={(e) => setBool("show_last_move", (e.target as HTMLInputElement).checked)}
          />
          <span>Highlight last move</span>
        </label>
      </div>
    </section>
  </div>

  {#snippet footer()}
    <Button variant="primary" onclick={onclose}>Done</Button>
  {/snippet}
</Modal>

<style>
  .grid {
    display: grid;
    gap: 18px;
  }
  .row {
    display: grid;
    gap: 10px;
  }
  .board-section {
    gap: 12px;
  }
  .row-head h3 {
    margin: 0 0 2px;
    font-size: 13px;
    font-weight: 600;
    color: var(--c-ink);
  }
  .row-head p {
    margin: 0;
    font-size: 12px;
    color: var(--c-ink-mute);
  }

  .preview-wrap {
    max-width: 320px;
  }

  .theme-pickers {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 10px;
  }
  .theme-card {
    display: grid;
    gap: 8px;
    padding: 10px;
    border: 1px solid var(--hairline);
    border-radius: 10px;
    background: var(--c-bg-card);
    transition: all 120ms ease;
    text-align: left;
    color: var(--c-ink-soft);
    font-size: 13px;
    font-weight: 500;
  }
  .theme-card:hover {
    border-color: color-mix(in oklab, var(--c-accent-mid) 65%, var(--hairline));
  }
  .theme-card.active {
    border-color: var(--c-accent-mid);
    box-shadow: 0 0 0 2px color-mix(in oklab, var(--c-accent-mid) 45%, transparent);
    color: var(--c-ink);
  }
  .swatch {
    display: grid;
    grid-template-columns: 1fr 1fr;
    height: 56px;
    border-radius: 6px;
    overflow: hidden;
  }
  .sw-wood .light,
  .sw-wood-realistic .light {
    background: var(--sq-light-wood);
  }
  .sw-wood .dark,
  .sw-wood-realistic .dark {
    background: var(--sq-dark-wood);
  }
  .sw-slate .light,
  .sw-slate-realistic .light {
    background: var(--sq-light-slate);
  }
  .sw-slate .dark,
  .sw-slate-realistic .dark {
    background: var(--sq-dark-slate);
  }
  .sw-marble .light { background: #eceff3; }
  .sw-marble .dark { background: #8b939f; }
  .sw-emerald .light { background: #d8efe3; }
  .sw-emerald .dark { background: #2f6f56; }
  .sw-obsidian .light { background: #7b8797; }
  .sw-obsidian .dark { background: #151b26; }
  .sw-sandstone .light { background: #efd8b8; }
  .sw-sandstone .dark { background: #b58959; }
  .sw-midnight .light { background: #4b5f86; }
  .sw-midnight .dark { background: #101a30; }

  .seg {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(0, 1fr));
    gap: 6px;
    background: var(--c-bg-card);
    border: 1px solid var(--hairline);
    border-radius: 10px;
    padding: 4px;
  }
  .accent-row {
    grid-template-columns: repeat(auto-fit, minmax(72px, 1fr));
  }
  .seg label {
    display: block;
    text-align: center;
    padding: 8px 10px;
    border-radius: 7px;
    font-size: 13px;
    font-weight: 500;
    color: var(--c-ink-soft);
    cursor: pointer;
    transition: all 120ms ease;
    position: relative;
  }
  .seg label.active {
    background: var(--c-bg-elev);
    color: var(--c-ink);
    box-shadow: inset 0 0 0 2px var(--c-accent-mid);
  }
  .seg input {
    position: absolute;
    opacity: 0;
    pointer-events: none;
  }

  .sound-row {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 16px;
    align-items: center;
  }
  .switch input {
    display: none;
  }
  .switch .track {
    width: 38px;
    height: 22px;
    background: var(--hairline-strong);
    border-radius: 999px;
    display: inline-block;
    position: relative;
    transition: background-color 160ms ease;
  }
  .switch .thumb {
    position: absolute;
    top: 3px;
    left: 3px;
    width: 16px;
    height: 16px;
    border-radius: 50%;
    background: var(--c-bg-elev);
    box-shadow: var(--shadow-sm);
    transition: transform 160ms var(--ease-out);
  }
  .switch input:checked + .track {
    background: var(--c-accent-mid);
  }
  .switch input:checked + .track .thumb {
    transform: translateX(16px);
  }
  .vol {
    width: 100%;
    -webkit-appearance: none;
    appearance: none;
    height: 4px;
    background: var(--hairline-strong);
    border-radius: 999px;
  }
  .vol::-webkit-slider-thumb {
    -webkit-appearance: none;
    width: 16px;
    height: 16px;
    background: var(--c-bg-elev);
    border: 2px solid var(--c-accent-mid);
    border-radius: 50%;
    cursor: pointer;
  }
  .vol:disabled {
    opacity: 0.4;
  }

  .checks {
    display: grid;
    gap: 8px;
  }
  .checks label {
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 13px;
    color: var(--c-ink);
    padding: 8px 10px;
    background: var(--c-bg-card);
    border: 1px solid var(--hairline);
    border-radius: 8px;
    cursor: pointer;
    transition: all 120ms ease;
  }
  .checks label:hover {
    border-color: color-mix(in oklab, var(--c-accent-mid) 55%, var(--hairline));
  }
  .checks input[type="checkbox"] {
    width: 16px;
    height: 16px;
    accent-color: var(--c-accent-mid);
  }

  @media (max-width: 820px) {
    .theme-pickers {
      grid-template-columns: 1fr 1fr;
    }
  }
</style>
