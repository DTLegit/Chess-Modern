import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/typography.dart';

/// Tiny uppercase label, 10px, 0.14em letter-spacing, ink-mute color.
/// Used as section headings inside dialogs in the Svelte UI.
class AppLabel extends StatelessWidget {
  const AppLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.label.copyWith(
        color: color ?? theme.palette.inkMute,
      ),
    );
  }
}
