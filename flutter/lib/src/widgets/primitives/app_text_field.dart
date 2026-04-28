import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// Minimal numeric/text input. Used for Custom Time Control inputs.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.placeholder,
    this.width,
    this.suffix,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? placeholder;
  final double? width;
  final Widget? suffix;
  final TextAlign textAlign;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focused != _focus.hasFocus) {
        setState(() => _focused = _focus.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;

    return AnimatedContainer(
      duration: AppDurations.fast,
      width: widget.width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: palette.bgElev,
        border: Border.all(
          color: _focused ? accent.mid : palette.hairlineStrong,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (widget.placeholder != null &&
                    widget.controller.text.isEmpty)
                  Text(
                    widget.placeholder!,
                    style: AppTextStyles.body.copyWith(color: palette.inkFaint),
                  ),
                EditableText(
                  controller: widget.controller,
                  focusNode: _focus,
                  style: AppTextStyles.body.copyWith(color: palette.ink),
                  cursorColor: accent.mid,
                  backgroundCursorColor: palette.inkFaint,
                  onChanged: widget.onChanged,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  textAlign: widget.textAlign,
                  selectionColor: accent.soft.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          if (widget.suffix != null) ...[
            const SizedBox(width: AppSpacing.sm),
            DefaultTextStyle.merge(
              style: AppTextStyles.caption.copyWith(color: palette.inkMute),
              child: widget.suffix!,
            ),
          ],
        ],
      ),
    );
  }
}
