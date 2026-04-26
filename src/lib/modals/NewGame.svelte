<script lang="ts">
  import type {
    GameMode,
    HumanColorChoice,
    NewGameOpts,
    TimeControl,
  } from "../api/contract";
  import Modal from "../ui/Modal.svelte";
  import Button from "../ui/Button.svelte";

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

  function start() {
    const opts: NewGameOpts = {
      mode,
      ai_difficulty: mode === "hva" ? difficulty : null,
      human_color: mode === "hva" ? humanColor : null,
      time_control: selectedTimeControl(),
    };
    onstart(opts);
  }
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
    color: var(--c-walnut-deep);
    box-shadow: var(--shadow-sm), inset 0 0 0 1px var(--hairline);
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
    height: 4px;
    background: linear-gradient(
      to right,
      var(--c-walnut) 0% calc(var(--p, 50%) * 1),
      var(--hairline) calc(var(--p, 50%) * 1) 100%
    );
    border-radius: 999px;
    outline: none;
  }
  .slider:focus-visible::-webkit-slider-thumb {
    box-shadow: 0 0 0 3px rgba(112, 78, 38, 0.4), var(--shadow-sm);
  }
  .slider:focus-visible::-moz-range-thumb {
    box-shadow: 0 0 0 3px rgba(112, 78, 38, 0.4), var(--shadow-sm);
  }
  .slider::-webkit-slider-thumb {
    -webkit-appearance: none;
    width: 18px;
    height: 18px;
    background: var(--c-bg-elev);
    border: 2px solid var(--c-walnut);
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
    border: 2px solid var(--c-walnut);
    border-radius: 50%;
    cursor: pointer;
  }
  .slider-meta {
    text-align: right;
    min-width: 90px;
  }
  .diff-num {
    display: block;
    font-size: 22px;
    font-weight: 500;
    color: var(--c-walnut-deep);
    line-height: 1;
  }
  .diff-label {
    display: block;
    font-size: 11px;
    color: var(--c-ink-mute);
    margin-top: 2px;
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
  .tc-pill:hover { border-color: var(--c-walnut); color: var(--c-ink); }
  .tc-pill.active {
    background: var(--c-walnut);
    color: var(--c-bg-elev);
    border-color: var(--c-walnut-deep);
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
    border-color: var(--c-walnut);
  }
</style>
