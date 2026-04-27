import '../rust/api.dart' as rust;
import 'squares.dart';

/// Parse the placement field of a FEN into a square -> piece map.
Map<String, rust.Piece> parseFenBoard(String fen) {
  final out = <String, rust.Piece>{};
  final placement = fen.split(' ').first;
  final ranks = placement.split('/');
  if (ranks.length != 8) return out;
  for (var r = 0; r < 8; r++) {
    var f = 0;
    final row = ranks[r];
    for (var i = 0; i < row.length; i++) {
      final ch = row[i];
      final code = ch.codeUnitAt(0);
      if (code >= '1'.codeUnitAt(0) && code <= '8'.codeUnitAt(0)) {
        f += int.parse(ch);
        continue;
      }
      final isWhite = ch == ch.toUpperCase();
      final lower = ch.toLowerCase();
      final kind = switch (lower) {
        'p' => rust.PieceKind.p,
        'n' => rust.PieceKind.n,
        'b' => rust.PieceKind.b,
        'r' => rust.PieceKind.r,
        'q' => rust.PieceKind.q,
        'k' => rust.PieceKind.k,
        _ => null,
      };
      if (kind != null) {
        final sq = '${kFiles[f]}${8 - r}';
        out[sq] = rust.Piece(
          color: isWhite ? rust.Color.w : rust.Color.b,
          kind: kind,
        );
      }
      f++;
    }
  }
  return out;
}
