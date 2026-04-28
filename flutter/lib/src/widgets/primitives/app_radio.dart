import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

class AppRadio<T> extends StatelessWidget {
  const AppRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final accent = theme.accent;
    final palette = theme.palette;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: _selected,
      child: Opacity(
        opacity: onChanged == null ? 0.4 : 1.0,
        child: MouseRegion(
          cursor: onChanged == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChanged == null ? null : () => onChanged!(value),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: AppCurves.easeOut,
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: palette.bgElev,
                border: Border.all(
                  color: _selected ? accent.mid : palette.hairlineStrong,
                  width: 1,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  width: _selected ? 9 : 0,
                  height: _selected ? 9 : 0,
                  decoration: BoxDecoration(
                    color: accent.mid,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
