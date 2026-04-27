import 'package:flutter/material.dart';

import '../../rust/api.dart' as rust;
import '../../state/game_controller.dart';

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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _formatMs(ms),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      },
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
  if (totalSeconds < 20) {
    final tenths = (ms ~/ 100) % 10;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.$tenths';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
