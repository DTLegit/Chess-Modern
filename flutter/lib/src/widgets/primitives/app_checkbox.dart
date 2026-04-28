import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;

    return Semantics(
      checked: value,
      child: Opacity(
        opacity: onChanged == null ? 0.4 : 1.0,
        child: MouseRegion(
          cursor: onChanged == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChanged == null ? null : () => onChanged!(!value),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: AppCurves.easeOut,
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? accent.mid : palette.bgElev,
                border: Border.all(
                  color: value ? accent.mid : palette.hairlineStrong,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(AppRadii.tiny),
              ),
              child: value
                  ? CustomPaint(
                      painter: _CheckPainter(color: accent.ink),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.72)
      ..lineTo(size.width * 0.78, size.height * 0.30);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.color != color;
}
