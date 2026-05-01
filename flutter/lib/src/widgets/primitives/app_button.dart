import 'package:flutter/material.dart' show Tooltip;
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

    final colors =
        _resolveColors(theme, v, hovered: _hovered, pressed: _pressed);

    final translateY = (_enabled && _hovered && !_pressed) ? -1.0 : 0.0;

    Widget content = DefaultTextStyle.merge(
      style: AppTextStyles.button.copyWith(
        color: colors.fg,
        fontSize: fontSize,
      ),
      child: IconTheme(
        data: IconThemeData(color: colors.fg, size: fontSize + 4),
        child:         Row(
          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              if (widget.label.isNotEmpty) const SizedBox(width: 6),
            ],
            if (widget.label.isNotEmpty) Text(widget.label),
            if (widget.trailing != null) ...[
              if (widget.label.isNotEmpty) const SizedBox(width: 6),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );

    final isFlat = theme.palette.shadowSm.isEmpty;

    // Primary button: add a subtle inset white highlight at the top edge
    // (approximates CSS inset 0 1px 0 rgba(255,255,255,0.2) inner sheen).
    if (v == AppButtonVariant.primary && !isFlat) {
      content = Stack(
        children: [
          content,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0x00FFFFFF),
                  const Color(0x33FFFFFF),
                  const Color(0x00FFFFFF),
                ]),
              ),
            ),
          ),
        ],
      );
    }

    Widget body = AnimatedScale(
      scale: (_pressed && _enabled) ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      child: AnimatedContainer(
      duration: AppDurations.fast,
      curve: AppCurves.easeOut,
      transform: Matrix4.translationValues(0, translateY, 0),
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        gradient: colors.gradient,
        color: colors.gradient == null ? colors.bg : null,
        borderRadius: BorderRadius.circular(isFlat ? AppRadii.pill : AppRadii.md),
        border: colors.borderColor == null
            ? null
            : Border.all(color: colors.borderColor!, width: 1),
        boxShadow: (_hovered && _enabled && v == AppButtonVariant.primary)
            ? theme.palette.shadowMd
            : (v == AppButtonVariant.primary ? theme.palette.shadowSm : null),
      ),
      child: content,
    ),
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

    Widget result = Opacity(
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

    if (widget.tooltip != null) {
      result = Tooltip(message: widget.tooltip!, child: result);
    }

    return result;
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
      final isFlat = theme.palette.shadowSm.isEmpty;
      return _ButtonColors(
        bg: isFlat ? (hovered ? accent.base : accent.mid) : accent.mid,
        fg: accent.ink,
        gradient: isFlat ? null : LinearGradient(
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
      // On hover: accent-tinted background + accent-tinted border.
      return _ButtonColors(
        bg: hovered
            ? Color.alphaBlend(
                accent.mid.withValues(alpha: 0.12), palette.bgCard)
            : const Color(0x00000000),
        fg: palette.ink,
        borderColor: hovered
            ? Color.alphaBlend(
                accent.mid.withValues(alpha: 0.40), palette.hairlineStrong)
            : palette.hairlineStrong,
      );

    case AppButtonVariant.subtle:
      return _ButtonColors(
        bg: hovered
            ? Color.alphaBlend(
                accent.soft.withValues(alpha: 0.18), palette.bgElev)
            : palette.bgElev.withValues(alpha: 0.0),
        fg: hovered ? palette.ink : palette.inkSoft,
      );

    // Danger: transparent bg + red border + red text; hover adds ~10% red fill.
    case AppButtonVariant.danger:
      return _ButtonColors(
        bg: hovered ? const Color(0x1AC25B4F) : const Color(0x00000000),
        fg: appRedSoft,
        borderColor: appRedSoft,
      );
  }
}
