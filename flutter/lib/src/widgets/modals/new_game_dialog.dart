import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../rust/api.dart' as rust;
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../primitives/app_button.dart';
import '../primitives/app_dialog.dart';
import '../primitives/app_label.dart';
import '../primitives/app_segmented.dart';
import '../primitives/app_slider.dart';
import '../primitives/app_text_field.dart';

/// Time-control preset.
enum _TcPreset { casual, blitz3p2, b5, b10, b15p10, b30, custom }

/// New game setup. Mirrors `legacy/svelte/lib/modals/NewGame.svelte`.
class NewGameDialog extends StatefulWidget {
  const NewGameDialog({super.key, this.initialBoardTheme, this.canDismiss = true});
  final rust.BoardTheme? initialBoardTheme;
  /// When false, the Cancel button and close icon are hidden so the user
  /// must start a game (used on first launch when no game exists yet).
  final bool canDismiss;

  @override
  State<NewGameDialog> createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<NewGameDialog> {
  rust.GameMode _mode = rust.GameMode.hva;
  int _aiDifficulty = 3;
  rust.HumanColorChoice _humanColor = rust.HumanColorChoice.w;
  _TcPreset _tcPreset = _TcPreset.casual;
  late rust.BoardTheme _boardTheme;
  rust.BoardTheme? _hoverTheme;
  late final TextEditingController _customMin = TextEditingController(text: '5');
  late final TextEditingController _customInc = TextEditingController(text: '0');

  rust.BoardTheme get _previewTheme => _hoverTheme ?? _boardTheme;

  @override
  void initState() {
    super.initState();
    _boardTheme = widget.initialBoardTheme ?? rust.BoardTheme.wood;
  }

  @override
  void dispose() {
    _customMin.dispose();
    _customInc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;

    return AppDialog(
      title: 'New game',
      width: 540,
      showCloseButton: widget.canDismiss,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLabel('Mode'),
          const SizedBox(height: AppSpacing.sm),
          AppSegmented<rust.GameMode>(
            equalWidth: true,
            value: _mode,
            onChanged: (v) => setState(() => _mode = v),
            options: const [
              AppSegmentOption(value: rust.GameMode.hva, label: 'Human vs AI'),
              AppSegmentOption(
                  value: rust.GameMode.hvh, label: 'Human vs Human'),
            ],
          ),
          if (_mode == rust.GameMode.hva) ...[
            const SizedBox(height: AppSpacing.huge),
            const AppLabel('AI difficulty'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppSlider(
                    value: _aiDifficulty.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) =>
                        setState(() => _aiDifficulty = v.round()),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: 88,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_aiDifficulty',
                        style: AppTextStyles.serifTitle
                            .copyWith(color: theme.accent.mid),
                      ),
                      Text(
                        _aiLabel(_aiDifficulty),
                        style: AppTextStyles.caption
                            .copyWith(color: palette.inkMute),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.huge),
            const AppLabel('You play as'),
            const SizedBox(height: AppSpacing.sm),
            AppSegmented<rust.HumanColorChoice>(
              equalWidth: true,
              value: _humanColor,
              onChanged: (v) => setState(() => _humanColor = v),
              options: const [
                AppSegmentOption(
                    value: rust.HumanColorChoice.w, label: 'White'),
                AppSegmentOption(
                    value: rust.HumanColorChoice.random, label: 'Random'),
                AppSegmentOption(
                    value: rust.HumanColorChoice.b, label: 'Black'),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.huge),
          const AppLabel('Board theme'),
          const SizedBox(height: AppSpacing.sm),
          // Mini-board preview — updates on hover.
          Center(child: _NewGameBoardPreview(boardTheme: _previewTheme)),
          const SizedBox(height: AppSpacing.md),
          // 3-col swatch grid.
          Center(
            child: _BoardThemePicker(
              value: _boardTheme,
              onChanged: (t) => setState(() => _boardTheme = t),
              onHover: (t) => setState(() => _hoverTheme = t),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
          const AppLabel('Time control'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final p in _TcPreset.values)
                _TcChip(
                  label: _tcLabel(p),
                  selected: _tcPreset == p,
                  onTap: () => setState(() => _tcPreset = p),
                ),
            ],
          ),
          if (_tcPreset == _TcPreset.custom) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minutes',
                        style: AppTextStyles.caption
                            .copyWith(color: palette.inkMute),
                      ),
                      const SizedBox(height: 4),
                      AppTextField(
                        controller: _customMin,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Increment (s)',
                        style: AppTextStyles.caption
                            .copyWith(color: palette.inkMute),
                      ),
                      const SizedBox(height: 4),
                      AppTextField(
                        controller: _customInc,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (widget.canDismiss)
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).maybePop(null),
          ),
        AppButton(
          label: 'Start game',
          onPressed: () => Navigator.of(context).maybePop(_buildOpts()),
        ),
      ],
    );
  }

  rust.NewGameOpts _buildOpts() {
    final tc = _resolveTimeControl();
    return rust.NewGameOpts(
      mode: _mode,
      aiDifficulty: _mode == rust.GameMode.hva ? _aiDifficulty : null,
      humanColor: _mode == rust.GameMode.hva ? _humanColor : null,
      timeControl: tc,
    );
  }

  rust.TimeControl? _resolveTimeControl() {
    switch (_tcPreset) {
      case _TcPreset.casual:
        return null;
      case _TcPreset.blitz3p2:
        return _tc(3, 2);
      case _TcPreset.b5:
        return _tc(5, 0);
      case _TcPreset.b10:
        return _tc(10, 0);
      case _TcPreset.b15p10:
        return _tc(15, 10);
      case _TcPreset.b30:
        return _tc(30, 0);
      case _TcPreset.custom:
        final m = (int.tryParse(_customMin.text) ?? 5).clamp(1, 180);
        final i = (int.tryParse(_customInc.text) ?? 0).clamp(0, 60);
        return _tc(m, i);
    }
  }

