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
    return AppDialog(
      // Svelte: width="380px"
      width: 380,
      title: 'About',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo tile.
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6E4A2A), Color(0xFF3A2515)],
              ),
              borderRadius: BorderRadius.circular(64 * 0.3),
              boxShadow: palette.shadowMd,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '♛',
                    style: TextStyle(
                      fontFamily: AppFontFamilies.serif,
                      fontSize: 40,
                      color: const Color(0xFFF5E0B5),
                      height: 1.0,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(64 * 0.3),
                    border: Border.all(color: const Color(0x33000000)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Chess',
            style: AppTextStyles.serifHero.copyWith(
              color: palette.ink,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'version 0.1.0',
            style: AppTextStyles.caption.copyWith(color: palette.inkMute),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Svelte copy: concise one-liner description.
          Text(
            'A small, hand-crafted chess application built with care. '
            'Two boards, two piece sets, no telemetry, no clutter.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: palette.inkSoft),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Built with Flutter + Rust via flutter_rust_bridge. '
            'AI uses a custom minimax engine (levels 1–3) and Stockfish 17 (levels 4–10) '
            'where available.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: palette.inkMute, height: 1.55),
          ),
        ],
      ),
      actions: [
        // Svelte About.svelte uses variant="primary" for the close button.
        AppButton(
          label: 'Close',
          variant: AppButtonVariant.primary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
