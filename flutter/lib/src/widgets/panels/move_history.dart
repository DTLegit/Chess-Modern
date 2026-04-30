import 'package:flutter/material.dart' show Tooltip;
import 'package:flutter/widgets.dart';

import '../../rust/api.dart' as rust;
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

class MoveHistoryPanel extends StatefulWidget {
  const MoveHistoryPanel({super.key, required this.game});

  final GameController game;

  @override
  State<MoveHistoryPanel> createState() => _MoveHistoryPanelState();
}

class _MoveHistoryPanelState extends State<MoveHistoryPanel> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.game.addListener(_onGameChanged);
  }

  @override
  void dispose() {
    widget.game.removeListener(_onGameChanged);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    // Auto-scroll to bottom when at the live position.
    if (widget.game.isAtLive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(game: widget.game),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.game,
              builder: (context, _) {
                final live = widget.game.live;
                if (live == null || live.history.isEmpty) {
                  return _Empty();
                }

                final pairs = <_PlyPair>[];
                for (var i = 0; i < live.history.length; i += 2) {
                  pairs.add(_PlyPair(
                    number: (i ~/ 2) + 1,
                    white: live.history[i],
                    black: i + 1 < live.history.length
                        ? live.history[i + 1]
                        : null,
                    whiteIndex: i + 1,
                    blackIndex: i + 2,
                  ));
                }
                final activeIndex =
                    widget.game.scrubIndex ?? widget.game.snapshots.length - 1;

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: pairs.length,
                  itemBuilder: (context, index) {
                    final p = pairs[index];
                    final isEven = index.isEven;
                    return _MoveRow(
                      isEven: isEven,
                      number: p.number,
                      whiteSan: p.white.san,
                      blackSan: p.black?.san,
                      whiteActive: activeIndex == p.whiteIndex,
                      blackActive: activeIndex == p.blackIndex,
                      onWhiteTap: () => widget.game.scrubTo(p.whiteIndex),
                      onBlackTap: p.black == null
                          ? null
                          : () => widget.game.scrubTo(p.blackIndex),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel header with title + scrub controls
// ---------------------------------------------------------------------------

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context).palette;
    final accent = AppTheme.of(context).accent;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgElev, palette.bgCard],
        ),
        border: Border(
          bottom: BorderSide(color: palette.hairline, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: 10),
      child: Row(
        children: [
          Text(
            'MOVES',
            style: TextStyle(
              fontFamily: AppFontFamilies.sans,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.54, // 0.14em
              color: palette.inkMute,
              height: 1.3,
            ),
          ),
          const Spacer(),
          // Scrub controls: ⏮ ◀ ▶ ⏭
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScrubBtn('⏮', 'Jump to start', () => game.scrubTo(0), palette, accent),
              const SizedBox(width: 2),
              _ScrubBtn('◀', 'Previous move', () => game.scrubStep(-1), palette, accent),
              const SizedBox(width: 2),
              _ScrubBtn('▶', 'Next move', () => game.scrubStep(1), palette, accent),
              const SizedBox(width: 2),
              _ScrubBtn('⏭', 'Jump to live', () => game.scrubLive(), palette, accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScrubBtn extends StatefulWidget {
  const _ScrubBtn(this.icon, this.tooltip, this.onTap, this.palette, this.accent);
  final String icon;
  final String tooltip;
  final VoidCallback onTap;
  final AppPalette palette;
  final AppAccent accent;

  @override
  State<_ScrubBtn> createState() => _ScrubBtnState();
}

class _ScrubBtnState extends State<_ScrubBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _hovered
                  ? Color.alphaBlend(
                      widget.accent.mid.withValues(alpha: 0.12),
                      widget.palette.bgCard)
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                widget.icon,
                style: TextStyle(
                  fontSize: 11,
                  color: _hovered ? widget.palette.ink : widget.palette.inkSoft,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Move row
// ---------------------------------------------------------------------------

class _MoveRow extends StatelessWidget {
  const _MoveRow({
    required this.isEven,
    required this.number,
    required this.whiteSan,
    required this.blackSan,
    required this.whiteActive,
    required this.blackActive,
    required this.onWhiteTap,
    required this.onBlackTap,
  });

  final bool isEven;
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
      decoration: BoxDecoration(
        color: isEven
            ? Color.alphaBlend(
                accent.mid.withValues(alpha: 0.05), palette.bgCard)
            : null,
        border: Border(
          bottom: BorderSide(
            color: Color.alphaBlend(
                accent.mid.withValues(alpha: 0.08), palette.hairline),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Move number
          SizedBox(
            width: 36,
            height: 32,
            child: Center(
              child: Text(
                '$number.',
                style: TextStyle(
                  fontFamily: AppFontFamilies.sans,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.inkFaint,
                  height: 1.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: _PlyChip(
              san: whiteSan,
              active: whiteActive,
              onTap: onWhiteTap,
            ),
          ),
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
        : (_hovered ? palette.ink : palette.ink);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                        accent.mid.withValues(alpha: 0.14), palette.bgCard)
                    : null),
            borderRadius: BorderRadius.circular(AppRadii.tiny),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: const Color(0x2E000000),
                      offset: const Offset(0, -2),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            widget.san,
            style: TextStyle(
              fontFamily: AppFontFamilies.sans,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fg,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context).palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'No moves yet. The game begins with white.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFontFamilies.sans,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: palette.inkMute,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
