<script lang="ts">
  import Modal from "../ui/Modal.svelte";
  import Button from "../ui/Button.svelte";
  import { settingsStore } from "../stores/settingsStore.svelte";
  import type { AppTheme, BoardTheme, PieceSet } from "../api/contract";

  interface Props {
    open: boolean;
    onclose: () => void;
  }
  const { open, onclose }: Props = $props();

  const s = $derived(settingsStore.settings);

  function setAppTheme(t: AppTheme) {
    void settingsStore.update({ app_theme: t });
  }
  function setTheme(t: BoardTheme) {
    void settingsStore.update({ board_theme: t });
  }
  function setPieces(p: PieceSet) {
    void settingsStore.update({ piece_set: p });
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

<Modal {open} {onclose} title="Settings" width="480px">
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
        <h3>Board theme</h3>
        <p>Wood is warm and traditional. Slate is modern and crisp.</p>
      </div>
      <div class="theme-pickers">
        <button
          class="theme-card theme-wood"
          class:active={s.board_theme === "wood"}
          onclick={() => setTheme("wood")}
        >
          <div class="swatch sw-wood">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Wood (Stylized)</span>
        </button>
        <button
          class="theme-card theme-wood-realistic"
          class:active={s.board_theme === "wood_realistic"}
          onclick={() => setTheme("wood_realistic")}
        >
          <div class="swatch sw-wood-realistic">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Wood (Realistic)</span>
        </button>
        <button
          class="theme-card theme-slate"
          class:active={s.board_theme === "slate"}
          onclick={() => setTheme("slate")}
        >
          <div class="swatch sw-slate">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Slate (Stylized)</span>
        </button>
        <button
          class="theme-card theme-slate-realistic"
          class:active={s.board_theme === "slate_realistic"}
          onclick={() => setTheme("slate_realistic")}
        >
          <div class="swatch sw-slate-realistic">
            <span class="sq light"></span>
            <span class="sq dark"></span>
          </div>
          <span>Slate (Realistic)</span>
        </button>
      </div>
    </section>

    <section class="row">
      <div class="row-head">
        <h3>Piece set</h3>
        <p>Choose from Classic, Modern, Merida, or Minimal.</p>
      </div>
      <div class="seg">
        <label class:active={s.piece_set === "classic"}>
          <input type="radio" name="set" checked={s.piece_set === "classic"} onchange={() => setPieces("classic")} />
          Classic
        </label>
        <label class:active={s.piece_set === "modern"}>
          <input type="radio" name="set" checked={s.piece_set === "modern"} onchange={() => setPieces("modern")} />
          Modern
        </label>
        <label class:active={s.piece_set === "merida"}>
          <input type="radio" name="set" checked={s.piece_set === "merida"} onchange={() => setPieces("merida")} />
          Merida
        </label>
        <label class:active={s.piece_set === "minimal"}>
          <input type="radio" name="set" checked={s.piece_set === "minimal"} onchange={() => setPieces("minimal")} />
          Minimal
        </label>
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
          min="0" max="1" step="0.05"
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

  .theme-pickers {
    display: grid;
    grid-template-columns: 1fr 1fr;
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
  .theme-card:hover { border-color: var(--c-walnut); }
  .theme-card.active {
    border-color: var(--c-walnut-deep);
    box-shadow: 0 0 0 1px var(--c-walnut-deep);
    color: var(--c-ink);
  }
  .swatch {
    display: grid;
    grid-template-columns: 1fr 1fr;
    height: 56px;
    border-radius: 6px;
    overflow: hidden;
  }
  .sw-wood .light, .sw-wood-realistic .light { background: var(--sq-light-wood); }
  .sw-wood .dark, .sw-wood-realistic .dark { background: var(--sq-dark-wood); }
  .sw-slate .light, .sw-slate-realistic .light { background: var(--sq-light-slate); }
  .sw-slate .dark, .sw-slate-realistic .dark { background: var(--sq-dark-slate); }

  .seg {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(0, 1fr));
    gap: 6px;
    background: var(--c-bg-card);
    border: 1px solid var(--hairline);
    border-radius: 10px;
    padding: 4px;
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
    color: var(--c-walnut-deep);
    box-shadow: var(--shadow-sm), inset 0 0 0 1px var(--hairline);
  }
  .seg input { position: absolute; opacity: 0; pointer-events: none; }

  .sound-row {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 16px;
    align-items: center;
  }
  .switch input { display: none; }
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
    background: var(--c-walnut);
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
    border: 2px solid var(--c-walnut);
    border-radius: 50%;
    cursor: pointer;
  }
  .vol:disabled { opacity: 0.4; }

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
  .checks label:hover { border-color: var(--c-walnut); }
  .checks input[type="checkbox"] {
    width: 16px;
    height: 16px;
    accent-color: var(--c-walnut);
  }
</style>
