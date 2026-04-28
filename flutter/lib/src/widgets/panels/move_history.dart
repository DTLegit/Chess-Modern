import 'package:flutter/widgets.dart';

import '../../rust/api.dart' as rust;
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../primitives/app_divider.dart';

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
            child: _Empty(),
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
            padding: EdgeInsets.zero,
            itemCount: pairs.length,
            itemBuilder: (context, index) {
              final p = pairs[index];
              final stripe = index.isOdd;
              return _MoveRow(
                stripe: stripe,
                number: p.number,
                whiteSan: p.white.san,
                blackSan: p.black?.san,
                whiteActive: activeIndex == p.whiteIndex,
                blackActive: activeIndex == p.blackIndex,
                onWhiteTap: () => game.scrubTo(p.whiteIndex),
                onBlackTap: p.black == null ? null : () => game.scrubTo(p.blackIndex),
              );
            },
          ),
        );
      },
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({
    required this.stripe,
    required this.number,
    required this.whiteSan,
    required this.blackSan,
    required this.whiteActive,
    required this.blackActive,
    required this.onWhiteTap,
    required this.onBlackTap,
  });
  final bool stripe;
  final int number;
  final String whiteSan;
  final String? blackSan;
  final bool whiteActive;
  final bool blackActive;
  final VoidCallback onWhiteTap;
  final VoidCallback? onBlackTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;

    return Container(
      color: stripe
          ? Color.alphaBlend(accent.soft.withValues(alpha: 0.05), palette.bgCard)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$number.',
              textAlign: TextAlign.right,
              style: AppTextStyles.mono.copyWith(color: palette.inkMute),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _PlyChip(
              san: whiteSan,
              active: whiteActive,
              onTap: onWhiteTap,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: blackSan == null
                ? const SizedBox.shrink()
                : _PlyChip(
                    san: blackSan!,
                    active: blackActive,
                    onTap: onBlackTap!,
                  ),
          ),
        ],
      ),
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

class _PlyChip extends StatefulWidget {
  const _PlyChip({
    required this.san,
    required this.active,
    required this.onTap,
  });
  final String san;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_PlyChip> createState() => _PlyChipState();
}

class _PlyChipState extends State<_PlyChip> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;

    final fg = widget.active
        ? accent.ink
        : (_hovered ? palette.ink : palette.inkSoft);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: widget.active
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent.mid, accent.base],
                  )
                : null,
            color: widget.active
                ? null
                : (_hovered
                    ? Color.alphaBlend(
                        accent.soft.withValues(alpha: 0.18), palette.bgCard)
                    : null),
            borderRadius: BorderRadius.circular(AppRadii.tiny),
          ),
          child: Text(
            widget.san,
            style: AppTextStyles.mono.copyWith(color: fg, fontWeight: FontWeight.w600),
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
    final palette = AppTheme.of(context).palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.bgCard,
        border: Border.all(color: palette.hairline, width: 1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: palette.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md,
                AppSpacing.lg, AppSpacing.sm),
            child: Text(
              title,
              style: AppTextStyles.heading2.copyWith(color: palette.ink),
            ),
          ),
          const AppDivider(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context).palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'No moves yet',
          style: AppTextStyles.bodyMuted.copyWith(color: palette.inkMute),
        ),
      ),
    );
  }
}
