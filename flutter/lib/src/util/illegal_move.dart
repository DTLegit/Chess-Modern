import '../rust/api.dart' as rust;

class IllegalMoveCopy {
  const IllegalMoveCopy({required this.title, required this.detail});
  final String title;
  final String detail;
}

IllegalMoveCopy explainIllegalMove({
  required rust.GameSnapshot live,
  required Map<String, rust.Piece> board,
  required String from,
  required String to,
}) {
  const title = 'Illegal move';
  final piece = board[from];
  if (piece == null) {
    return const IllegalMoveCopy(
      title: title,
      detail: 'There is no piece on the starting square.',
    );
  }
  if (piece.color != live.turn) {
    return const IllegalMoveCopy(
      title: title,
      detail: 'That piece is not yours to move on this turn.',
    );
  }
  final legal = live.legalMoves[from] ?? const <String>[];
  if (!legal.contains(to)) {
    if (live.inCheck) {
      return const IllegalMoveCopy(
        title: title,
        detail:
            'You are in check. You must make a move that gets out of check.',
      );
    }
    return const IllegalMoveCopy(
      title: title,
      detail:
          'That square is not a legal destination for this piece. The path may be blocked, or the move would leave your king in check.',
    );
  }
  return const IllegalMoveCopy(
    title: title,
    detail: 'This move is not allowed.',
  );
}

IllegalMoveCopy moveRejectedCopy() => const IllegalMoveCopy(
      title: 'Move rejected',
      detail:
          'The game engine did not accept this move. The position may have changed.',
    );
