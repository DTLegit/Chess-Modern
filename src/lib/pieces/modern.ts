// Modern — cleaner, slightly geometric reinterpretation of the chess set.
// Same 100x100 viewBox, same color/stroke conventions as the classic set.

import type { PieceKind } from "../api/contract";

export const MODERN: Record<PieceKind, string> = {
  p: `
    <g class="silhouette">
      <circle cx="50" cy="30" r="13"/>
      <path d="M34 56c0-7 7-12 16-12s16 5 16 12c0 8-4 14-8 22H42c-4-8-8-14-8-22z"/>
      <path d="M22 78h56v8H22z" rx="2"/>
      <rect x="16" y="86" width="68" height="8" rx="2"/>
    </g>
    <g class="hi">
      <ellipse cx="46" cy="24" rx="4" ry="4"/>
    </g>
  `,
  r: `
    <g class="silhouette">
      <path d="M22 14h10v8h6v-8h10v8h6v-8h10v8h6v-8h10v16H22z"/>
      <rect x="26" y="32" width="48" height="40" rx="2"/>
      <rect x="22" y="72" width="56" height="8" rx="2"/>
      <rect x="16" y="80" width="68" height="10" rx="2"/>
    </g>
    <g class="hi">
      <rect x="29" y="36" width="3" height="32" rx="1"/>
    </g>
  `,
  n: `
    <g class="silhouette">
      <path d="M30 14l24-2 14 14 6 14-4 6 4 30H22c0-10 6-12 12-18 4-4 4-10 0-14l-10-2c-2-4 0-8 6-12z"/>
      <circle cx="44" cy="30" r="2.4" fill="var(--piece-eye)"/>
      <rect x="18" y="76" width="64" height="8" rx="2"/>
      <rect x="14" y="84" width="72" height="10" rx="2"/>
    </g>
    <g class="hi">
      <path d="M52 22l10 8-2 4z"/>
      <path d="M40 48c2 4 1 8-2 12 0-5 0-9 2-12z"/>
    </g>
  `,
  b: `
    <g class="silhouette">
      <path d="M50 8l10 14H40z"/>
      <circle cx="50" cy="26" r="6"/>
      <path d="M30 32l40 0c2 6-6 16-20 16s-22-10-20-16z"/>
      <path d="M28 50h44l-4 22H32z"/>
      <rect x="22" y="72" width="56" height="8" rx="2"/>
      <rect x="14" y="80" width="72" height="10" rx="2"/>
    </g>
    <g class="hi">
      <ellipse cx="46" cy="24" rx="2" ry="2"/>
      <path d="M40 56c-2 5-2 10 0 14 0-5 0-10 0-14z"/>
    </g>
  `,
  q: `
    <g class="silhouette">
      <circle cx="22" cy="14" r="4"/>
      <circle cx="36" cy="10" r="4"/>
      <circle cx="50" cy="8" r="4"/>
      <circle cx="64" cy="10" r="4"/>
      <circle cx="78" cy="14" r="4"/>
      <path d="M18 14l8 24 10-22 6 22 8-24 8 24 6-22 10 22 8-24-6 32H24z"/>
      <rect x="22" y="46" width="56" height="20" rx="3"/>
      <rect x="20" y="66" width="60" height="10" rx="2"/>
      <rect x="14" y="76" width="72" height="14" rx="3"/>
    </g>
    <g class="hi">
      <ellipse cx="44" cy="56" rx="3" ry="6"/>
    </g>
  `,
  k: `
    <g class="silhouette">
      <rect x="46" y="6" width="8" height="6" rx="1"/>
      <rect x="40" y="9" width="20" height="4" rx="1"/>
      <path d="M30 16h40v18l-6 4v32H36V38l-6-4z"/>
      <rect x="22" y="70" width="56" height="10" rx="2"/>
      <rect x="14" y="80" width="72" height="14" rx="3"/>
    </g>
    <g class="hi">
      <rect x="34" y="22" width="3" height="14" rx="1"/>
      <rect x="34" y="40" width="3" height="26" rx="1"/>
    </g>
  `,
};
