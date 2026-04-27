// Square / coordinate helpers.

import type { Color, SquareStr } from "../api/contract";

export const FILES = ["a", "b", "c", "d", "e", "f", "g", "h"] as const;
export const RANKS = [1, 2, 3, 4, 5, 6, 7, 8] as const;

export function fileIndex(sq: SquareStr): number {
  return sq.charCodeAt(0) - 97; // 'a' -> 0
}

export function rankIndex(sq: SquareStr): number {
  return parseInt(sq[1]!, 10) - 1; // '1' -> 0
}

/** Light squares are where (file + rank) is odd. */
export function isLightSquare(sq: SquareStr): boolean {
  return (fileIndex(sq) + rankIndex(sq)) % 2 === 1;
}

/** Returns column/row 0..7 in screen coordinates given board orientation. */
export function squareXY(
  sq: SquareStr,
  orientation: Color,
): { col: number; row: number } {
  const f = fileIndex(sq);
  const r = rankIndex(sq);
  if (orientation === "w") {
    return { col: f, row: 7 - r };
  }
  return { col: 7 - f, row: r };
}

/** Convert a click in 0..1 board coordinates back to a square. */
export function xyToSquare(
  xPct: number,
  yPct: number,
  orientation: Color,
): SquareStr | null {
  const col = Math.floor(xPct * 8);
  const row = Math.floor(yPct * 8);
  if (col < 0 || col > 7 || row < 0 || row > 7) return null;
  const f = orientation === "w" ? col : 7 - col;
  const r = orientation === "w" ? 7 - row : row;
  return `${FILES[f]}${r + 1}`;
}

export const ALL_SQUARES: SquareStr[] = (() => {
  const out: SquareStr[] = [];
  for (const f of FILES) for (const r of RANKS) out.push(`${f}${r}`);
  return out;
})();
