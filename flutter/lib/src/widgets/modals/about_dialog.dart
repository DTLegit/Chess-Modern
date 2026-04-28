import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../primitives/app_button.dart';
import '../primitives/app_dialog.dart';

/// About modal. Mirrors `legacy/svelte/lib/modals/About.svelte`.
class ChessAboutDialog extends StatelessWidget {
  const ChessAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;
    return AppDialog(
      width: 460,
      title: 'About',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '♛',
              style: AppTextStyles.serifHero.copyWith(
                color: accent.mid,
                fontSize: 64,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              'Chess',
              style: AppTextStyles.serifHero.copyWith(
                color: palette.ink,
                fontSize: 26,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'version 0.1.0 — early preview',
              style: AppTextStyles.caption.copyWith(color: palette.inkMute),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'A polished, native cross-platform chess game.',
            style: AppTextStyles.body.copyWith(
              color: palette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Built with Flutter for the UI and Rust for the engine + AI, '
            'connected through flutter_rust_bridge.',
            style: AppTextStyles.body.copyWith(color: palette.inkSoft),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'AI uses a custom Rust minimax engine for difficulty 1–3, and '
            'Stockfish 17 for 4–10 on platforms where it is available '
            '(macOS, Windows, Linux desktop, and Android). On iOS the '
            'sandbox forbids spawning external binaries, so levels 4–10 '
            'transparently use the strongest custom-engine setting.',
            style: AppTextStyles.body.copyWith(color: palette.inkSoft),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            defaultTargetPlatform == TargetPlatform.iOS
                ? 'You are on iOS, which uses the custom Rust engine.'
                : 'Stockfish is bundled with the desktop and Android builds.',
            style: AppTextStyles.caption.copyWith(color: palette.inkMute),
          ),
        ],
      ),
      actions: [
        AppButton(
          label: 'Close',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
