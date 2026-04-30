import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

// Kept for any residual call-sites that import this enum.
enum WelcomeAction { newGame, settings }

/// Full-screen welcome overlay.
///
/// Mirrors `legacy/svelte/lib/modals/WelcomeScreen.svelte`:
/// - Dark navy radial-gradient background.
/// - Faint grid-glow layer (24 × 24 px grid with blue-tinted lines).
/// - Glassmorphic dark panel with backdrop blur, border, and box-shadow.
/// - Uppercase "CHESS" title with blue text-glow.
/// - Two action buttons: primary (accent gradient + blue mix) and ghost.
///
/// Rendered as a `Stack` overlay inside `HomeScreen` — not via `showDialog` —
/// so the underlying UI is blocked but still visible behind the overlay.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onNewGame,
    required this.onSettings,
  });

  final VoidCallback onNewGame;
  final VoidCallback onSettings;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _hoverStart = false;
  bool _hoverOptions = false;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.of(context).accent;

    return Stack(
      children: [
        // Blur the underlying app content visible through the overlay.
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: const SizedBox.expand(),
          ),
        ),
        // Dark background — base radial gradient (semi-transparent so blur shows).
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, 0.1),
              radius: 1.4,
              colors: [Color(0xD80D1015), Color(0xE50A0C10)],
            ),
          ),
        ),
        // Board-ghost: faint radial highlight.
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.04),
              radius: 0.52,
              colors: [Color(0x12FFFFFF), Color(0x00FFFFFF)],
            ),
          ),
        ),
        // Grid-glow layer.
        Positioned.fill(
          child: Opacity(
            opacity: 0.18,
            child: CustomPaint(painter: _GridGlowPainter()),
          ),
        ),
        // Content.
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHero(),
                  const SizedBox(height: 16),
                  _buildPanel(accent),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo tile — walnut gradient + ♛ silhouette.
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4F3321), Color(0xFF28170D)],
            ),
            borderRadius: BorderRadius.circular(56 * 0.3),
          ),
          child: Stack(
            children: [
              const Center(
                child: Text(
                  '♛',
                  style: TextStyle(
                    fontFamily: AppFontFamilies.serif,
                    fontSize: 34,
                    color: Color(0xFFF5E0B5),
                    height: 1.0,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(56 * 0.3),
                  border: Border.all(color: const Color(0x33000000)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'MAIN MENU',
          style: TextStyle(
            fontFamily: AppFontFamilies.sans,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
            height: 1.4,
            color: Color(0xA8D2E4FF),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(AppAccent accent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xDB14202E), Color(0xE00D151E)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x4DC1DDFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x73000000),
                blurRadius: 40,
                offset: Offset(0, 20),
              ),
              BoxShadow(
                color: Color(0x1FFFFFFF),
                blurRadius: 0,
                spreadRadius: -1,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CHESS',
                style: TextStyle(
                  fontFamily: AppFontFamilies.serif,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.24,
                  height: 1.1,
                  color: Color(0xFFF2F7FF),
                  shadows: [
                    Shadow(color: Color(0x59A5D0FF), blurRadius: 16),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: 'START GAME',
                isPrimary: true,
                hovered: _hoverStart,
                accent: accent,
                onHover: (v) => setState(() => _hoverStart = v),
                onTap: widget.onNewGame,
              ),
              const SizedBox(height: 6),
              _buildActionButton(
                label: 'OPTIONS',
                isPrimary: false,
                hovered: _hoverOptions,
                accent: accent,
                onHover: (v) => setState(() => _hoverOptions = v),
                onTap: widget.onSettings,
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'Configure mode, AI difficulty, board appearance, and game rules in the setup screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamilies.sans,
                    fontSize: 11,
                    height: 1.45,
                    color: Color(0xBFBDD3EC),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isPrimary,
    required bool hovered,
    required AppAccent accent,
    required ValueChanged<bool> onHover,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 34,
          transform: Matrix4.translationValues(0, hovered ? -1 : 0, 0),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(accent.mid, const Color(0xFFB9DFFF), 0.35)!,
                      Color.lerp(accent.base, const Color(0xFF5B92C6), 0.35)!,
                    ],
                  )
                : null,
            color: isPrimary ? null : const Color(0xB20C1621),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPrimary
                  ? Color.lerp(accent.mid, const Color(0xFFB2DBFF), 0.45)!
                  : hovered
                      ? const Color(0xB2C6E5FF)
                      : const Color(0x59A4C6ED),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFontFamilies.sans,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.44,
                color: isPrimary
                    ? const Color(0xFF09121B)
                    : const Color(0xF2EBF5FF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Faint 24 × 24 px grid with blue-tinted lines, mirroring Svelte's
/// `.grid-glow` background-image pattern (opacity applied by parent).
class _GridGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final hPaint = Paint()
      ..color = const Color(0x1299C8FF)
      ..strokeWidth = 1.0;
    final vPaint = Paint()
      ..color = const Color(0x0F99C8FF)
      ..strokeWidth = 1.0;

    const step = 24.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hPaint);
    }
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), vPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridGlowPainter old) => false;
}
