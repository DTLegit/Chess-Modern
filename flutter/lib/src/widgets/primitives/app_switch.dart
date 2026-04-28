import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

/// Pill-style toggle. Mirrors Svelte switch styling in
/// `legacy/svelte/lib/modals/Settings.svelte` — accent track when on,
/// hairline track when off.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final accent = theme.accent;
    final palette = theme.palette;

    final trackColor = value ? accent.mid : palette.hairlineStrong;
    final thumbColor = value ? accent.ink : palette.bgElev;

    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: Opacity(
        opacity: onChanged == null ? 0.4 : 1.0,
        child: MouseRegion(
          cursor: onChanged == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChanged == null ? null : () => onChanged!(!value),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: AppCurves.easeOut,
              width: 38,
              height: 22,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x14000000),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: thumbColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x33000000),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
