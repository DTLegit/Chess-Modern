import 'package:flutter/widgets.dart';

import '../../rust/api.dart' as rust;
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../primitives/app_button.dart';
import '../primitives/app_dialog.dart';
import '../primitives/app_label.dart';
import '../primitives/app_list_row.dart';
import '../primitives/app_segmented.dart';
import '../primitives/app_slider.dart';
import '../primitives/app_switch.dart';

/// Settings modal — mirrors `legacy/svelte/lib/modals/Settings.svelte`.
///
/// Changes from original Flutter port:
/// - Stateful to track hovered board theme for live preview.
/// - Board preview is a live 8×8 mini-board above the swatch grid.
/// - Section label "Appearance" → "App theme".
/// - Descriptive subtitles per section (matching Svelte copy).
/// - Swatch `_BoardThemeCard` selection shows accent-colored glow BoxShadow.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.controller,
    this.showBoardTheme = true,
  });

  final SettingsController controller;
  /// When false, the board theme section is hidden. Set to false when opening
  /// settings from the welcome screen, since board theme is already available
  /// in the New Game dialog.
  final bool showBoardTheme;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  rust.BoardTheme? _hoverTheme;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.value;
        return AppDialog(
          title: 'Settings',
          width: 520,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App theme ──────────────────────────────────────────────
              const AppLabel('App theme'),
              const SizedBox(height: 4),
              _SectionSubtitle('Choose the overall color palette of the app.'),
              const SizedBox(height: AppSpacing.sm),
              _AppThemeRow(controller: widget.controller, value: s.appTheme),
              const SizedBox(height: AppSpacing.lg),

              // ── Accent color ─────────────────────────────────────────
              const AppLabel('Accent color'),
              const SizedBox(height: 4),
              _SectionSubtitle('Used for buttons, highlights, and active states.'),
              const SizedBox(height: AppSpacing.sm),
              _AccentRow(controller: widget.controller, value: s.accent),
              const SizedBox(height: AppSpacing.lg),

              // ── Board theme (hidden when opened from welcome screen) ───
              if (widget.showBoardTheme) ...[
                const AppLabel('Board theme'),
                const SizedBox(height: 4),
                _SectionSubtitle('Choose the chess board appearance.'),
                const SizedBox(height: AppSpacing.sm),
                _SettingsBoardPreview(boardTheme: _hoverTheme ?? s.boardTheme),
                const SizedBox(height: AppSpacing.md),
                _SettingsBoardPicker(
                  value: s.boardTheme,
                  onChanged: (t) =>
                      widget.controller.update((c) => _copy(c, boardTheme: t)),
                  onHover: (t) => setState(() => _hoverTheme = t),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Board hints ──────────────────────────────────────────
              const AppLabel('Board hints'),
              const SizedBox(height: 4),
              _SectionSubtitle('Visual helpers shown during play.'),
              const SizedBox(height: AppSpacing.xxs),
              AppListRow(
                title: 'Show legal moves',
                trailing: AppSwitch(
                  value: s.showLegalMoves,
                  onChanged: (v) =>
                      widget.controller.update((c) => _copy(c, showLegalMoves: v)),
                ),
              ),
              AppListRow(
                title: 'Show coordinates',
                trailing: AppSwitch(
                  value: s.showCoordinates,
                  onChanged: (v) =>
                      widget.controller.update((c) => _copy(c, showCoordinates: v)),
                ),
              ),
              AppListRow(
                title: 'Highlight last move',
                trailing: AppSwitch(
                  value: s.showLastMove,
                  onChanged: (v) =>
                      widget.controller.update((c) => _copy(c, showLastMove: v)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Sound ────────────────────────────────────────────────
              const AppLabel('Sound'),
              const SizedBox(height: 4),
              _SectionSubtitle('Audio feedback for moves and game events.'),
              const SizedBox(height: AppSpacing.xxs),
              AppListRow(
                title: 'Sound effects',
                trailing: AppSwitch(
                  value: s.soundEnabled,
                  onChanged: (v) =>
                      widget.controller.update((c) => _copy(c, soundEnabled: v)),
                ),
              ),
              if (s.soundEnabled) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Volume',
                          style: AppTextStyles.body
                              .copyWith(color: AppTheme.of(context).palette.ink),
                        ),
                      ),
                      Expanded(
                        child: AppSlider(
                          value: s.soundVolume,
                          divisions: 20,
                          onChanged: (v) =>
                              widget.controller.update((c) => _copy(c, soundVolume: v)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${(s.soundVolume * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.mono.copyWith(
                              color: AppTheme.of(context).palette.inkMute),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            AppButton(
              label: 'Close',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        );
      },
    );
  }
}

class _SectionSubtitle extends StatelessWidget {
  const _SectionSubtitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context).palette;
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(color: palette.inkMute),
    );
  }
}

// ---------------------------------------------------------------------------
// App theme row
// ---------------------------------------------------------------------------

class _AppThemeRow extends StatelessWidget {
  const _AppThemeRow({required this.controller, required this.value});
  final SettingsController controller;
  final rust.AppTheme value;
  @override
  Widget build(BuildContext context) {
    return AppSegmented<rust.AppTheme>(
      value: value,
      onChanged: (v) => controller.update((c) => _copy(c, appTheme: v)),
      options: const [
        AppSegmentOption(value: rust.AppTheme.light, label: 'Light'),
        AppSegmentOption(value: rust.AppTheme.dark, label: 'Dark'),
        AppSegmentOption(value: rust.AppTheme.blue, label: 'Blue'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Accent color row
// ---------------------------------------------------------------------------

class _AccentRow extends StatelessWidget {
  const _AccentRow({required this.controller, required this.value});
  final SettingsController controller;
  final rust.Accent value;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final a in rust.Accent.values)
          _AccentSwatch(
            accent: a,
            selected: a == value,
            onTap: () => controller.update((c) => _copy(c, accent: a)),
          ),
      ],
    );
  }
}

class _AccentSwatch extends StatefulWidget {
  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });
  final rust.Accent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AccentSwatch> createState() => _AccentSwatchState();
}

class _AccentSwatchState extends State<_AccentSwatch> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accentColors = accentFor(widget.accent);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: widget.selected
                ? Color.alphaBlend(
                    accentColors.soft.withValues(alpha: 0.18), palette.bgCard)
                : palette.bgCard,
            border: Border.all(
              color: widget.selected
                  ? accentColors.mid
                  : (_hover ? palette.hairlineStrong : palette.hairline),
              width: widget.selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: accentColors.mid.withValues(alpha: 0.30),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accentColors.soft, accentColors.mid],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.hairline, width: 1),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _accentLabel(widget.accent),
                style: AppTextStyles.button.copyWith(color: palette.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Label helpers
// ---------------------------------------------------------------------------

String _accentLabel(rust.Accent a) {
  switch (a) {
    case rust.Accent.walnut:
      return 'Walnut';
    case rust.Accent.forest:
      return 'Forest';
    case rust.Accent.violet:
      return 'Violet';
    case rust.Accent.teal:
      return 'Teal';
    case rust.Accent.rose:
      return 'Rose';
  }
}

// ---------------------------------------------------------------------------
// Board theme preview + picker (settings version)
// ---------------------------------------------------------------------------

class _SettingsBoardPreview extends StatelessWidget {
  const _SettingsBoardPreview({required this.boardTheme});
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
                          color:
                              (row + col).isEven ? board.light : board.dark,
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

class _SettingsBoardPicker extends StatelessWidget {
  const _SettingsBoardPicker({
    required this.value,
    required this.onChanged,
    required this.onHover,
  });
  final rust.BoardTheme value;
  final ValueChanged<rust.BoardTheme> onChanged;
  final ValueChanged<rust.BoardTheme?> onHover;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final t in rust.BoardTheme.values)
          _SettingsBoardThemeSwatch(
            theme: t,
            selected: t == value,
            onTap: () => onChanged(t),
            onHover: onHover,
          ),
      ],
    );
  }
}

