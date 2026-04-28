import 'package:flutter/widgets.dart';

import '../../rust/api.dart' as rust;
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../util/squares.dart';
import 'piece_widget.dart';

/// In-board promotion picker overlay.
///
/// Mirrors `legacy/svelte/lib/modals/Promotion.svelte`:
/// - Positioned on the destination square as percentages of the board size.
/// - Stacks 4 piece buttons (Q, N, R, B) vertically.
/// - Direction is upward (toward player) when promoting on rank 8,
///   downward when promoting on rank 1.
/// - Semi-transparent dark backdrop with 2px blur covers the rest of the
///   board; tapping it cancels.
/// - 160ms scale-in (0.94 → 1.0) with `easeOut`.
class PromotionOverlay extends StatefulWidget {
  const PromotionOverlay({
    super.key,
    required this.boardSize,
    required this.orientation,
    required this.pending,
    required this.game,
  });

  final double boardSize;
  final rust.Color orientation;
  final PendingPromotion pending;
  final GameController game;

  @override
  State<PromotionOverlay> createState() => _PromotionOverlayState();
}

class _PromotionOverlayState extends State<PromotionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  )..forward();
  late final Animation<double> _anim =
      CurvedAnimation(parent: _ctrl, curve: AppCurves.easeOut);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _choices = [
    rust.Promotion.q,
    rust.Promotion.n,
    rust.Promotion.r,
    rust.Promotion.b,
  ];

  rust.PieceKind _kind(rust.Promotion p) {
    switch (p) {
      case rust.Promotion.q:
        return rust.PieceKind.q;
      case rust.Promotion.n:
        return rust.PieceKind.n;
      case rust.Promotion.r:
        return rust.PieceKind.r;
      case rust.Promotion.b:
        return rust.PieceKind.b;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.boardSize;
    final cell = size / 8;
    final destXY = squareXY(widget.pending.to, widget.orientation);
    // Direction: if promoting on the top row (row 0), stack downward. Else
    // stack upward toward the player.
    final stackDown = destXY.row == 0;
    final col = destXY.col;
    final startRow = stackDown ? destXY.row : (destXY.row - 3);

    return Stack(
      children: [
        // Backdrop — taps cancel.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.game.cancelPromotion(),
            child: FadeTransition(
              opacity: _anim,
              child: const ColoredBox(color: Color(0x66000000)),
            ),
          ),
        ),
        // Picker tiles.
        Positioned(
          left: col * cell,
          top: startRow * cell,
          width: cell,
          height: cell * 4,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(_anim),
            child: FadeTransition(
              opacity: _anim,
              child: Column(
                children: [
                  for (final p in _choices)
                    _Tile(
                      cell: cell,
                      color: widget.pending.color,
                      kind: _kind(p),
                      onTap: () => widget.game.commitPromotion(p),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({
    required this.cell,
    required this.color,
    required this.kind,
    required this.onTap,
  });
  final double cell;
  final rust.Color color;
  final rust.PieceKind kind;
  final VoidCallback onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: widget.cell,
          height: widget.cell,
          decoration: BoxDecoration(
            color: _hover ? theme.accent.soft : theme.palette.bgElev,
            border: Border.all(color: theme.palette.hairline, width: 1),
          ),
          padding: EdgeInsets.all(widget.cell * 0.10),
          child: PieceWidget(
            piece: rust.Piece(color: widget.color, kind: widget.kind),
          ),
        ),
      ),
    );
  }
}
