import '../rust/api.dart' as rust;

/// Square / coordinate helpers (port of `legacy/svelte/lib/util/squares.ts`).

const List<String> kFiles = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
const List<int> kRanks = [1, 2, 3, 4, 5, 6, 7, 8];

int fileIndex(String sq) => sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
int rankIndex(String sq) => int.parse(sq[1]) - 1;

bool isLightSquare(String sq) => (fileIndex(sq) + rankIndex(sq)) % 2 == 1;

({int col, int row}) squareXY(String sq, rust.Color orientation) {
  final f = fileIndex(sq);
  final r = rankIndex(sq);
  if (orientation == rust.Color.w) {
    return (col: f, row: 7 - r);
  }
  return (col: 7 - f, row: r);
}

String? xyToSquare(double xPct, double yPct, rust.Color orientation) {
  final col = (xPct * 8).floor();
  final row = (yPct * 8).floor();
  if (col < 0 || col > 7 || row < 0 || row > 7) return null;
  final f = orientation == rust.Color.w ? col : 7 - col;
  final r = orientation == rust.Color.w ? 7 - row : row;
  return '${kFiles[f]}${r + 1}';
}

List<String> get allSquares {
  final out = <String>[];
  for (final f in kFiles) {
    for (final r in kRanks) {
      out.add('$f$r');
    }
  }
  return out;
}
