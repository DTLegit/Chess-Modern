import type { GameSnapshot, Piece, SquareStr } from "../api/contract";

export interface IllegalMoveCopy {
  title: string;
  detail: string;
}

export function explainIllegalMove(
  live: GameSnapshot,
  board: Map<SquareStr, Piece>,
  from: SquareStr,
  to: SquareStr,
): IllegalMoveCopy {
  const title = "Illegal move";
  const piece = board.get(from);

  if (!piece) {
    return {
      title,
      detail: "There is no piece on the starting square.",
    };
  }

  if (piece.color !== live.turn) {
    return {
      title,
      detail: "That piece is not yours to move on this turn.",
    };
  }

  const legal = live.legal_moves[from] ?? [];
  if (!legal.includes(to)) {
    if (live.in_check) {
      return {
        title,
        detail:
          "You are in check. You must make a move that gets out of check.",
      };
    }
    return {
      title,
      detail:
        "That square is not a legal destination for this piece. The path may be blocked, or the move would leave your king in check.",
    };
  }

  return {
    title,
    detail: "This move is not allowed.",
  };
}

export function moveRejectedCopy(): IllegalMoveCopy {
  return {
    title: "Move rejected",
    detail:
      "The game engine did not accept this move. The position may have changed.",
  };
}
