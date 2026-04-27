// Local helper types for the frontend, not part of the API contract.

import type { Color, PieceKind, SquareStr } from "../api/contract";

/** A piece tracked across moves so we can animate it between squares. */
export interface TrackedPiece {
  id: number;
  color: Color;
  kind: PieceKind;
  square: SquareStr;
  /** True if just captured this turn — fades + scales out. */
  captured?: boolean;
  /** Promotion target — when set, replaces `kind` after the slide. */
  promoteTo?: PieceKind;
}

export type ToastKind = "info" | "success" | "warn" | "error";

export interface Toast {
  id: number;
  kind: ToastKind;
  message: string;
}
