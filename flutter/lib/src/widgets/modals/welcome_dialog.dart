import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../primitives/app_button.dart';
import '../primitives/game_logo.dart';

// Kept for any residual call-sites that import this enum.
enum WelcomeAction { newGame, settings }

/// Full-screen welcome overlay.
///
/// Updated to match the "Tactile Flat" and suite-wide theme designs.
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
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final isFlat = palette.shadowSm.isEmpty;

    return Stack(
      children: [
        // Blur the underlying app content visible through the overlay.
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              color: palette.bg.withValues(alpha: 0.6),
            ),
          ),
        ),
        // Content.
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pageMargin),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHero(palette),
                  const SizedBox(height: AppSpacing.xl),
                  _buildPanel(palette, isFlat),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(AppPalette palette) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GameLogo(size: 64),
        const SizedBox(height: AppSpacing.md),
        Text(
          'MAIN MENU',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
            color: palette.inkSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(AppPalette palette, bool isFlat) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: palette.bgElev,
        borderRadius: BorderRadius.circular(isFlat ? AppRadii.lg : AppRadii.xl),
        border: Border.all(color: palette.hairline, width: 1),
        boxShadow: palette.shadowLg,
      ),
      padding: const EdgeInsets.all(AppSpacing.huge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CHESS',
            style: AppTextStyles.serifTitle.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.24,
              height: 1.1,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.bigGap),
          AppButton(
            label: 'START GAME',
            fullWidth: true,
            onPressed: widget.onNewGame,
            variant: AppButtonVariant.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'APPEARANCE',
            fullWidth: true,
            onPressed: widget.onSettings,
            variant: AppButtonVariant.ghost,
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'Configure mode, AI difficulty, board appearance, and game rules in the setup screen.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                height: 1.45,
                color: palette.inkMute,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
