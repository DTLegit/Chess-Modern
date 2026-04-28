import 'package:flutter/widgets.dart';

import '../../rust/api.dart' as rust;
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

class ClockPanel extends StatelessWidget {
  const ClockPanel({super.key, required this.game, required this.side});

  final GameController game;
  final rust.Color side;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final live = game.live;
        final clock = live?.clock;
        if (clock == null) return const SizedBox.shrink();
        final ms =
            (side == rust.Color.w ? clock.whiteMs : clock.blackMs).toInt();
        final active = clock.active == side && !clock.paused;
        final isLow = ms < 30000; // < 30s — red tint per Svelte Clock.svelte
        return _ClockBox(active: active, isLow: isLow, child: Text(_formatMs(ms)));
      },
    );
  }
}

class _ClockBox extends StatelessWidget {
  const _ClockBox({
    required this.active,
    required this.isLow,
    required this.child,
  });
  final bool active;
  final bool isLow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;

    Color textColor = palette.ink;
    if (isLow) textColor = appRedSoft;
    if (active && !isLow) textColor = accent.mid;

    BoxDecoration decoration;
    if (active) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgElev, palette.bgCard],
        ),
        border: Border.all(color: isLow ? appRedSoft : accent.soft, width: 1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: [
          BoxShadow(
            color: isLow
                ? const Color(0x38C25B4F) // accent_red glow
                : const Color(0x2EC2933B), // accent_mid glow
            blurRadius: 24,
          ),
        ],
      );
    } else {
      decoration = BoxDecoration(
        color: palette.bgElev,
        border: Border.all(color: palette.hairline, width: 1),
        borderRadius: BorderRadius.circular(AppRadii.md),
      );
    }

    return AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      decoration: decoration,
      child: DefaultTextStyle.merge(
        style: AppTextStyles.clock.copyWith(color: textColor),
        child: child,
      ),
    );
  }
}

String _formatMs(int ms) {
  if (ms < 0) ms = 0;
  final totalSeconds = ms ~/ 1000;
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  if (totalSeconds < 60) {
    final tenths = (ms ~/ 100) % 10;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.$tenths';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
