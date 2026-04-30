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
        final isLow = ms < 30000;
        return _ClockBox(
            active: active, isLow: isLow, child: Text(_formatMs(ms)));
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

    // Gold-soft color approximation for active ring.
    const goldSoft = Color(0xFFD4A84B);

    Color textColor = palette.ink;
    if (isLow) textColor = appRedSoft;
    if (active && !isLow) textColor = accent.mid;

    BoxDecoration decoration;
    if (active) {
      decoration = BoxDecoration(
        // Svelte: linear-gradient(180deg, #fffaef, var(--c-bg-elev))
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFFAEF), palette.bgElev],
        ),
        border: Border.all(
          color: isLow ? appRedSoft : goldSoft,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          // Ring effect: 0 0 0 1px goldSoft/redSoft
          BoxShadow(
            color: isLow ? appRedSoft : goldSoft,
            blurRadius: 0,
            spreadRadius: 1,
          ),
          // Blur glow behind
          BoxShadow(
            color: isLow
                ? const Color(0x38C25B4F)
                : const Color(0x2EC2933B),
            blurRadius: 24,
          ),
        ],
      );
    } else {
      decoration = BoxDecoration(
        color: palette.bgCard,
        border: Border.all(color: palette.hairline, width: 1),
        borderRadius: BorderRadius.circular(10),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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

/// Formats milliseconds to display string matching Clock.svelte:
/// - Under 1 minute:  "5.3"  (seconds + tenth, no minutes prefix)
/// - 1 min – 1 hour:  "m:ss"
/// - 1 hour+:          "h:mm:ss"
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
    // Svelte shows just "s.t" (e.g. "5.3") without zero-padded minutes.
    return '$s.$tenths';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}
