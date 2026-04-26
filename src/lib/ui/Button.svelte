<script lang="ts">
  import type { Snippet } from "svelte";

  interface Props {
    variant?: "primary" | "ghost" | "subtle" | "danger";
    size?: "sm" | "md";
    type?: "button" | "submit" | "reset";
    disabled?: boolean;
    onclick?: (e: MouseEvent) => void;
    title?: string;
    children: Snippet;
  }

  const {
    variant = "ghost",
    size = "md",
    type = "button",
    disabled = false,
    onclick,
    title,
    children,
  }: Props = $props();
</script>

<button
  {type}
  class="btn variant-{variant} size-{size}"
  {disabled}
  {onclick}
  {title}
>
  {@render children()}
</button>

<style>
  .btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    font-family: var(--font-sans);
    font-weight: 500;
    line-height: 1;
    border-radius: 8px;
    transition:
      background-color 120ms ease,
      color 120ms ease,
      transform 120ms var(--ease-out),
      box-shadow 120ms ease,
      border-color 120ms ease;
    border: 1px solid transparent;
    user-select: none;
    white-space: nowrap;
  }
  .btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  .btn:not(:disabled):hover {
    transform: translateY(-1px);
  }
  .btn:not(:disabled):active {
    transform: translateY(0);
  }
  .size-md {
    height: 34px;
    padding: 0 14px;
    font-size: 13px;
  }
  .size-sm {
    height: 28px;
    padding: 0 10px;
    font-size: 12px;
  }

  .variant-primary {
    background: linear-gradient(180deg, #c2933b 0%, #a87a28 100%);
    color: #fffaee;
    box-shadow:
      inset 0 1px 0 rgba(255, 255, 255, 0.18),
      0 1px 2px rgba(70, 45, 12, 0.2);
    border-color: rgba(70, 45, 12, 0.18);
  }
  .variant-primary:not(:disabled):hover {
    box-shadow:
      inset 0 1px 0 rgba(255, 255, 255, 0.22),
      0 4px 10px rgba(70, 45, 12, 0.22);
  }

  .variant-ghost {
    background: transparent;
    color: var(--c-ink);
    border-color: var(--hairline-strong);
  }
  .variant-ghost:not(:disabled):hover {
    background: rgba(110, 74, 42, 0.06);
    border-color: var(--c-walnut);
  }

  .variant-subtle {
    background: transparent;
    color: var(--c-ink-soft);
  }
  .variant-subtle:not(:disabled):hover {
    background: rgba(110, 74, 42, 0.08);
    color: var(--c-ink);
  }

  .variant-danger {
    background: transparent;
    color: var(--c-red-soft);
    border-color: rgba(194, 91, 79, 0.42);
  }
  .variant-danger:not(:disabled):hover {
    background: rgba(194, 91, 79, 0.1);
    border-color: var(--c-red-soft);
  }
</style>
