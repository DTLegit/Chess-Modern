import 'package:flutter/material.dart';

import '../../rust/api.dart' as rust;

class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.snapshot,
    required this.onNewGame,
    required this.onRematch,
  });

  final rust.GameSnapshot snapshot;
  final VoidCallback onNewGame;
  final void Function(rust.NewGameOpts) onRematch;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_resultTitle(snapshot.result)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_resultDetail(snapshot.status)),
            const SizedBox(height: 12),
            Text(
              '${snapshot.history.length} ${snapshot.history.length == 1 ? "move" : "moves"} '
              'played.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onNewGame();
          },
          child: const Text('New game…'),
        ),
        FilledButton(
          onPressed: snapshot.mode == rust.GameMode.hva &&
                  snapshot.aiDifficulty != null
              ? () {
                  Navigator.of(context).pop();
                  onRematch(rust.NewGameOpts(
                    mode: snapshot.mode,
                    aiDifficulty: snapshot.aiDifficulty,
                    humanColor: snapshot.humanColor == rust.Color.w
                        ? rust.HumanColorChoice.w
                        : rust.HumanColorChoice.b,
                    timeControl: null,
                  ));
                }
              : () {
                  Navigator.of(context).pop();
                  onRematch(rust.NewGameOpts(
                    mode: rust.GameMode.hvh,
                    timeControl: null,
                  ));
                },
          child: const Text('Rematch'),
        ),
      ],
    );
  }
}

String _resultTitle(rust.GameResult r) {
  switch (r) {
    case rust.GameResult.white:
      return 'White wins';
    case rust.GameResult.black:
      return 'Black wins';
    case rust.GameResult.draw:
      return 'Draw';
    case rust.GameResult.ongoing:
      return 'Game over';
  }
}

String _resultDetail(rust.GameStatus s) {
  switch (s) {
    case rust.GameStatus.checkmate:
      return 'Checkmate.';
    case rust.GameStatus.stalemate:
      return 'Stalemate.';
    case rust.GameStatus.drawFiftyMove:
      return 'Draw by the 50-move rule.';
    case rust.GameStatus.drawThreefold:
      return 'Draw by threefold repetition.';
    case rust.GameStatus.drawInsufficient:
      return 'Draw — insufficient material.';
    case rust.GameStatus.drawAgreement:
      return 'Draw by agreement.';
    case rust.GameStatus.resigned:
      return 'A player resigned.';
    case rust.GameStatus.timeForfeit:
      return 'Time forfeit.';
    case rust.GameStatus.active:
      return 'Game in progress.';
  }
}
