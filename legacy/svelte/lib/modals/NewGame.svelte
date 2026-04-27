<script lang="ts">
  import type {
    BoardTheme,
    GameMode,
    HumanColorChoice,
    NewGameOpts,
    TimeControl,
  } from "../api/contract";
  import Modal from "../ui/Modal.svelte";
  import Button from "../ui/Button.svelte";
  import BoardThemePreview from "../board/BoardThemePreview.svelte";
  import { settingsStore } from "../stores/settingsStore.svelte";

  interface Props {
    open: boolean;
    onclose: () => void;
    onstart: (opts: NewGameOpts) => void;
  }
  const { open, onclose, onstart }: Props = $props();

  let mode = $state<GameMode>("hva");
  let difficulty = $state(5);
  let humanColor = $state<HumanColorChoice>("w");
  let tc = $state<string>("none");
  let customMin = $state(10);
  let customInc = $state(0);
  let boardTheme = $state<BoardTheme>("wood");
  let hoverBoard = $state<BoardTheme | null>(null);

  const TC_OPTIONS = [
    { id: "none",    label: "Casual",         tc: null as TimeControl | null },
    { id: "3+2",     label: "3 + 2 Blitz",    tc: { initial_ms: 180_000,   increment_ms: 2_000 } },
    { id: "5+0",     label: "5 + 0 Blitz",    tc: { initial_ms: 300_000,   increment_ms: 0 } },
    { id: "10+0",    label: "10 + 0 Rapid",   tc: { initial_ms: 600_000,   increment_ms: 0 } },
    { id: "15+10",   label: "15 + 10 Rapid",  tc: { initial_ms: 900_000,   increment_ms: 10_000 } },
    { id: "30+0",    label: "30 + 0 Classical", tc: { initial_ms: 1_800_000, increment_ms: 0 } },
    { id: "custom",  label: "Custom",         tc: null },
  ] as const;

  const DIFF_LABELS: Record<number, string> = {
    1: "Casual",
    2: "Beginner",
    3: "Intermediate",
    4: "Strong club",
    5: "Club master",
    6: "Expert",
    7: "Candidate master",
    8: "Master",
    9: "International master",
    10: "Grandmaster",
  };
  const BOARD_OPTIONS: { value: BoardTheme; label: string; swatch: string }[] = [
    { value: "wood", label: "Wood (Stylized)", swatch: "sw-wood" },
    { value: "wood_realistic", label: "Wood (Realistic)", swatch: "sw-wood-realistic" },
    { value: "slate", label: "Slate (Stylized)", swatch: "sw-slate" },
    { value: "slate_realistic", label: "Slate (Realistic)", swatch: "sw-slate-realistic" },
    { value: "marble", label: "Marble", swatch: "sw-marble" },
    { value: "emerald", label: "Emerald", swatch: "sw-emerald" },
    { value: "obsidian", label: "Obsidian", swatch: "sw-obsidian" },
    { value: "sandstone", label: "Sandstone", swatch: "sw-sandstone" },
    { value: "midnight", label: "Midnight", swatch: "sw-midnight" },
  ];

  $effect(() => {
    if (open) boardTheme = settingsStore.settings.board_theme;
  });

  function selectedTimeControl(): TimeControl | null {
    const opt = TC_OPTIONS.find((o) => o.id === tc);
    if (!opt) return null;
    if (opt.id === "custom") {
      return {
        initial_ms: Math.max(0, customMin) * 60_000,
        increment_ms: Math.max(0, customInc) * 1_000,
      };
    }
    return opt.tc;
  }

  async function start() {
    await settingsStore.update({ board_theme: boardTheme, piece_set: "merida" });
    const opts: NewGameOpts = {
      mode,
      ai_difficulty: mode === "hva" ? difficulty : null,
      human_color: mode === "hva" ? humanColor : null,
      time_control: selectedTimeControl(),
    };
    onstart(opts);
  }

  const difficultyTrackPct = $derived(((difficulty - 1) / 9) * 100);
  const previewBoard = $derived(hoverBoard ?? boardTheme);
</script>

