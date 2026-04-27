<script lang="ts">
  import type { GameResult, GameStatus, NewGameOpts } from "../api/contract";
  import Modal from "../ui/Modal.svelte";
  import Button from "../ui/Button.svelte";
  import { game } from "../stores/gameStore.svelte";

  interface Props {
    open: boolean;
    onclose: () => void;
    onnewgame: () => void;
    onrematch: (opts: NewGameOpts) => void;
  }
  const { open, onclose, onnewgame, onrematch }: Props = $props();

  const result = $derived<GameResult | undefined>(game.live?.result);
  const status = $derived<GameStatus | undefined>(game.live?.status);

  const headline = $derived.by(() => {
    if (!result || result === "ongoing") return "";
    if (result === "draw") return "Draw";
    if (result === "white") return "White wins";
    if (result === "black") return "Black wins";
    return "";
  });

  const subhead = $derived.by(() => {
    switch (status) {
      case "checkmate": return "by checkmate";
      case "stalemate": return "by stalemate";
      case "draw_fifty_move": return "by the fifty-move rule";
      case "draw_threefold": return "by threefold repetition";
      case "draw_insufficient": return "by insufficient material";
      case "draw_agreement": return "by agreement";
      case "resigned": return "by resignation";
      case "time_forfeit": return "on time";
      default: return "";
    }
  });

  let copied = $state(false);
  async function copyPgn() {
    const pgn = await game.exportPgn();
    try {
      await navigator.clipboard.writeText(pgn);
      copied = true;
      setTimeout(() => (copied = false), 1400);
    } catch {
      // ignore
    }
  }

  async function exportPgn() {
    const pgn = await game.exportPgn();
    const blob = new Blob([pgn], { type: "application/x-chess-pgn" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "game.pgn";
    a.click();
    URL.revokeObjectURL(a.href);
  }

  function rematch() {
    if (!game.live) return;
    const live = game.live;
    onrematch({
      mode: live.mode,
      ai_difficulty: live.ai_difficulty,
      // Swap colors on rematch
      human_color:
        live.human_color == null
          ? null
          : live.human_color === "w"
            ? "b"
            : "w",
      time_control: live.clock
        ? { initial_ms: live.clock.white_ms, increment_ms: 0 }
        : null,
    });
  }
</script>

<Modal {open} {onclose} title={headline || "Game over"} width="420px">
  <div class="result-body">
    {#if subhead}
      <p class="sub">{subhead}</p>
    {/if}

    <div class="actions">
      <Button onclick={copyPgn}>{copied ? "Copied!" : "Copy PGN"}</Button>
      <Button onclick={exportPgn}>Export PGN…</Button>
    </div>
  </div>

  {#snippet footer()}
    <Button variant="ghost" onclick={onclose}>Close</Button>
    {#if game.live?.mode === "hva"}
      <Button onclick={rematch}>Rematch</Button>
    {/if}
    <Button variant="primary" onclick={onnewgame}>New game</Button>
  {/snippet}
</Modal>

<style>
  .result-body {
    text-align: center;
    padding: 8px 0 4px;
  }
  .sub {
    margin: 0 0 18px;
    font-size: 14px;
    color: var(--c-ink-mute);
  }
  .actions {
    display: flex;
    gap: 8px;
    justify-content: center;
  }
</style>
