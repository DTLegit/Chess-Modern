import 'package:chess/src/rust/api.dart' as rust;
import 'package:chess/src/util/fen.dart';
import 'package:chess/src/util/illegal_move.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  rust.GameSnapshot snap({
    required Map<String, List<String>> legalMoves,
    rust.Color turn = rust.Color.w,
    bool inCheck = false,
    String fen =
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  }) {
    return rust.GameSnapshot(
      gameId: 'test',
      fen: fen,
      turn: turn,
      inCheck: inCheck,
      status: rust.GameStatus.active,
      result: rust.GameResult.ongoing,
      history: const [],
      legalMoves: legalMoves,
      mode: rust.GameMode.hvh,
    );
  }

  test('explainIllegalMove: empty source square', () {
    final live = snap(legalMoves: const {});
    final board = parseFenBoard(live.fen);
    final c = explainIllegalMove(
      live: live,
      board: board,
      from: 'e4',
      to: 'e5',
    );
    expect(c.detail, contains('no piece'));
  });

  test('explainIllegalMove: opponent piece', () {
    final live = snap(legalMoves: const {});
    final board = parseFenBoard(live.fen);
    final c = explainIllegalMove(
      live: live,
      board: board,
      from: 'e7',
      to: 'e6',
    );
    expect(c.detail, contains('not yours'));
  });

  test('explainIllegalMove: in check', () {
    final live = snap(legalMoves: const {'e2': ['e3']}, inCheck: true);
    final board = parseFenBoard(live.fen);
    final c = explainIllegalMove(
      live: live,
      board: board,
      from: 'e2',
      to: 'e5',
    );
    expect(c.detail, contains('check'));
  });
}
