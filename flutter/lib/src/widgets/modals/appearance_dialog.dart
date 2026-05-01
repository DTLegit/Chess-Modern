import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import '../../rust/api.dart' as rust;
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../primitives/app_button.dart';
import '../primitives/app_dialog.dart';
import '../primitives/app_label.dart';
import '../primitives/app_segmented.dart';

class AppearanceDialog extends StatefulWidget {
  const AppearanceDialog({
    super.key,
    required this.controller,
    this.showBoardTheme = true,
  });

  final SettingsController controller;
  final bool showBoardTheme;

  @override
  State<AppearanceDialog> createState() => _AppearanceDialogState();
}

enum _ThemeCategory { modern, casual, native }

class _AppearanceDialogState extends State<AppearanceDialog> {
  rust.BoardTheme? _hoverTheme;
  _ThemeCategory? _selectedCategory;
  rust.AppTheme? _lastSeenTheme;

  @override
  void initState() {
    super.initState();
    _updateCategoryFromTheme(widget.controller.value.appTheme);
  }

  void _updateCategoryFromTheme(rust.AppTheme theme) {
    _lastSeenTheme = theme;
    if (theme == rust.AppTheme.casualLight || theme == rust.AppTheme.casualDark) {
      _selectedCategory = _ThemeCategory.casual;
    } else if (theme == rust.AppTheme.liquidGlass || theme == rust.AppTheme.material) {
      _selectedCategory = _ThemeCategory.native;
    } else {
      _selectedCategory = _ThemeCategory.modern;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.value;
        
        // Ensure category matches external theme changes ONLY if theme actually changed
        if (_lastSeenTheme != s.appTheme) {
          // Wrap in a post-frame callback or just update local state before building
          _updateCategoryFromTheme(s.appTheme);
        }

        return AppDialog(
          title: 'Appearance',
          width: 520,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App Theme Category ───────────────────────────────────
              const AppLabel('Theme Style'),
              const SizedBox(height: 4),
              _SectionSubtitle(
                _selectedCategory == _ThemeCategory.modern
                    ? 'Default modern, flat, and polished theme.'
                    : _selectedCategory == _ThemeCategory.casual
                        ? 'Casual and relaxed look.'
                        : 'Theme and design to match the rest of your device.',
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSegmented<_ThemeCategory>(
                equalWidth: true,
                value: _selectedCategory!,
                onChanged: (c) => setState(() => _selectedCategory = c),
                options: const [
                  AppSegmentOption(value: _ThemeCategory.modern, label: 'Modern'),
                  AppSegmentOption(value: _ThemeCategory.casual, label: 'Casual'),
                  AppSegmentOption(value: _ThemeCategory.native, label: 'Native'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Sub-themes for the selected category ──────────────────
              if (_selectedCategory == _ThemeCategory.modern) ...[
                _AppThemeRow(
                  controller: widget.controller,
                  value: s.appTheme,
                  options: const [
                    AppSegmentOption(value: rust.AppTheme.light, label: 'Light'),
                    AppSegmentOption(value: rust.AppTheme.dark, label: 'Dark'),
                    AppSegmentOption(value: rust.AppTheme.black, label: 'Black'),
                  ],
                ),
              ] else if (_selectedCategory == _ThemeCategory.casual) ...[
                _AppThemeRow(
                  controller: widget.controller,
                  value: s.appTheme,
                  options: const [
                    AppSegmentOption(value: rust.AppTheme.casualLight, label: 'Casual Light'),
                    AppSegmentOption(value: rust.AppTheme.casualDark, label: 'Casual Dark'),
                  ],
                ),
              ] else ...[
                _AppThemeRow(
                  controller: widget.controller,
                  value: s.appTheme,
                  options: (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                      ? [
                          AppSegmentOption(
                            value: Platform.isAndroid ? rust.AppTheme.material : rust.AppTheme.liquidGlass,
                            label: 'Native',
                          )
                        ]
                      : const [
                          AppSegmentOption(value: rust.AppTheme.liquidGlass, label: 'Liquid Glass'),
                          AppSegmentOption(value: rust.AppTheme.material, label: 'Material'),
                        ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // ── Accent color ─────────────────────────────────────────
              const AppLabel('Accent color'),
              const SizedBox(height: 4),
              _SectionSubtitle('Used for buttons, highlights, and active states.'),
              const SizedBox(height: AppSpacing.sm),
              _AccentRow(controller: widget.controller, value: s.accent),
              const SizedBox(height: AppSpacing.lg),

              // ── Board theme ──────────────────────────────────────────
              if (widget.showBoardTheme) ...[
                const AppLabel('Board theme'),
                const SizedBox(height: 4),
                _SectionSubtitle('Choose the chess board appearance.'),
                const SizedBox(height: AppSpacing.sm),
                Center(child: _SettingsBoardPreview(boardTheme: _hoverTheme ?? s.boardTheme)),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: _SettingsBoardPicker(
                    value: s.boardTheme,
                    onChanged: (t) =>
                        widget.controller.update((c) => _copy(c, boardTheme: t)),
                    onHover: (t) => setState(() => _hoverTheme = t),
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

class _AppThemeRow extends StatelessWidget {
  const _AppThemeRow({
    required this.controller,
    required this.value,
    required this.options,
  });
  final SettingsController controller;
  final rust.AppTheme value;
  final List<AppSegmentOption<rust.AppTheme>> options;
  
  @override
  Widget build(BuildContext context) {
    // If the currently active theme is not in this row's options, don't pass value, 
    // or just let AppSegmented render nothing selected.
    final selectedValue = options.any((o) => o.value == value) ? value : null;
    
    return AppSegmented<rust.AppTheme?>(
      value: selectedValue,
      onChanged: (v) {
        if (v != null) controller.update((c) => _copy(c, appTheme: v));
      },
      options: options.map((o) => AppSegmentOption<rust.AppTheme?>(value: o.value, label: o.label)).toList(),
    );
  }
}

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