class _SettingsBoardThemeSwatch extends StatefulWidget {
  const _SettingsBoardThemeSwatch({
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
  State<_SettingsBoardThemeSwatch> createState() =>
      _SettingsBoardThemeSwatchState();
}

class _SettingsBoardThemeSwatchState
    extends State<_SettingsBoardThemeSwatch> {
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
                _settingsBoardThemeName(widget.theme),
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

String _settingsBoardThemeName(rust.BoardTheme t) {
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

// ---------------------------------------------------------------------------
// Settings copy helper
// ---------------------------------------------------------------------------

rust.Settings _copy(
  rust.Settings s, {
  rust.AppTheme? appTheme,
  rust.BoardTheme? boardTheme,
  rust.Accent? accent,
  bool? soundEnabled,
  double? soundVolume,
  bool? showLegalMoves,
  bool? showCoordinates,
  bool? showLastMove,
}) {
  return rust.Settings(
    appTheme: appTheme ?? s.appTheme,
    boardTheme: boardTheme ?? s.boardTheme,
    pieceSet: rust.PieceSet.merida,
    accent: accent ?? s.accent,
    soundEnabled: soundEnabled ?? s.soundEnabled,
    soundVolume: soundVolume ?? s.soundVolume,
    showLegalMoves: showLegalMoves ?? s.showLegalMoves,
    showCoordinates: showCoordinates ?? s.showCoordinates,
    showLastMove: showLastMove ?? s.showLastMove,
  );
}
