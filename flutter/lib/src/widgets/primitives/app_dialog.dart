import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../rust/api.dart' as rust;
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import 'app_icon_button.dart';

/// Modal dialog frame matching `legacy/svelte/lib/ui/Modal.svelte`:
/// - Backdrop rgba(20,14,8,0.42), 2px blur (approx).
/// - Modal: `--c-bg-elev` bg, 14px radius, shadow-lg.
/// - Header: 18×22 padding, h2 serif title (22px, -0.012em).
/// - Footer: flex row gap 8, right-aligned actions.
/// - Pop-in: scale 0.98→1, translateY 6→0, fade. 180ms ease-out.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.width = 440,
    this.onClose,
    this.padBody = true,
    this.showCloseButton = true,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final double width;
  final VoidCallback? onClose;
  final bool padBody;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;

    final effectiveTitle = titleWidget ??
        (title != null
            ? Text(
                title!,
                style: AppTextStyles.serifTitle.copyWith(color: palette.ink),
              )
            : null);

    final bodyChild = padBody
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.bigGap,
              AppSpacing.sm,
              AppSpacing.bigGap,
              AppSpacing.huge,
            ),
            child: body,
          )
        : body;

    final isMobile = MediaQuery.of(context).size.width < 720;

    Widget dialogContent = Container(
      width: isMobile ? double.infinity : null,
      decoration: BoxDecoration(
        color: palette.bgElev,
        borderRadius: BorderRadius.circular(isMobile ? AppRadii.lg : AppRadii.xl),
        boxShadow: palette.shadowLg,
        border: Border.all(color: palette.hairline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (effectiveTitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.bigGap,
                AppSpacing.huge,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: effectiveTitle),
                  if (showCloseButton)
                    AppIconButton(
                      icon: const _XIcon(),
                      onPressed: onClose ??
                          () => Navigator.of(context).maybePop(),
                      tooltip: 'Close',
                      size: 28,
                      iconSize: 16,
                    ),
                ],
              ),
            ),
          Flexible(
            child: SingleChildScrollView(child: bodyChild),
          ),
          if (actions != null && actions!.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.bigGap,
                AppSpacing.lg,
                AppSpacing.bigGap,
                AppSpacing.huge,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: palette.hairline, width: 1),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: actions!,
              ),
            ),
        ],
      ),
    );

    if (theme.appTheme == rust.AppTheme.liquidGlass) {
      dialogContent = ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? AppRadii.lg : AppRadii.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: dialogContent,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 0.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: MediaQuery.of(context).size.height - 48,
          ),
          child: DefaultTextStyle.merge(
            style: AppTextStyles.body.copyWith(color: palette.ink),
            child: dialogContent,
          ),
        ),
      ),
    );
  }
}

/// Minimal × glyph used as the modal close icon.
class _XIcon extends StatelessWidget {
  const _XIcon();
  @override
  Widget build(BuildContext context) {
    final color = AppTheme.of(context).palette.inkMute;
    return CustomPaint(
      size: const Size(14, 14),
      painter: _XPainter(color),
    );
  }
}

class _XPainter extends CustomPainter {
  _XPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(2, 2), Offset(size.width - 2, size.height - 2), p);
    canvas.drawLine(Offset(size.width - 2, 2), Offset(2, size.height - 2), p);
  }

  @override
  bool shouldRepaint(covariant _XPainter old) => old.color != color;
}

/// Show a dialog with the Svelte modal animation. Drop-in for `showDialog`.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? const Color(0x6B140E08),
      barrierLabel: 'Dismiss',
      transitionDuration: AppDurations.base,
      reverseTransitionDuration: AppDurations.fast,
      pageBuilder: (ctx, anim, secondary) {
        return _DialogScrim(
          barrierDismissible: barrierDismissible,
          child: Builder(builder: builder),
        );
      },
      transitionsBuilder: (ctx, anim, secondary, child) {
        final curve = CurvedAnimation(parent: anim, curve: AppCurves.easeOut);
        final scale = Tween<double>(begin: 0.98, end: 1.0).animate(curve);
        final dy = Tween<double>(begin: 6, end: 0).animate(curve);
        return FadeTransition(
          opacity: curve,
          child: AnimatedBuilder(
            animation: curve,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, dy.value),
              child: Transform.scale(
                scale: scale.value,
                child: child,
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Centers the dialog and absorbs taps outside the dialog body for dismiss.
/// Applies a backdrop blur to the content behind the dialog.
class _DialogScrim extends StatelessWidget {
  const _DialogScrim({required this.child, this.barrierDismissible = true});
  final Widget child;
  final bool barrierDismissible;
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: GestureDetector(
        onTap: barrierDismissible
            ? () => Navigator.of(context).maybePop()
            : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageMargin),
          child: GestureDetector(
            // Absorb taps inside the dialog so they don't propagate to the scrim.
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: child,
          ),
        ),
      ),
    );
  }
}
