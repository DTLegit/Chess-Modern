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
import '../primitives/app_slider.dart';
import '../primitives/app_switch.dart';

/// Settings modal — mirrors `legacy/svelte/lib/modals/Settings.svelte`.
///
/// Appearance settings have been extracted to AppearanceDialog.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.controller,
  });

  final SettingsController controller;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
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
