import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import 'app_button.dart';
import 'app_icons.dart';

/// A universal game shell layout for mobile.
/// Provides a top app bar, a drawer for global suite navigation,
/// a bottom navigation bar for in-game actions, and a central viewport.
class GameShell extends StatefulWidget {
  const GameShell({
    super.key,
    required this.title,
    required this.body,
    required this.drawerItemsBuilder,
    this.bottomBar,
    this.topBarTrailing,
  });

  final String title;
  final Widget body;
  final List<Widget> Function(VoidCallback closeDrawer) drawerItemsBuilder;
  final Widget? bottomBar;
  final Widget? topBarTrailing;

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> with SingleTickerProviderStateMixin {
  late final AnimationController _drawerController;
  late final Animation<Offset> _drawerSlide;
  bool _drawerVisible = false;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
    _drawerSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: AppCurves.easeOut,
    ));

    _drawerController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() => _drawerVisible = false);
      } else {
        if (!_drawerVisible) setState(() => _drawerVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_drawerController.isDismissed) {
      _drawerController.forward();
    } else {
      _drawerController.reverse();
    }
  }

  void _closeDrawer() {
    if (!_drawerController.isDismissed) {
      _drawerController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;

    final topBar = Row(
      children: [
        AppButton(
          label: '',
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.small,
          leading: const IconMenu(),
          onPressed: _toggleDrawer,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          widget.title,
          style: AppTextStyles.serifTitle.copyWith(
            fontSize: 18,
            color: palette.ink,
          ),
        ),
        const Spacer(),
        if (widget.topBarTrailing != null) widget.topBarTrailing!,
      ],
    );

    final bottomNav = widget.bottomBar;

    final scaffold = ColoredBox(
      color: palette.bg,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: palette.bgSoft,
                border: Border(bottom: BorderSide(color: palette.hairline, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: topBar,
            ),
            Expanded(child: widget.body),
            if (bottomNav != null) bottomNav,
          ],
        ),
      ),
    );

    return Stack(
      children: [
        scaffold,
        if (_drawerVisible) ...[
          GestureDetector(
            onTap: _closeDrawer,
            child: AnimatedBuilder(
              animation: _drawerController,
              builder: (context, _) => Container(
                color: const Color(0xFF000000).withValues(alpha: _drawerController.value * 0.4),
              ),
            ),
          ),
          SlideTransition(
            position: _drawerSlide,
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                color: palette.bgCard,
                border: Border(right: BorderSide(color: palette.hairline)),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Menu',
                            style: AppTextStyles.serifTitle.copyWith(fontSize: 18, color: palette.ink),
                          ),
                          AppButton(
                            label: '',
                            variant: AppButtonVariant.ghost,
                            size: AppButtonSize.small,
                            leading: const IconChevronLeft(),
                            onPressed: _closeDrawer,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...widget.drawerItemsBuilder(_closeDrawer).asMap().entries.map((entry) {
                      final index = entry.key;
                      final child = entry.value;
                      // Stagger delay maxes out at 0.5 to ensure it completes within the drawer's duration
                      final delay = (index * 0.1).clamp(0.0, 0.5);
                      final animation = CurvedAnimation(
                        parent: _drawerController,
                        curve: Interval(delay, 1.0, curve: AppCurves.easeOut),
                      );
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-0.1, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
