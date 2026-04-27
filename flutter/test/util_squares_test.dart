import 'package:chess/src/rust/api.dart' as rust;
import 'package:chess/src/util/fen.dart';
import 'package:chess/src/util/squares.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('squares', () {
    test('fileIndex / rankIndex', () {
      expect(fileIndex('a1'), 0);
      expect(fileIndex('h8'), 7);
      expect(rankIndex('a1'), 0);
      expect(rankIndex('h8'), 7);
    });

    test('isLightSquare', () {
      expect(isLightSquare('a1'), false);
      expect(isLightSquare('h1'), true);
      expect(isLightSquare('h8'), false);
    });

    test('squareXY honors orientation', () {
      expect(squareXY('a1', rust.Color.w), (col: 0, row: 7));
      expect(squareXY('h8', rust.Color.w), (col: 7, row: 0));
      expect(squareXY('a1', rust.Color.b), (col: 7, row: 0));
    });

    test('xyToSquare round-trips', () {
      expect(xyToSquare(0.05, 0.95, rust.Color.w), 'a1');
      expect(xyToSquare(0.95, 0.05, rust.Color.w), 'h8');
    });
  });

  group('FEN', () {
    test('starting position parses 32 pieces', () {
      const start =
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
      final board = parseFenBoard(start);
      expect(board.length, 32);
      expect(board['a1']?.kind, rust.PieceKind.r);
      expect(board['a1']?.color, rust.Color.w);
      expect(board['e8']?.kind, rust.PieceKind.k);
      expect(board['e8']?.color, rust.Color.b);
    });
  });
}
