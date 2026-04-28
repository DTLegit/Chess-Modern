import 'package:flutter/widgets.dart';

import '../../rust/api.dart' as rust;
import '../../state/game_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../../util/squares.dart';
import 'piece_widget.dart';
import 'promotion_overlay.dart';

class BoardWidget extends StatefulWidget {
  const BoardWidget({
    super.key,
    required this.game,
    required this.settings,
  });

  final GameController game;
  final SettingsController settings;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  // Drag state
  String? _dragFrom;
  Offset _dragOffset = Offset.zero;
  Offset _dragStart = Offset.zero;
  bool _dragMoved = false;
  double _boardSize = 0;

  // Check pulse animation
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: AppDurations.checkPulse,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // 0.6% threshold for entering drag mode (Svelte uses the same).
  bool _crossedThreshold(double dx, double dy, double size) {
    final pct = 0.006;
    return dx.abs() > size * pct || dy.abs() > size * pct;
  }

  String? _squareAt(Offset local, double size, rust.Color orientation) {
    return xyToSquare(local.dx / size, local.dy / size, orientation);
  }

  void _onPointerDown(
    PointerDownEvent e,
    rust.Color orientation,
    Map<String, rust.Piece> board,
    rust.Color? turn,
  ) {
    final sq = _squareAt(e.localPosition, _boardSize, orientation);
    if (sq == null) return;
    final piece = board[sq];
    if (piece == null) return;
    if (turn != null && piece.color != turn) return;
    if (widget.game.inputLocked) return;
    setState(() {
      _dragFrom = sq;
      _dragStart = e.localPosition;
      _dragOffset = e.localPosition;
      _dragMoved = false;
    });
    widget.game.select(sq);
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_dragFrom == null) return;
    final dx = e.localPosition.dx - _dragStart.dx;
    final dy = e.localPosition.dy - _dragStart.dy;
    if (!_dragMoved && _crossedThreshold(dx, dy, _boardSize)) {
      setState(() => _dragMoved = true);
    }
    if (_dragMoved) {
      setState(() => _dragOffset = e.localPosition);
    }
  }

  void _onPointerUp(PointerUpEvent e, rust.Color orientation) {
    final from = _dragFrom;
    if (from == null) return;
    final wasDrag = _dragMoved;
    setState(() {
      _dragFrom = null;
      _dragMoved = false;
    });
    if (!wasDrag) return;
    final to = _squareAt(e.localPosition, _boardSize, orientation);
    if (to == null || to == from) return;
    widget.game.tryMove(from, to);
  }

  void _onPointerCancel() {
    if (_dragFrom == null) return;
    setState(() {
      _dragFrom = null;
      _dragMoved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.game, widget.settings]),
      builder: (context, _) {
        final theme = AppTheme.of(context);
        final palette = theme.palette;
        final boardPalette = theme.board;
        final view = widget.game.view;
        final board = widget.game.board;
        final orientation = widget.game.orientation;
        final selected = widget.game.selected;
        final lastMove = widget.game.lastMove;
        final showLegalMoves = widget.settings.value.showLegalMoves;
        final showCoordinates = widget.settings.value.showCoordinates;
        final showLastMove = widget.settings.value.showLastMove;
        final inCheck = view?.inCheck ?? false;
        final turn = view?.turn;
        final pendingPromotion = widget.game.pendingPromotion;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: boardPalette.bezel,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                boardPalette.bezel,
                Color.lerp(boardPalette.bezel, const Color(0xFF000000), 0.15)!,
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: palette.shadowBoard,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _boardSize = constraints.maxWidth;
                final cell = _boardSize / 8;
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) =>
                      _onPointerDown(e, orientation, board, turn),
                  onPointerMove: _onPointerMove,
                  onPointerUp: (e) => _onPointerUp(e, orientation),
                  onPointerCancel: (_) => _onPointerCancel(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.deferToChild,
                    onTapUp: (details) {
                      final sq = _squareAt(
                          details.localPosition, _boardSize, orientation);
                      if (sq != null && _dragFrom == null) {
                        widget.game.select(sq);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.tiny),
                      child: Stack(
                        children: [
                          // Squares
                          for (final sq in allSquares)
                            _Square(
                              sq: sq,
                              cell: cell,
                              orientation: orientation,
                              boardPalette: boardPalette,
                              highlights: theme.highlights,
                              selected: selected == sq,
                              isLastMove: showLastMove &&
                                  lastMove != null &&
                                  (lastMove.from == sq || lastMove.to == sq),
                              inCheck: inCheck &&
                                  board[sq]?.kind == rust.PieceKind.k &&
                                  board[sq]?.color == turn,
                              showCoordinates: showCoordinates,
                              pulse: _pulseCtrl,
                            ),
                          // Pieces (skip the dragged piece — drawn separately)
                          for (final entry in board.entries)
                            if (entry.key != _dragFrom || !_dragMoved)
                              _Piece(
                                sq: entry.key,
                                piece: entry.value,
                                cell: cell,
                                orientation: orientation,
                              ),
                          // Legal-move hints
                          if (showLegalMoves && selected != null)
                            for (final sq in widget.game.legalForSelected)
                              _Hint(
                                sq: sq,
                                cell: cell,
                                orientation: orientation,
                                isCapture: board.containsKey(sq),
                                highlights: theme.highlights,
                              ),
                          // Dragged piece (lifted)
                          if (_dragMoved && _dragFrom != null && board[_dragFrom!] != null)
                            _DraggedPiece(
                              piece: board[_dragFrom!]!,
                              cell: cell,
                              position: _dragOffset,
                            ),
                          // Promotion overlay (Phase 5a)
                          if (pendingPromotion != null)
                            PromotionOverlay(
                              boardSize: _boardSize,
                              orientation: orientation,
                              pending: pendingPromotion,
                              game: widget.game,
                            ),
                        ],
                      ),
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
    required this.boardPalette,
    required this.highlights,
    required this.selected,
    required this.isLastMove,
    required this.inCheck,
    required this.showCoordinates,
    required this.pulse,
  });

  final String sq;
  final double cell;
  final rust.Color orientation;
  final BoardPalette boardPalette;
  final AppHighlights highlights;
  final bool selected;
  final bool isLastMove;
  final bool inCheck;
  final bool showCoordinates;
  final Listenable pulse;

  @override
  Widget build(BuildContext context) {
    final xy = squareXY(sq, orientation);
    final light = isLightSquare(sq);
    final base = light ? boardPalette.light : boardPalette.dark;
    final coordColor = light ? boardPalette.dark : boardPalette.light;

    return Positioned(
      left: xy.col * cell,
      top: xy.row * cell,
      width: cell,
      height: cell,
      child: Stack(
        children: [
          ColoredBox(color: base),
          if (isLastMove) ColoredBox(color: highlights.last),
          if (selected) ColoredBox(color: highlights.select),
          if (inCheck)
            AnimatedBuilder(
              animation: pulse,
              builder: (_, __) {
                final t = pulse is Animation<double>
                    ? (pulse as Animation<double>).value
                    : 1.0;
                final opacity = 0.5 + 0.35 * t;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color.fromRGBO(194, 91, 79, opacity),
                        const Color(0x00C25B4F),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (showCoordinates && xy.col == 0)
            Positioned(
              top: 3,
              left: 4,
              child: Text(
                sq[1],
                style: AppTextStyles.caption.copyWith(
                  fontSize: cell * 0.16,
                  color: coordColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (showCoordinates && xy.row == 7)
            Positioned(
              bottom: 5,
              right: 3,
              child: Text(
                sq[0],
                style: AppTextStyles.caption.copyWith(
                  fontSize: cell * 0.16,
                  color: coordColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
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
      duration: AppDurations.pieceMove,
      curve: AppCurves.easeOut,
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

class _DraggedPiece extends StatelessWidget {
  const _DraggedPiece({
    required this.piece,
    required this.cell,
    required this.position,
  });
  final rust.Piece piece;
  final double cell;
  final Offset position;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - cell / 2,
      top: position.dy - cell / 2,
      width: cell,
      height: cell,
      child: IgnorePointer(
        child: Transform.scale(
          scale: 1.08,
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x5C000000),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(cell * 0.06),
              child: PieceWidget(piece: piece),
            ),
          ),
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
    required this.highlights,
  });

  final String sq;
  final double cell;
  final rust.Color orientation;
  final bool isCapture;
  final AppHighlights highlights;

  @override
  Widget build(BuildContext context) {
    final xy = squareXY(sq, orientation);
    return IgnorePointer(
      child: Positioned(
        left: xy.col * cell,
        top: xy.row * cell,
        width: cell,
        height: cell,
        child: Center(
          child: isCapture
              ? Container(
                  width: cell * 0.92,
                  height: cell * 0.92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: highlights.dotCap, width: 4),
                  ),
                )
              : Container(
                  width: cell * 0.26,
                  height: cell * 0.26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlights.dot,
                  ),
                ),
        ),
      ),
    );
  }
}
