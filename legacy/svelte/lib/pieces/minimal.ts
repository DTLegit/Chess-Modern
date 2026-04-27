import type { PieceKind } from "../api/contract";

// Minimal — clean, abstract, and highly geometric piece set.
// Uses basic shapes to represent the essence of each piece.
// All pieces drawn in a 100x100 viewBox, centered horizontally on x=50.

export const MINIMAL: Record<PieceKind, string> = {
  p: `
    <g class="silhouette">
      <circle cx="50" cy="40" r="14"/>
      <path d="M36 76 L 42 50 L 58 50 L 64 76 Z"/>
      <rect x="28" y="76" width="44" height="10" rx="3"/>
    </g>
    <g class="hi">
      <circle cx="46" cy="36" r="4"/>
    </g>
  `,
  r: `
    <g class="silhouette">
      <rect x="32" y="24" width="36" height="52"/>
      <rect x="26" y="16" width="48" height="12" rx="2"/>
      <rect x="24" y="76" width="52" height="10" rx="3"/>
    </g>
    <g class="hi">
      <rect x="36" y="30" width="4" height="40" rx="1"/>
    </g>
  `,
  n: `
    <g class="silhouette">
      <path d="M34 76 L 34 40 L 44 20 L 66 20 L 66 36 L 50 36 L 50 46 L 66 46 L 66 76 Z"/>
      <rect x="24" y="76" width="52" height="10" rx="3"/>
    </g>
    <g class="hi">
      <rect x="38" y="44" width="4" height="28" rx="1"/>
    </g>
  `,
  b: `
    <g class="silhouette">
      <circle cx="50" cy="20" r="6"/>
      <path d="M30 76 L 50 30 L 70 76 Z"/>
      <rect x="24" y="76" width="52" height="10" rx="3"/>
    </g>
    <g class="hi">
      <path d="M46 44 L 50 34 L 54 44 Z"/>
    </g>
  `,
  q: `
    <g class="silhouette">
      <circle cx="50" cy="46" r="16"/>
      <path d="M26 24 L 38 40 L 50 16 L 62 40 L 74 24 L 66 76 L 34 76 Z"/>
      <rect x="24" y="76" width="52" height="10" rx="3"/>
    </g>
    <g class="hi">
      <circle cx="50" cy="46" r="6"/>
    </g>
  `,
  k: `
    <g class="silhouette">
      <rect x="46" y="10" width="8" height="24"/>
      <rect x="38" y="16" width="24" height="8"/>
      <path d="M36 76 L 42 36 L 58 36 L 64 76 Z"/>
      <rect x="24" y="76" width="52" height="10" rx="3"/>
    </g>
    <g class="hi">
      <rect x="44" y="42" width="4" height="28" rx="1"/>
    </g>
  `,
};
