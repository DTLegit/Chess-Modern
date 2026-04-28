import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../primitives/app_button.dart';
import '../primitives/app_dialog.dart';

/// Welcome / Start screen. Mirrors `legacy/svelte/lib/modals/WelcomeScreen.svelte`.
class WelcomeDialog extends StatelessWidget {
  const WelcomeDialog({
    super.key,
    required this.onNewGame,
    required this.onSettings,
  });

  final VoidCallback onNewGame;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final accent = theme.accent;
    final palette = theme.palette;

    return AppDialog(
      width: 380,
      titleWidget: const SizedBox.shrink(),
      showCloseButton: false,
      padBody: false,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.bigGap,
          AppSpacing.huge,
          AppSpacing.bigGap,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '♛',
              style: AppTextStyles.serifHero.copyWith(
                color: accent.mid,
                fontSize: 56,
                height: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'MAIN MENU',
              style: AppTextStyles.label.copyWith(
                color: accent.mid,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chess',
              style: AppTextStyles.serifHero.copyWith(color: palette.ink),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'A quiet match against a polished AI, or two players sharing a board.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyMuted.copyWith(color: palette.inkMute),
            ),
            const SizedBox(height: AppSpacing.bigGap),
            AppButton(
              label: 'Start game',
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).maybePop();
                onNewGame();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Options',
              variant: AppButtonVariant.ghost,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).maybePop();
                onSettings();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Tap a piece to select, tap a destination to move.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.caption.copyWith(color: palette.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}