  rust.TimeControl _tc(int minutes, int incSeconds) {
    return rust.TimeControl(
      initialMs: BigInt.from(minutes * 60 * 1000),
      incrementMs: BigInt.from(incSeconds * 1000),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini-board preview (new game)
// ---------------------------------------------------------------------------

class _NewGameBoardPreview extends StatelessWidget {
  const _NewGameBoardPreview({required this.boardTheme});
  final rust.BoardTheme boardTheme;

  @override
  Widget build(BuildContext context) {
    final board = boardPaletteFor(boardTheme);
    final bezel = boardBezelFor(boardTheme);
    final palette = AppTheme.of(context).palette;
    return AnimatedContainer(
      duration: AppDurations.fast,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bezel.topColor, bezel.bottomColor],
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: palette.shadowSm,
      ),
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.tiny),
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (_, constraints) {
              final cell = constraints.maxWidth / 8;
              return Stack(
                children: [
                  for (var row = 0; row < 8; row++)
                    for (var col = 0; col < 8; col++)
                      Positioned(
                        left: col * cell,
                        top: row * cell,
                        width: cell,
                        height: cell,
                        child: ColoredBox(
                          color: (row + col).isEven ? board.light : board.dark,
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Board theme picker (3-col grid)
// ---------------------------------------------------------------------------

class _BoardThemePicker extends StatelessWidget {
  const _BoardThemePicker({
    required this.value,
    required this.onChanged,
    required this.onHover,
  });
  final rust.BoardTheme value;
  final ValueChanged<rust.BoardTheme> onChanged;
  final ValueChanged<rust.BoardTheme?> onHover;

  @override
  Widget build(BuildContext context) {
    final themes = rust.BoardTheme.values;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final t in themes)
          _BoardThemeSwatch(
            theme: t,
            selected: t == value,
            onTap: () => onChanged(t),
            onHover: onHover,
          ),
      ],
    );
  }
}

class _BoardThemeSwatch extends StatefulWidget {
  const _BoardThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
    required this.onHover,
  });
  final rust.BoardTheme theme;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<rust.BoardTheme?> onHover;

  @override
  State<_BoardThemeSwatch> createState() => _BoardThemeSwatchState();
}

class _BoardThemeSwatchState extends State<_BoardThemeSwatch> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;
    final board = boardPaletteFor(widget.theme);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hover = true);
        widget.onHover(widget.theme);
      },
      onExit: (_) {
        setState(() => _hover = false);
        widget.onHover(null);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 110,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: palette.bgCard,
            border: Border.all(
              color: widget.selected
                  ? accent.mid
                  : (_hover ? palette.hairlineStrong : palette.hairline),
              width: widget.selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: accent.mid.withValues(alpha: 0.30),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 4-square checker pattern — CrossAxisAlignment.stretch needed
              // so ColoredBox fills the full height of each Expanded cell.
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.tiny),
                child: AspectRatio(
                  aspectRatio: 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: ColoredBox(color: board.light)),
                      Expanded(child: ColoredBox(color: board.dark)),
                      Expanded(child: ColoredBox(color: board.dark)),
                      Expanded(child: ColoredBox(color: board.light)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _boardThemeName(widget.theme),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: widget.selected ? accent.mid : palette.ink,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time-control chip
// ---------------------------------------------------------------------------

class _TcChip extends StatefulWidget {
  const _TcChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TcChip> createState() => _TcChipState();
}

class _TcChipState extends State<_TcChip> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;

    final fg = widget.selected
        ? accent.ink
        : (_hover ? palette.ink : palette.inkSoft);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 7),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent.mid, accent.base],
                  )
                : null,
            color: widget.selected
                ? null
                : (_hover
                    ? Color.alphaBlend(
                        accent.soft.withValues(alpha: 0.16), palette.bgCard)
                    : palette.bgCard),
            border: Border.all(
              color: widget.selected ? accent.mid : palette.hairline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.button.copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _tcLabel(_TcPreset p) {
  switch (p) {
    case _TcPreset.casual:
      return 'Casual';
    case _TcPreset.blitz3p2:
      return '3+2 Blitz';
    case _TcPreset.b5:
      return '5+0';
    case _TcPreset.b10:
      return '10+0';
    case _TcPreset.b15p10:
      return '15+10';
    case _TcPreset.b30:
      return '30+0';
    case _TcPreset.custom:
      return 'Custom';
  }
}

String _aiLabel(int n) {
  switch (n) {
    case 1:
      return 'Beginner';
    case 2:
      return 'Novice';
    case 3:
      return 'Easy';
    case 4:
      return 'Casual';
    case 5:
      return 'Intermediate';
    case 6:
      return 'Club';
    case 7:
      return 'Hard';
    case 8:
      return 'Expert';
    case 9:
      return 'Master';
    case 10:
      return 'Grandmaster';
    default:
      return '';
  }
}

String _boardThemeName(rust.BoardTheme t) {
  switch (t) {
    case rust.BoardTheme.wood:
      return 'Wood';
    case rust.BoardTheme.slate:
      return 'Slate';
    case rust.BoardTheme.woodRealistic:
      return 'Wood (realistic)';
    case rust.BoardTheme.slateRealistic:
      return 'Slate (realistic)';
    case rust.BoardTheme.marble:
      return 'Marble';
    case rust.BoardTheme.emerald:
      return 'Emerald';
    case rust.BoardTheme.obsidian:
      return 'Obsidian';
    case rust.BoardTheme.sandstone:
      return 'Sandstone';
    case rust.BoardTheme.midnight:
      return 'Midnight';
  }
}
