import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

/// Page frame: bg + optional sticky topbar + body + optional statusbar.
/// Replaces Material `Scaffold`. Mirrors Svelte `App.svelte` shell layout.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.statusBar,
    this.floatingActionButton,
  });

  final Widget body;
  final Widget? topBar;
  final Widget? statusBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    return ColoredBox(
      color: palette.bg,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (topBar != null)
                  _TopBarFrame(child: topBar!),
                Expanded(child: body),
                if (statusBar != null)
                  _StatusBarFrame(child: statusBar!),
              ],
            ),
            if (floatingActionButton != null)
              Positioned(
                bottom: AppSpacing.bigGap,
                right: AppSpacing.bigGap,
                child: floatingActionButton!,
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBarFrame extends StatelessWidget {
  const _TopBarFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context).palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.bgSoft,
        border: Border(
          bottom: BorderSide(color: palette.hairline, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.bigGap,
        vertical: AppSpacing.md,
      ),
      child: child,
    );
  }
}

class _StatusBarFrame extends StatelessWidget {
  const _StatusBarFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context).palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.bgSoft,
        border: Border(
          top: BorderSide(color: palette.hairline, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.bigGap,
        vertical: AppSpacing.sm,
      ),
      child: child,
    );
  }
}
