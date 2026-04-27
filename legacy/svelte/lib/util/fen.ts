// Minimal FEN parsing. We only use the piece-placement field; the rest of the
// snapshot (turn / clocks / etc.) comes from the API contract directly.

import type { Color, Piece, PieceKind, SquareStr } from "../api/contract";
import { FILES } from "./squares";

export function parseFenBoard(fen: string): Map<SquareStr, Piece> {
  const out = new Map<SquareStr, Piece>();
  const placement = fen.split(" ")[0] ?? "";
  const ranks = placement.split("/");
  if (ranks.length !== 8) return out;
  for (let r = 0; r < 8; r++) {
    const row = ranks[r]!;
    let f = 0;
    for (const ch of row) {
      if (ch >= "1" && ch <= "8") {
        f += parseInt(ch, 10);
        continue;
      }
      const color: Color = ch === ch.toUpperCase() ? "w" : "b";
      const kind = ch.toLowerCase() as PieceKind;
      const sq: SquareStr = `${FILES[f]}${8 - r}`;
      out.set(sq, { color, kind });
      f++;
    }
  }
  return out;
}

export function startingFen(): string {
  return "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
}
