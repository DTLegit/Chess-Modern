import 'package:flutter/material.dart';

import '../../rust/api.dart' as rust;
import '../../state/game_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../util/squares.dart';
import 'piece_widget.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({
    super.key,
    required this.game,
    required this.settings,
  });

  final GameController game;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([game, settings]),
      builder: (context, _) {
        final theme = ChessThemeBuilder.of(settings.value);
        final view = game.view;
        final board = game.board;
        final orientation = game.orientation;
        final selected = game.selected;
        final lastMove = game.lastMove;
        final showLegalMoves = settings.value.showLegalMoves;
        final showCoordinates = settings.value.showCoordinates;
        final showLastMove = settings.value.showLastMove;
        final inCheck = view?.inCheck ?? false;
        final turn = view?.turn;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.boardBezel,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                offset: Offset(0, 6),
                color: Color(0x55000000),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth;
                final cell = size / 8;
                return GestureDetector(
                  onTapUp: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final local = details.localPosition;
                    final sq = xyToSquare(
                      local.dx / size,
                      local.dy / size,
                      orientation,
                    );
                    if (sq != null) game.select(sq);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        // Squares
                        for (final sq in allSquares)
                          _Square(
                            sq: sq,
                            cell: cell,
                            orientation: orientation,
                            theme: theme,
                            selected: selected == sq,
                            isLastMove: showLastMove &&
                                lastMove != null &&
                                (lastMove.from == sq || lastMove.to == sq),
                            inCheck: inCheck &&
                                board[sq]?.kind == rust.PieceKind.k &&
                                board[sq]?.color == turn,
                            showCoordinates: showCoordinates,
                          ),
                        // Pieces
                        for (final entry in board.entries)
                          _Piece(
                            sq: entry.key,
                            piece: entry.value,
                            cell: cell,
                            orientation: orientation,
                          ),
                        // Legal-move hints
                        if (showLegalMoves && selected != null)
                          for (final sq in game.legalForSelected)
                            _Hint(
                              sq: sq,
                              cell: cell,
                              orientation: orientation,
                              isCapture: board.containsKey(sq),
                              theme: theme,
                            ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({
    required this.sq,
    required this.cell,
    required this.orientation,
    required this.theme,
    required this.selected,
    required this.isLastMove,
    required this.inCheck,
    required this.showCoordinates,
  });

  final String sq;
  final double cell;
  final rust.Color orientation;
  final ChessThemeData theme;
  final bool selected;
  final bool isLastMove;
  final bool inCheck;
  final bool showCoordinates;

  @override
  Widget build(BuildContext context) {
    final xy = squareXY(sq, orientation);
    final light = isLightSquare(sq);
    final base = light ? theme.boardLight : theme.boardDark;
    final coordColor = light ? theme.boardDark : theme.boardLight;

    return Positioned(
      left: xy.col * cell,
      top: xy.row * cell,
      width: cell,
      height: cell,
      child: Stack(
        children: [
          Container(color: base),
          if (isLastMove)
            Container(color: theme.lastMoveHighlight),
          if (selected)
            Container(color: theme.selectedHighlight),
          if (inCheck)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xCCC25B4F),
                    const Color(0x00C25B4F),
                  ],
                ),
              ),
            ),
          if (showCoordinates && xy.col == 0)
            Positioned(
              top: 2,
              left: 4,
              child: Text(
                sq[1],
                style: TextStyle(
                  fontSize: cell * 0.18,
                  fontWeight: FontWeight.w600,
                  color: coordColor,
                ),
              ),
            ),
          if (showCoordinates && xy.row == 7)
            Positioned(
              bottom: 2,
              right: 4,
              child: Text(
                sq[0],
                style: TextStyle(
                  fontSize: cell * 0.18,
                  fontWeight: FontWeight.w600,
                  color: coordColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Piece extends StatelessWidget {
  const _Piece({
    required this.sq,
    required this.piece,
    required this.cell,
    required this.orientation,
  });

  final String sq;
  final rust.Piece piece;
  final double cell;
  final rust.Color orientation;

  @override
  Widget build(BuildContext context) {
    final xy = squareXY(sq, orientation);
    return AnimatedPositioned(
      key: ValueKey('${piece.color}-${piece.kind}-$sq'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      left: xy.col * cell,
      top: xy.row * cell,
      width: cell,
      height: cell,
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(cell * 0.06),
          child: PieceWidget(piece: piece),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.sq,
    required this.cell,
    required this.orientation,
    required this.isCapture,
    required this.theme,
  });

  final String sq;
  final double cell;
  final rust.Color orientation;
  final bool isCapture;
  final ChessThemeData theme;

  @override
  Widget build(BuildContext context) {
    final xy = squareXY(sq, orientation);
    // `Positioned` must be a direct child of a `Stack`. We previously
    // wrapped it in `IgnorePointer`, which broke the parent-data
    // contract (`type 'ParentData' is not a subtype of type
    // 'StackParentData'`). Move IgnorePointer inside.
    return Positioned(
      left: xy.col * cell,
      top: xy.row * cell,
      width: cell,
      height: cell,
      child: IgnorePointer(
        child: Center(
          child: isCapture
              ? Container(
                  width: cell * 0.92,
                  height: cell * 0.92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.captureRing, width: 4),
                  ),
                )
              : Container(
                  width: cell * 0.26,
                  height: cell * 0.26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.legalDot,
                  ),
                ),
        ),
      ),
    );
  }
}
