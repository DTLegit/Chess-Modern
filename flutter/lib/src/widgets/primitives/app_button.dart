import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// Variants from `legacy/svelte/lib/ui/Button.svelte`.
enum AppButtonVariant { primary, ghost, subtle, danger }

enum AppButtonSize { medium, small }

/// `MouseRegion` + `GestureDetector` wrapper that paints the Svelte button
/// look — gradient on primary, hairline border on ghost, accent tint on
/// hover, -1px translate on hover, opacity 0.5 when disabled.
///
/// Mirrors the Svelte `<Button>` component (see `lib/ui/Button.svelte`).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leading,
    this.trailing,
    this.fullWidth = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leading;
  final Widget? trailing;
  final bool fullWidth;
  final String? tooltip;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final v = widget.variant;
    final s = widget.size;

    final padH = s == AppButtonSize.small ? 12.0 : 16.0;
    final padV = s == AppButtonSize.small ? 7.0 : 10.0;
    final fontSize = s == AppButtonSize.small ? 12.0 : 13.0;

    final colors = _resolveColors(theme, v, hovered: _hovered, pressed: _pressed);

    final translateY = (_enabled && _hovered && !_pressed) ? -1.0 : 0.0;

    Widget content = DefaultTextStyle.merge(
      style: AppTextStyles.button.copyWith(
        color: colors.fg,
        fontSize: fontSize,
      ),
      child: IconTheme(
        data: IconThemeData(color: colors.fg, size: fontSize + 4),
        child: Row(
          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 6),
            ],
            Text(widget.label),
            if (widget.trailing != null) ...[
              const SizedBox(width: 6),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );

    Widget body = AnimatedContainer(
      duration: AppDurations.fast,
      curve: AppCurves.easeOut,
      transform: Matrix4.translationValues(0, translateY, 0),
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        gradient: colors.gradient,
        color: colors.gradient == null ? colors.bg : null,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: colors.borderColor == null
            ? null
            : Border.all(color: colors.borderColor!, width: 1),
        boxShadow: (_hovered && _enabled && v == AppButtonVariant.primary)
            ? theme.palette.shadowMd
            : (v == AppButtonVariant.primary ? theme.palette.shadowSm : null),
      ),
      child: content,
    );

    if (widget.fullWidth) {
      body = SizedBox(width: double.infinity, child: body);
    }

    final semantics = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: body,
    );

    return Opacity(
      opacity: _enabled ? 1.0 : 0.5,
      child: MouseRegion(
        cursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) {
          if (_enabled) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (_enabled) {
            setState(() {
              _hovered = false;
              _pressed = false;
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: _enabled
              ? (_) {
                  setState(() => _pressed = false);
                  widget.onPressed?.call();
                }
              : null,
          child: semantics,
        ),
      ),
    );
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.bg,
    required this.fg,
    this.borderColor,
    this.gradient,
  });
  final Color bg;
  final Color fg;
  final Color? borderColor;
  final Gradient? gradient;
}

_ButtonColors _resolveColors(
  AppThemeData theme,
  AppButtonVariant v, {
  required bool hovered,
  required bool pressed,
}) {
  final accent = theme.accent;
  final palette = theme.palette;

  switch (v) {
    case AppButtonVariant.primary:
      return _ButtonColors(
        bg: accent.mid,
        fg: accent.ink,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            hovered
                ? Color.lerp(accent.soft, accent.mid, 0.4)!
                : accent.mid,
            hovered
                ? Color.lerp(accent.mid, accent.base, 0.4)!
                : accent.base,
          ],
        ),
      );
    case AppButtonVariant.ghost:
      return _ButtonColors(
        bg: hovered ? palette.bgCard : palette.bgElev.withValues(alpha: 0.0),
        fg: palette.ink,
        borderColor: palette.hairlineStrong,
      );
    case AppButtonVariant.subtle:
      return _ButtonColors(
        bg: hovered
            ? Color.alphaBlend(accent.soft.withValues(alpha: 0.18), palette.bgElev)
            : palette.bgElev.withValues(alpha: 0.0),
        fg: hovered ? palette.ink : palette.inkSoft,
      );
    case AppButtonVariant.danger:
      return _ButtonColors(
        bg: hovered ? const Color(0xFFD06A5E) : appRedSoft,
        fg: const Color(0xFFFFFAEE),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            hovered ? const Color(0xFFD06A5E) : appRedSoft,
            const Color(0xFFA84A40),
          ],
        ),
      );
  }
}
