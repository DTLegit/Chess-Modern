import 'dart:ui' show lerpDouble;

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
    with TickerProviderStateMixin {
  double _boardSize = 0;

  // Check-pulse animation — only runs while the king is in check.
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: AppDurations.checkPulse,
  );

  // Piece movement animation — slides the last-moved piece from its origin.
  late final AnimationController _moveCtrl = AnimationController(
    vsync: this,
    duration: AppDurations.pieceMove,
  );

  bool _wasInCheck = false;

  // Animation state for the sliding piece overlay.
  rust.Move? _lastAnimMove;
  String? _animFrom;
  String? _animTo;
  rust.Piece? _animPiece;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    widget.game.addListener(_onGameChanged);
    _moveCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animating = false;
          _animFrom = null;
          _animTo = null;
          _animPiece = null;
        });
      }
    });
  }

  @override
  void dispose() {
    widget.game.removeListener(_onGameChanged);
    _pulseCtrl.dispose();
    _moveCtrl.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    final inCheck = widget.game.view?.inCheck ?? false;
    if (inCheck && !_wasInCheck) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!inCheck && _wasInCheck) {
      _pulseCtrl
        ..stop()
        ..reset();
    }
    _wasInCheck = inCheck;

    // Trigger piece movement animation when lastMove changes.
    final newMove = widget.game.lastMove;
    if (newMove != null && newMove != _lastAnimMove) {
      _lastAnimMove = newMove;
      setState(() {
        _animFrom = newMove.from;
        _animTo = newMove.to;
        _animPiece = widget.game.board[newMove.to];
        _animating = true;
      });
      _moveCtrl
        ..reset()
        ..forward();
    }
  }

  String? _squareAt(Offset local, double size, rust.Color orientation) {
    return xyToSquare(local.dx / size, local.dy / size, orientation);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.game, widget.settings]),
        builder: (context, _) {
          final theme = AppTheme.of(context);
          final palette = theme.palette;
          final boardPalette = theme.board;
          final boardTheme = widget.settings.value.boardTheme;
          final bezelConfig = boardBezelFor(boardTheme);
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bezelConfig.topColor, bezelConfig.bottomColor],
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
                  // Click-only interaction: tap any square to select/move.
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final sq = _squareAt(
                          details.localPosition, _boardSize, orientation);
                      if (sq != null && !widget.game.inputLocked) {
                        widget.game.select(sq);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.tiny),
                      child: Stack(
                        children: [
                          // Board squares
                          for (final sq in allSquares)
                            _Square(
                              sq: sq,
                              cell: cell,
                              orientation: orientation,
                              boardPalette: boardPalette,
                              grain: boardGrainFor(boardTheme),
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

                          // Static pieces — the piece at _animTo is hidden
                          // during the slide animation and replaced by the
                          // AnimatedBuilder overlay below.
                          for (final entry in board.entries)
                            if (entry.key != _animTo || !_animating)
                              Positioned(
                                key: ValueKey('piece-${entry.key}'),
                                left: squareXY(entry.key, orientation).col *
                                    cell,
                                top: squareXY(entry.key, orientation).row *
                                    cell,
                                width: cell,
                                height: cell,
                                child: IgnorePointer(
                                  child: AnimatedScale(
                                    scale:
                                        selected == entry.key ? 1.08 : 1.0,
                                    duration: AppDurations.fast,
                                    curve: AppCurves.easeOut,
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(cell * 0.06),
                                      child: PieceWidget(
                                          piece: entry.value),
                                    ),
                                  ),
                                ),
                              ),

                          // Sliding animation overlay for the last-moved piece.
                          if (_animating &&
                              _animPiece != null &&
                              _animFrom != null &&
                              _animTo != null)
                            AnimatedBuilder(
                              animation: _moveCtrl,
                              builder: (_, child) {
                                final fromXY =
                                    squareXY(_animFrom!, orientation);
                                final toXY =
                                    squareXY(_animTo!, orientation);
                                final t = AppCurves.easeOut
                                    .transform(_moveCtrl.value);
                                final left = lerpDouble(
                                    fromXY.col * cell,
                                    toXY.col * cell,
                                    t)!;
                                final top = lerpDouble(
                                    fromXY.row * cell,
                                    toXY.row * cell,
                                    t)!;
                                return Positioned(
                                  left: left,
                                  top: top,
                                  width: cell,
                                  height: cell,
                                  child: child!,
                                );
                              },
                              child: IgnorePointer(
                                child: Padding(
                                  padding: EdgeInsets.all(cell * 0.06),
                                  child: PieceWidget(piece: _animPiece!),
                                ),
                              ),
                            ),

                          // Legal-move hints.
                          // Positioned MUST be the direct Stack child —
                          // IgnorePointer is placed inside it.
                          if (showLegalMoves && selected != null)
                            for (final sq in widget.game.legalForSelected)
                              _Hint(
                                sq: sq,
                                cell: cell,
                                orientation: orientation,
                                isCapture: board.containsKey(sq),
                                highlights: theme.highlights,
                              ),

                          // Promotion overlay
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
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Square
// ---------------------------------------------------------------------------

class _Square extends StatelessWidget {
  const _Square({
    required this.sq,
    required this.cell,
    required this.orientation,
    required this.boardPalette,
    required this.grain,
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
  final BoardGrainConfig grain;
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
    final grainColor = light ? grain.lightGrain : grain.darkGrain;
    final highlightColor =
        light ? grain.lightHighlight : grain.darkHighlight;

    return Positioned(
      left: xy.col * cell,
      top: xy.row * cell,
      width: cell,
      height: cell,
      child: Stack(
        children: [
          // SizedBox.expand forces each layer to fill the cell (ColoredBox/
          // DecoratedBox with no child return size 0 under loose Stack constraints).
          SizedBox.expand(child: ColoredBox(color: base)),
          if (grainColor != const Color(0x00000000))
            SizedBox.expand(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [grainColor, highlightColor],
                  ),
                ),
              ),
            ),
          if (isLastMove)
            SizedBox.expand(child: ColoredBox(color: highlights.last)),
          if (selected)
            SizedBox.expand(child: ColoredBox(color: highlights.select)),
          if (inCheck)
            AnimatedBuilder(
              animation: pulse,
              builder: (_, __) {
                final t = pulse is Animation<double>
                    ? (pulse as Animation<double>).value
                    : 0.0;
                final opacity = 0.5 + 0.35 * t;
                return SizedBox.expand(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Color.fromRGBO(194, 91, 79, opacity),
                          const Color(0x00C25B4F),
                        ],
                      ),
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

// ---------------------------------------------------------------------------
// Legal move hint
// ---------------------------------------------------------------------------

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
    // Positioned MUST be the direct Stack child — placing IgnorePointer
    // outside of Positioned would break the positional layout because
    // Positioned only functions as a direct Stack descendant.
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
