import 'package:flutter/material.dart';

import '../../rust/api.dart' as rust;
import '../../state/game_controller.dart';
import '../board/piece_widget.dart';

const _values = {
  rust.PieceKind.q: 9,
  rust.PieceKind.r: 5,
  rust.PieceKind.b: 3,
  rust.PieceKind.n: 3,
  rust.PieceKind.p: 1,
};

class CapturesRow extends StatelessWidget {
  const CapturesRow({super.key, required this.game, required this.side});

  final GameController game;
  final rust.Color side;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final live = game.live;
        if (live == null) return const SizedBox.shrink();
        final captures = <rust.PieceKind, int>{};
        var whitePoints = 0;
        var blackPoints = 0;
        for (final mv in live.history) {
          final captured = mv.captured;
          if (captured == null) continue;
          if (captured.color == side) {
            captures.update(captured.kind, (v) => v + 1, ifAbsent: () => 1);
          }
          final v = _values[captured.kind] ?? 0;
          if (captured.color == rust.Color.b) {
            whitePoints += v;
          } else {
            blackPoints += v;
          }
        }
        final entries = captures.entries.toList()
          ..sort((a, b) => (_values[b.key] ?? 0).compareTo(_values[a.key] ?? 0));
        final myPoints = side == rust.Color.b ? whitePoints : blackPoints;
        final theirPoints = side == rust.Color.b ? blackPoints : whitePoints;
        final diff = theirPoints - myPoints;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in entries)
              for (var i = 0; i < entry.value; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: PieceWidget(
                      piece: rust.Piece(color: side, kind: entry.key),
                    ),
                  ),
                ),
            if (diff > 0) ...[
              const SizedBox(width: 4),
              Text(
                '+$diff',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }
}
