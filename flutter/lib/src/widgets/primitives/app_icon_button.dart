import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

/// Square icon button — toolbar variant.
/// Mirrors the bare `<button>` icon usage in `legacy/svelte/App.svelte`
/// topbar (no chrome, hover background lifts to `--c-bg-card`).
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 32,
    this.iconSize = 18,
    this.tinted = false,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;

  /// When true, hover uses the soft accent tint instead of bg-card.
  final bool tinted;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _hovered = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;

    final hoverBg = widget.tinted
        ? Color.alphaBlend(accent.soft.withValues(alpha: 0.18), palette.bgElev)
        : palette.bgCard;

    Widget child = AnimatedContainer(
      duration: AppDurations.fast,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _hovered && _enabled ? hoverBg : palette.bgElev.withValues(alpha: 0.0),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Center(
        child: IconTheme(
          data: IconThemeData(
            color: _hovered && _enabled ? palette.ink : palette.inkSoft,
            size: widget.iconSize,
          ),
          child: widget.icon,
        ),
      ),
    );

    return Opacity(
      opacity: _enabled ? 1.0 : 0.4,
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: widget.tooltip,
        child: MouseRegion(
          cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) {
            if (_enabled) setState(() => _hovered = true);
          },
          onExit: (_) {
            if (_enabled) setState(() => _hovered = false);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            child: child,
          ),
        ),
      ),
    );
  }
}
