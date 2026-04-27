import 'package:flutter/material.dart';

import '../../rust/api.dart' as rust;
import '../../state/settings_controller.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.value;
        return AlertDialog(
          title: const Text('Settings'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section(context, 'Appearance'),
                  _appThemeRow(context, s),
                  const SizedBox(height: 12),
                  _accentRow(context, s),
                  const SizedBox(height: 12),
                  _boardThemeRow(context, s),
                  const SizedBox(height: 16),
                  _section(context, 'Board'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show legal moves'),
                    value: s.showLegalMoves,
                    onChanged: (v) => controller
                        .update((cur) => _copy(cur, showLegalMoves: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show coordinates'),
                    value: s.showCoordinates,
                    onChanged: (v) => controller
                        .update((cur) => _copy(cur, showCoordinates: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Highlight last move'),
                    value: s.showLastMove,
                    onChanged: (v) => controller
                        .update((cur) => _copy(cur, showLastMove: v)),
                  ),
                  const SizedBox(height: 16),
                  _section(context, 'Audio'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sound effects'),
                    value: s.soundEnabled,
                    onChanged: (v) => controller
                        .update((cur) => _copy(cur, soundEnabled: v)),
                  ),
                  if (s.soundEnabled) ...[
                    Text('Volume: ${(s.soundVolume * 100).round()}%'),
                    Slider(
                      value: s.soundVolume,
                      onChanged: (v) => controller
                          .update((cur) => _copy(cur, soundVolume: v)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );

  Widget _appThemeRow(BuildContext context, rust.Settings s) {
    return Wrap(
      spacing: 8,
      children: [
        for (final t in rust.AppTheme.values)
          ChoiceChip(
            selected: s.appTheme == t,
            label: Text(_appThemeLabel(t)),
            onSelected: (_) =>
                controller.update((cur) => _copy(cur, appTheme: t)),
          ),
      ],
    );
  }

  Widget _accentRow(BuildContext context, rust.Settings s) {
    return Wrap(
      spacing: 8,
      children: [
        for (final a in rust.Accent.values)
          ChoiceChip(
            selected: s.accent == a,
            label: Text(_accentLabel(a)),
            onSelected: (_) =>
                controller.update((cur) => _copy(cur, accent: a)),
          ),
      ],
    );
  }

  Widget _boardThemeRow(BuildContext context, rust.Settings s) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final t in rust.BoardTheme.values)
          ChoiceChip(
            selected: s.boardTheme == t,
            label: Text(_boardThemeLabel(t)),
            onSelected: (_) =>
                controller.update((cur) => _copy(cur, boardTheme: t)),
          ),
      ],
    );
  }
}

String _appThemeLabel(rust.AppTheme t) {
  switch (t) {
    case rust.AppTheme.light:
      return 'Light';
    case rust.AppTheme.dark:
      return 'Dark';
    case rust.AppTheme.blue:
      return 'Blue';
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
