import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';

/// 1px hairline divider in the current theme's hairline color.
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.height = 1,
    this.indent = 0,
    this.endIndent = 0,
  });
  final double height;
  final double indent;
  final double endIndent;
  @override
  Widget build(BuildContext context) {
    final color = AppTheme.of(context).palette.hairline;
    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: SizedBox(
        height: height,
        child: ColoredBox(color: color),
      ),
    );
  }
}
