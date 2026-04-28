import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

/// Card-equivalent surface. Mirrors Svelte `.panel` blocks
/// (`legacy/svelte/lib/panels/*.svelte`): `--c-bg-card` background,
/// 1px hairline border, 10px radius, optional shadow-sm.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevated = false,
    this.background,
    this.borderColor,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool elevated;
  final Color? background;
  final Color? borderColor;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background ?? palette.bgCard,
        border: Border.all(color: borderColor ?? palette.hairline, width: 1),
        borderRadius: BorderRadius.circular(radius ?? AppRadii.md),
        boxShadow: elevated ? palette.shadowSm : null,
      ),
      child: child,
    );
  }
}
