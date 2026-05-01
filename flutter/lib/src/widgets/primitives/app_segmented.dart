import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

class AppSegmentOption<T> {
  const AppSegmentOption({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final Widget? icon;
}

/// Segmented selector — replaces SegmentedButton + ChoiceChip groups.
/// Mirrors Svelte segmented buttons (e.g. mode, color, time-control pills
/// in `legacy/svelte/lib/modals/NewGame.svelte`).
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.equalWidth = false,
    this.compact = false,
  });

  final List<AppSegmentOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;
  final bool equalWidth;

  /// When true, uses smaller padding for dense pill rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final isFlat = palette.shadowSm.isEmpty;

    Widget row = Row(
      mainAxisSize: equalWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (final opt in options)
          equalWidth
              ? Expanded(child: _segment(context, opt))
              : _segment(context, opt),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.bgCard,
        border: Border.all(color: palette.hairline),
        borderRadius: BorderRadius.circular(isFlat ? AppRadii.pill : AppRadii.md),
      ),
      child: equalWidth
          ? row
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: row,
            ),
    );
  }

  Widget _segment(BuildContext context, AppSegmentOption<T> opt) {
    return _Segment<T>(
      option: opt,
      selected: opt.value == value,
      onTap: onChanged == null ? null : () => onChanged!(opt.value),
      compact: compact,
    );
  }
}

class _Segment<T> extends StatefulWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.onTap,
    required this.compact,
  });
  final AppSegmentOption<T> option;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<_Segment<T>> createState() => _SegmentState<T>();
}

class _SegmentState<T> extends State<_Segment<T>> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;
    final isFlat = palette.shadowSm.isEmpty;

    final padH = widget.compact ? 10.0 : 14.0;
    final padV = widget.compact ? 6.0 : 8.0;

    final fg = widget.selected
        ? accent.ink
        : (_hovered ? palette.ink : palette.inkSoft);

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          decoration: BoxDecoration(
            gradient: (widget.selected && !isFlat)
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent.mid, accent.base],
                  )
                : null,
            color: widget.selected
                ? (isFlat ? accent.mid : null)
                : (_hovered
                    ? Color.alphaBlend(
                        accent.soft.withValues(alpha: 0.16), palette.bgCard)
                    : null),
            borderRadius: BorderRadius.circular(isFlat ? AppRadii.pill : AppRadii.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.option.icon != null) ...[
                IconTheme(
                  data: IconThemeData(color: fg, size: 14),
                  child: widget.option.icon!,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.option.label,
                  style: AppTextStyles.button.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
