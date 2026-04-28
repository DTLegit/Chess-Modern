import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// Settings/move-list row layout: leading area, title + optional subtitle,
/// trailing control. Mirrors Svelte settings rows
/// (`legacy/svelte/lib/modals/Settings.svelte`).
class AppListRow extends StatefulWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final bool selected;

  @override
  State<AppListRow> createState() => _AppListRowState();
}

class _AppListRowState extends State<AppListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;
    final padV = widget.dense ? 6.0 : 10.0;

    final bg = widget.selected
        ? Color.alphaBlend(accent.soft.withValues(alpha: 0.18), palette.bgCard)
        : (_hovered && widget.onTap != null
            ? Color.alphaBlend(palette.hairline, palette.bgElev)
            : null);

    Widget content = Container(
      color: bg,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: padV,
      ),
      child: Row(
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: AppSpacing.lg),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: AppTextStyles.body.copyWith(color: palette.ink),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: AppTextStyles.caption.copyWith(color: palette.inkMute),
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: AppSpacing.lg),
            widget.trailing!,
          ],
        ],
      ),
    );

    if (widget.onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: content,
      ),
    );
  }
}
