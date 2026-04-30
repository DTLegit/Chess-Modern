import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../rust/api.dart' as rust;
import '../board/merida.dart';

/// Brand mark for the top bar and about dialog.
///
/// Shows a walnut-gradient squircle tile with a dark knight silhouette in
/// front of a cream king silhouette — mirroring the app icon's composition.
class GameLogo extends StatelessWidget {
  const GameLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final r = size * 0.28;
    final pieceSize = size * 0.72;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7A5430), Color(0xFF3A2515)],
        ),
        borderRadius: BorderRadius.circular(r),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle chess-board grid overlay for texture.
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            // King — cream silhouette, offset slightly right.
            Transform.translate(
              offset: Offset(size * 0.12, size * 0.04),
              child: _PieceSilhouette(
                kind: rust.PieceKind.k,
                color: rust.Color.w,
                size: pieceSize,
                tint: const Color(0xFFD4A96A),
              ),
            ),
            // Knight — dark silhouette, offset slightly left and in front.
            Transform.translate(
              offset: Offset(-size * 0.1, size * 0.02),
              child: _PieceSilhouette(
                kind: rust.PieceKind.n,
                color: rust.Color.b,
                size: pieceSize,
                tint: const Color(0xFF1A1008),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a Merida chess piece SVG as a flat silhouette using the given [tint].
class _PieceSilhouette extends StatelessWidget {
  const _PieceSilhouette({
    required this.kind,
    required this.color,
    required this.size,
    required this.tint,
  });

  final rust.PieceKind kind;
  final rust.Color color;
  final double size;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      child: SvgPicture.string(
        meridaSvg(kind, color),
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Faint 2×2 grid overlay to add a subtle chess-board texture to the tile.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x18000000);
    final half = size.width / 2;
    // Two dark quadrants (like a chess board corner).
    canvas.drawRect(Rect.fromLTWH(half, 0, half, half), paint);
    canvas.drawRect(Rect.fromLTWH(0, half, half, half), paint);
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

/// Larger version of GameLogo for the about dialog.
class GameLogoLarge extends StatelessWidget {
  const GameLogoLarge({super.key});

  @override
  Widget build(BuildContext context) => const GameLogo(size: 40);
}