<Modal {open} {onclose} title="New game" width="520px">
  <div class="grid">
    <fieldset class="field">
      <legend>Mode</legend>
      <div class="seg">
        <label class:active={mode === "hva"}>
          <input type="radio" bind:group={mode} value="hva" />
          Human vs AI
        </label>
        <label class:active={mode === "hvh"}>
          <input type="radio" bind:group={mode} value="hvh" />
          Human vs Human
        </label>
      </div>
    </fieldset>

    {#if mode === "hva"}
      <fieldset class="field">
        <legend>AI difficulty</legend>
        <div class="slider-row">
          <input
            type="range"
            min="1"
            max="10"
            step="1"
            bind:value={difficulty}
            class="slider"
            style:--p="{difficultyTrackPct}%"
          />
          <div class="slider-meta tabular">
            <span class="diff-num">{difficulty}</span>
            <span class="diff-label">{DIFF_LABELS[difficulty]}</span>
          </div>
        </div>
      </fieldset>

      <fieldset class="field">
        <legend>You play as</legend>
        <div class="seg three">
          <label class:active={humanColor === "w"}>
            <input type="radio" bind:group={humanColor} value="w" /> White
          </label>
          <label class:active={humanColor === "b"}>
            <input type="radio" bind:group={humanColor} value="b" /> Black
          </label>
          <label class:active={humanColor === "random"}>
            <input type="radio" bind:group={humanColor} value="random" /> Random
          </label>
        </div>
      </fieldset>
    {/if}

    <fieldset class="field">
      <legend>Time control</legend>
      <div class="tc-grid">
        {#each TC_OPTIONS as o}
          <label class="tc-pill" class:active={tc === o.id}>
            <input type="radio" bind:group={tc} value={o.id} />
            {o.label}
          </label>
        {/each}
      </div>
      {#if tc === "custom"}
        <div class="custom-tc">
          <label>
            <span>Minutes</span>
            <input
              type="number"
              min="1"
              max="180"
              bind:value={customMin}
              class="num-input"
            />
          </label>
          <label>
            <span>Increment (s)</span>
            <input
              type="number"
              min="0"
              max="60"
              bind:value={customInc}
              class="num-input"
            />
          </label>
        </div>
      {/if}
    </fieldset>

    <fieldset class="field board-field">
      <legend>Board theme</legend>
      <div class="board-preview-wrap" role="presentation" onmouseleave={() => (hoverBoard = null)}>
        <BoardThemePreview theme={previewBoard} />
      </div>
      <div class="board-grid">
        {#each BOARD_OPTIONS as o}
          <button
            type="button"
            class="board-card {o.swatch}"
            class:active={boardTheme === o.value}
            onmouseenter={() => (hoverBoard = o.value)}
            onclick={() => {
              hoverBoard = null;
              boardTheme = o.value;
            }}
          >
            <div class="board-swatch">
              <span class="light"></span>
              <span class="dark"></span>
            </div>
            <span>{o.label}</span>
          </button>
        {/each}
      </div>
    </fieldset>
  </div>

  {#snippet footer()}
    <Button variant="ghost" onclick={onclose}>Cancel</Button>
    <Button variant="primary" onclick={start}>Start game</Button>
  {/snippet}
</Modal>

<style>
  .grid {
    display: grid;
    gap: 18px;
  }
  .field {
    border: none;
    padding: 0;
    margin: 0;
  }
  .field legend {
    display: block;
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--c-ink-mute);
    padding: 0;
    margin-bottom: 8px;
  }
  .seg {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 6px;
    background: var(--c-bg-card);
    border: 1px solid var(--hairline);
    border-radius: 10px;
    padding: 4px;
  }
  .seg.three { grid-template-columns: 1fr 1fr 1fr; }
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
  }
  .seg label:hover {
    color: var(--c-ink);
  }
  .seg input[type="radio"] {
    position: absolute;
    opacity: 0;
    pointer-events: none;
  }
  .seg label.active {
    background: var(--c-bg-elev);
    color: var(--c-ink);
    box-shadow: var(--shadow-sm), inset 0 0 0 2px var(--c-accent-mid);
  }

  .slider-row {
    display: grid;
    grid-template-columns: 1fr auto;
    gap: 14px;
    align-items: center;
  }
  .slider {
    width: 100%;
    -webkit-appearance: none;
    appearance: none;
    height: 18px;
    background: transparent;
    border-radius: 999px;
    outline: none;
  }
  .slider::-webkit-slider-runnable-track {
    height: 4px;
    background: linear-gradient(
      to right,
      var(--c-accent-mid) 0% var(--p, 50%),
      var(--hairline) var(--p, 50%) 100%
    );
    border-radius: 999px;
  }
  .slider::-moz-range-track {
    height: 4px;
    background: var(--hairline);
    border-radius: 999px;
  }
  .slider::-moz-range-progress {
    height: 4px;
    background: var(--c-accent-mid);
    border-radius: 999px;
  }
  .slider:focus-visible::-webkit-slider-thumb {
    box-shadow: 0 0 0 3px color-mix(in oklab, var(--c-accent-mid) 45%, transparent), var(--shadow-sm);
  }
  .slider:focus-visible::-moz-range-thumb {
    box-shadow: 0 0 0 3px color-mix(in oklab, var(--c-accent-mid) 45%, transparent), var(--shadow-sm);
  }
  .slider::-webkit-slider-thumb {
    -webkit-appearance: none;
    width: 18px;
    height: 18px;
    margin-top: -7px;
    background: var(--c-bg-elev);
    border: 2px solid var(--c-accent-mid);
    border-radius: 50%;
    cursor: pointer;
    box-shadow: var(--shadow-sm);
    transition: transform 120ms ease;
  }
  .slider::-webkit-slider-thumb:hover { transform: scale(1.1); }
  .slider::-moz-range-thumb {
    width: 18px;
    height: 18px;
    background: var(--c-bg-elev);
    border: 2px solid var(--c-accent-mid);
    border-radius: 50%;
    cursor: pointer;
  }
  .slider-meta {
    text-align: right;
    min-width: 148px;
    flex-shrink: 0;
  }
  .diff-num {
    display: block;
    font-size: 22px;
    font-weight: 500;
    color: var(--c-accent-mid);
    line-height: 1;
  }
  .diff-label {
    display: block;
    font-size: 11px;
    color: var(--c-ink-mute);
    margin-top: 2px;
    line-height: 1.25;
    min-height: 2.5em;
  }

  .tc-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
    gap: 6px;
  }
  .tc-pill {
    display: block;
    padding: 9px 10px;
    border-radius: 8px;
    border: 1px solid var(--hairline);
    background: var(--c-bg-card);
    text-align: center;
    font-size: 12.5px;
    color: var(--c-ink-soft);
    cursor: pointer;
    transition: all 120ms ease;
  }
  .tc-pill input { display: none; }
  .tc-pill:hover {
    border-color: color-mix(in oklab, var(--c-accent-mid) 65%, var(--hairline));
    color: var(--c-ink);
  }
  .tc-pill.active {
    background: linear-gradient(180deg, var(--c-accent-mid) 0%, var(--c-accent) 100%);
    color: var(--c-accent-ink);
    border-color: color-mix(in oklab, var(--c-accent) 55%, transparent);
  }

  .custom-tc {
    margin-top: 8px;
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
  }
  .custom-tc label {
    display: flex;
    flex-direction: column;
    gap: 4px;
    font-size: 11px;
    color: var(--c-ink-mute);
  }
  .num-input {
    height: 34px;
    padding: 0 10px;
    border: 1px solid var(--hairline-strong);
    border-radius: 8px;
    background: var(--c-bg-elev);
    font-family: var(--font-sans);
    font-variant-numeric: tabular-nums;
    color: var(--c-ink);
  }
  .num-input:focus {
    outline: none;
    border-color: var(--c-accent-mid);
  }

  .board-field {
    display: grid;
    gap: 10px;
  }
  .board-preview-wrap {
    max-width: 220px;
  }
  .board-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(132px, 1fr));
    gap: 8px;
  }
  .board-card {
    display: grid;
    gap: 7px;
    padding: 8px;
    border-radius: 8px;
    border: 1px solid var(--hairline);
    background: var(--c-bg-card);
    color: var(--c-ink-soft);
    text-align: left;
    font-size: 12px;
    font-weight: 500;
    transition: all 120ms ease;
  }
  .board-card:hover {
    border-color: color-mix(in oklab, var(--c-accent-mid) 65%, var(--hairline));
  }
  .board-card.active {
    border-color: var(--c-accent-mid);
    box-shadow: 0 0 0 2px color-mix(in oklab, var(--c-accent-mid) 40%, transparent);
    color: var(--c-ink);
  }
  .board-swatch {
    display: grid;
    grid-template-columns: 1fr 1fr;
    height: 38px;
    border-radius: 6px;
    overflow: hidden;
  }
  .sw-wood .light,
  .sw-wood-realistic .light { background: var(--sq-light-wood); }
  .sw-wood .dark,
  .sw-wood-realistic .dark { background: var(--sq-dark-wood); }
  .sw-slate .light,
  .sw-slate-realistic .light { background: var(--sq-light-slate); }
  .sw-slate .dark,
  .sw-slate-realistic .dark { background: var(--sq-dark-slate); }
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
</style>
