// Classic — hand-illustrated Staunton-inspired silhouettes.
// All pieces drawn in a 100x100 viewBox, centered horizontally on x=50.
// The Piece component fills via currentColor and provides stroke/highlight
// through CSS custom properties so the same SVG works for white and black.

import type { PieceKind } from "../api/contract";

// Notes on technique:
// - Each piece is a tight `<g>` of fill paths (the silhouette) followed by
//   `<g class="hi">` shapes that paint a soft top-light highlight.
// - Strokes are applied by the Piece component via `stroke`/`stroke-width`
//   on the wrapping <g>. Highlights use `var(--piece-hi)`.

export const CLASSIC: Record<PieceKind, string> = {
  p: `
    <g class="silhouette">
      <path d="M50 12c-7 0-12 5-12 12 0 4 2 8 5 10-5 3-9 9-9 16 0 6 3 11 7 14-3 2-7 7-9 14h36c-2-7-6-12-9-14 4-3 7-8 7-14 0-7-4-13-9-16 3-2 5-6 5-10 0-7-5-12-12-12z"/>
      <path d="M22 80h56c1 3 2 5 3 8H19c1-3 2-5 3-8z"/>
      <path d="M16 88h68c1 0 2 1 2 2v3c0 1-1 2-2 2H16c-1 0-2-1-2-2v-3c0-1 1-2 2-2z"/>
    </g>
    <g class="hi">
      <ellipse cx="46" cy="22" rx="4" ry="3"/>
      <ellipse cx="46" cy="44" rx="3" ry="6"/>
    </g>
  `,
  r: `
    <g class="silhouette">
      <path d="M22 16h12v8h6v-8h12v8h6v-8h12v18l-6 4v8h-6l4 30H20l4-30h-6v-8l-6-4V16h2z" transform="translate(2 0)"/>
      <path d="M20 78h60l3 8H17z"/>
      <path d="M14 86h72c1 0 2 1 2 2v4c0 1-1 2-2 2H14c-1 0-2-1-2-2v-4c0-1 1-2 2-2z"/>
    </g>
    <g class="hi">
      <rect x="26" y="20" width="3" height="14" rx="1"/>
      <rect x="26" y="40" width="3" height="28" rx="1"/>
    </g>
  `,
  n: `
    <g class="silhouette">
      <!-- Horse head profile facing left, mane behind, body below -->
      <path d="M58 12 C 70 16 78 28 80 42 C 81 50 80 58 78 64 L 78 70 H 22 C 22 64 24 60 28 56 C 33 51 36 47 36 42 C 36 39 35 37 34 35 C 30 38 25 40 21 40 C 18 40 16 38 17 35 C 18 31 22 27 28 24 L 38 16 C 36 13 36 11 38 10 C 41 9 47 9 52 10 C 54 10 56 11 58 12 Z"/>
      <path d="M62 22 C 66 24 70 28 72 32 C 70 30 66 28 62 27 Z" fill="var(--piece-bg)" stroke="none"/>
      <circle cx="50" cy="28" r="2.2" fill="var(--piece-eye)" stroke="none"/>
      <path d="M22 70h56l3 8H19z"/>
      <path d="M14 78h72c1 0 2 1 2 2v6c0 1-1 2-2 2H14c-1 0-2-1-2-2v-6c0-1 1-2 2-2z"/>
    </g>
    <g class="hi">
      <path d="M58 18 C 64 20 70 26 73 32 C 68 28 63 24 58 22 Z"/>
      <path d="M40 50 C 42 56 41 62 36 66 C 37 60 38 54 40 50 Z"/>
    </g>
  `,
  b: `
    <g class="silhouette">
      <path d="M50 8c-2 0-4 2-4 4 0 1 0 2 1 3-5 3-9 9-9 16 0 5 2 9 5 12-5 2-9 7-11 13l-1 4h38l-1-4c-2-6-6-11-11-13 3-3 5-7 5-12 0-7-4-13-9-16 1-1 1-2 1-3 0-2-2-4-4-4z"/>
      <path d="M40 18l4 6h12l4-6" stroke="var(--piece-bg)" stroke-width="2" fill="none"/>
      <path d="M22 64h56l3 10H19z"/>
      <path d="M16 76h68c1 0 2 1 2 2v6c0 1-1 2-2 2H16c-1 0-2-1-2-2v-6c0-1 1-2 2-2z"/>
    </g>
    <g class="hi">
      <ellipse cx="46" cy="14" rx="2" ry="2"/>
      <path d="M42 32c-2 4-2 9 0 14 0-5 0-9 0-14z"/>
    </g>
  `,
  q: `
    <g class="silhouette">
      <path d="M18 18l5 22 8-16 5 18 6-22 6 22 5-18 8 16 5-22-6 30c0 0-3 2-3 6 0 0 2 4 1 8H21c-1-4 1-8 1-8 0-4-3-6-3-6L13 18z" transform="translate(7 0)"/>
      <circle cx="24" cy="16" r="3"/>
      <circle cx="36" cy="14" r="3"/>
      <circle cx="50" cy="12" r="3"/>
      <circle cx="64" cy="14" r="3"/>
      <circle cx="76" cy="16" r="3"/>
      <path d="M24 60h52l3 8H21z"/>
      <path d="M22 68h56l4 10H18z"/>
      <path d="M14 78h72c1 0 2 1 2 2v6c0 1-1 2-2 2H14c-1 0-2-1-2-2v-6c0-1 1-2 2-2z"/>
    </g>
    <g class="hi">
      <ellipse cx="44" cy="42" rx="3" ry="10"/>
    </g>
  `,
  k: `
    <g class="silhouette">
      <path d="M48 4h4v8h6v4h-6v8h-4v-8h-6v-4h6z"/>
      <path d="M30 28c4-4 12-6 20-6s16 2 20 6c4 4 4 10 0 14-2 2-6 4-10 5 4 4 6 10 6 16 0 5-1 10-3 13H27c-2-3-3-8-3-13 0-6 2-12 6-16-4-1-8-3-10-5-4-4-4-10 0-14z"/>
      <path d="M24 76h52l3 8H21z"/>
      <path d="M16 84h68c1 0 2 1 2 2v6c0 1-1 2-2 2H16c-1 0-2-1-2-2v-6c0-1 1-2 2-2z"/>
    </g>
    <g class="hi">
      <ellipse cx="44" cy="36" rx="3" ry="6"/>
      <ellipse cx="44" cy="58" rx="3" ry="8"/>
    </g>
  `,
};
