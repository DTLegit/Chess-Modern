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
  const NewGameDialog({super.key});

  @override
  State<NewGameDialog> createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<NewGameDialog> {
  rust.GameMode _mode = rust.GameMode.hva;
  int _aiDifficulty = 3;
  rust.HumanColorChoice _humanColor = rust.HumanColorChoice.w;
  _TcPreset _tcPreset = _TcPreset.casual;
  late final TextEditingController _customMin = TextEditingController(text: '5');
  late final TextEditingController _customInc = TextEditingController(text: '0');

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
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).maybePop(null),
        ),
        AppButton(
          label: 'Start',
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
      return 'Casual';
    case 2:
    case 3:
      return 'Easy';
    case 4:
    case 5:
      return 'Medium';
    case 6:
    case 7:
      return 'Hard';
    case 8:
    case 9:
      return 'Expert';
    case 10:
      return 'Grandmaster';
    default:
      return '';
  }
}
