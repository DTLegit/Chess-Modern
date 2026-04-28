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
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.value;
        return AppDialog(
          title: 'Settings',
          width: 560,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLabel('Appearance'),
              const SizedBox(height: AppSpacing.sm),
              _AppThemeRow(controller: controller, value: s.appTheme),
              const SizedBox(height: AppSpacing.lg),
              const AppLabel('Accent color'),
              const SizedBox(height: AppSpacing.sm),
              _AccentRow(controller: controller, value: s.accent),
              const SizedBox(height: AppSpacing.lg),
              const AppLabel('Board theme'),
              const SizedBox(height: AppSpacing.sm),
              _BoardThemeGrid(controller: controller, value: s.boardTheme),
              const SizedBox(height: AppSpacing.huge),
              const AppLabel('Board hints'),
              const SizedBox(height: AppSpacing.xxs),
              AppListRow(
                title: 'Show legal moves',
                trailing: AppSwitch(
                  value: s.showLegalMoves,
                  onChanged: (v) =>
                      controller.update((c) => _copy(c, showLegalMoves: v)),
                ),
              ),
              AppListRow(
                title: 'Show coordinates',
                trailing: AppSwitch(
                  value: s.showCoordinates,
                  onChanged: (v) =>
                      controller.update((c) => _copy(c, showCoordinates: v)),
                ),
              ),
              AppListRow(
                title: 'Highlight last move',
                trailing: AppSwitch(
                  value: s.showLastMove,
                  onChanged: (v) =>
                      controller.update((c) => _copy(c, showLastMove: v)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppLabel('Sound'),
              const SizedBox(height: AppSpacing.xxs),
              AppListRow(
                title: 'Sound effects',
                trailing: AppSwitch(
                  value: s.soundEnabled,
                  onChanged: (v) =>
                      controller.update((c) => _copy(c, soundEnabled: v)),
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
                              controller.update((c) => _copy(c, soundVolume: v)),
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

class _BoardThemeGrid extends StatelessWidget {
  const _BoardThemeGrid({required this.controller, required this.value});
  final SettingsController controller;
  final rust.BoardTheme value;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final t in rust.BoardTheme.values)
          _BoardThemeCard(
            theme: t,
            selected: t == value,
            onTap: () => controller.update((c) => _copy(c, boardTheme: t)),
          ),
      ],
    );
  }
}

class _BoardThemeCard extends StatefulWidget {
  const _BoardThemeCard({
    required this.theme,
    required this.selected,
    required this.onTap,
  });
  final rust.BoardTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_BoardThemeCard> createState() => _BoardThemeCardState();
}

class _BoardThemeCardState extends State<_BoardThemeCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;
    final board = boardPaletteFor(widget.theme);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 130,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: palette.bgCard,
            border: Border.all(
              color: widget.selected
                  ? accent.mid
                  : (_hover ? palette.hairlineStrong : palette.hairline),
              width: widget.selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 4-square mini-board preview
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.tiny),
                child: AspectRatio(
                  aspectRatio: 2,
                  child: Row(
                    children: [
                      Expanded(child: ColoredBox(color: board.light)),
                      Expanded(child: ColoredBox(color: board.dark)),
                      Expanded(child: ColoredBox(color: board.dark)),
                      Expanded(child: ColoredBox(color: board.light)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _boardThemeLabel(widget.theme),
                style: AppTextStyles.caption.copyWith(
                  color: widget.selected ? accent.mid : palette.ink,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                ),
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

String _boardThemeLabel(rust.BoardTheme t) {
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
