import 'package:flutter/material.dart';

import '../../rust/api.dart' as rust;
import '../../state/game_controller.dart';

class MoveHistoryPanel extends StatelessWidget {
  const MoveHistoryPanel({super.key, required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final live = game.live;
        if (live == null || live.history.isEmpty) {
          return const _PanelShell(
            title: 'Moves',
            child: Center(child: Text('No moves yet')),
          );
        }
        final pairs = <_PlyPair>[];
        for (var i = 0; i < live.history.length; i += 2) {
          pairs.add(_PlyPair(
            number: (i ~/ 2) + 1,
            white: live.history[i],
            black: i + 1 < live.history.length ? live.history[i + 1] : null,
            whiteIndex: i + 1,
            blackIndex: i + 2,
          ));
        }
        final activeIndex = game.scrubIndex ?? game.snapshots.length - 1;
        return _PanelShell(
          title: 'Moves',
          child: ListView.builder(
            itemCount: pairs.length,
            itemBuilder: (context, index) {
              final p = pairs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${p.number}.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PlyButton(
                        san: p.white.san,
                        active: activeIndex == p.whiteIndex,
                        onTap: () => game.scrubTo(p.whiteIndex),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: p.black == null
                          ? const SizedBox.shrink()
                          : _PlyButton(
                              san: p.black!.san,
                              active: activeIndex == p.blackIndex,
                              onTap: () => game.scrubTo(p.blackIndex),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PlyPair {
  _PlyPair({
    required this.number,
    required this.white,
    required this.black,
    required this.whiteIndex,
    required this.blackIndex,
  });
  final int number;
  final rust.Move white;
  final rust.Move? black;
  final int whiteIndex;
  final int blackIndex;
}

class _PlyButton extends StatelessWidget {
  const _PlyButton({
    required this.san,
    required this.active,
    required this.onTap,
  });
  final String san;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          san,
          style: const TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
