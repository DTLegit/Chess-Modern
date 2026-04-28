import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Minimal hand-rolled icon set. Replaces Material `Icons.*` for the handful
/// of glyphs the Flutter UI actually needs. Each icon paints itself via
/// `CustomPainter` with stroke-based geometry sized to the inherited
/// `IconTheme` size and color.

abstract class AppStrokeIcon extends StatelessWidget {
  const AppStrokeIcon({super.key, this.size, this.color, this.strokeWidth});
  final double? size;
  final Color? color;
  final double? strokeWidth;

  void paintIcon(Canvas canvas, Size size, Paint paint);

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 18;
    final c = color ?? theme.color ?? const Color(0xFF1F1A14);
    final sw = strokeWidth ?? (s / 12);
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(
        painter: _IconPainter(this, c, sw),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.color, this.strokeWidth);
  final AppStrokeIcon icon;
  final Color color;
  final double strokeWidth;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    icon.paintIcon(canvas, size, paint);
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.icon.runtimeType != icon.runtimeType;
}

class IconPlus extends AppStrokeIcon {
  const IconPlus({super.key, super.size, super.color, super.strokeWidth});
  @override
  void paintIcon(Canvas canvas, Size s, Paint p) {
    canvas.drawLine(Offset(s.width / 2, s.height * 0.18),
        Offset(s.width / 2, s.height * 0.82), p);
    canvas.drawLine(Offset(s.width * 0.18, s.height / 2),
        Offset(s.width * 0.82, s.height / 2), p);
  }
}

class IconUndo extends AppStrokeIcon {
  const IconUndo({super.key, super.size, super.color, super.strokeWidth});
  @override
  void paintIcon(Canvas canvas, Size s, Paint p) {
    final rect = Rect.fromLTWH(
      s.width * 0.12,
      s.height * 0.20,
      s.width * 0.76,
      s.height * 0.55,
    );
    final path = Path()..addArc(rect, math.pi, math.pi);
    path.lineTo(s.width * 0.88, s.height * 0.75);
    canvas.drawPath(path, p);
    canvas.drawLine(Offset(s.width * 0.18, s.height * 0.42),
        Offset(s.width * 0.12, s.height * 0.62), p);
    canvas.drawLine(Offset(s.width * 0.30, s.height * 0.50),
        Offset(s.width * 0.12, s.height * 0.62), p);
  }
}

class IconFlip extends AppStrokeIcon {
  const IconFlip({super.key, super.size, super.color, super.strokeWidth});
  @override
  void paintIcon(Canvas canvas, Size s, Paint p) {
    final cx = s.width / 2;
    canvas.drawLine(Offset(cx, s.height * 0.10), Offset(cx, s.height * 0.90), p);
    canvas.drawLine(Offset(s.width * 0.30, s.height * 0.30), Offset(cx, s.height * 0.10), p);
    canvas.drawLine(Offset(s.width * 0.70, s.height * 0.30), Offset(cx, s.height * 0.10), p);
    canvas.drawLine(Offset(s.width * 0.30, s.height * 0.70), Offset(cx, s.height * 0.90), p);
    canvas.drawLine(Offset(s.width * 0.70, s.height * 0.70), Offset(cx, s.height * 0.90), p);
  }
}

class IconFlag extends AppStrokeIcon {
  const IconFlag({super.key, super.size, super.color, super.strokeWidth});
  @override
  void paintIcon(Canvas canvas, Size s, Paint p) {
    canvas.drawLine(Offset(s.width * 0.25, s.height * 0.10),
        Offset(s.width * 0.25, s.height * 0.90), p);
    final flag = Path()
      ..moveTo(s.width * 0.25, s.height * 0.16)
      ..lineTo(s.width * 0.85, s.height * 0.22)
      ..lineTo(s.width * 0.65, s.height * 0.40)
      ..lineTo(s.width * 0.85, s.height * 0.58)
      ..lineTo(s.width * 0.25, s.height * 0.52)
      ..close();
    canvas.drawPath(flag, p);
  }
}

class IconChevronLeft extends AppStrokeIcon {
  const IconChevronLeft({super.key, super.size, super.color, super.strokeWidth});
  @override
  void paintIcon(Canvas canvas, Size s, Paint p) {
    final path = Path()
      ..moveTo(s.width * 0.65, s.height * 0.18)
      ..lineTo(s.width * 0.35, s.height * 0.50)
      ..lineTo(s.width * 0.65, s.height * 0.82);
    canvas.drawPath(path, p);
  }
}

class IconChevronRight extends AppStrokeIcon {
  const IconChevronRight({super.key, super.size, super.color, super.strokeWidth});
  @override
  void paintIcon(Canvas canvas, Size s, Paint p) {
    final path = Path()
      ..moveTo(s.width * 0.35, s.height * 0.18)
      ..lineTo(s.width * 0.65, s.height * 0.50)
      ..lineTo(s.width * 0.35, s.height * 0.82);
    canvas.drawPath(path, p);
  }
}

class IconLive extends AppStrokeIcon {
  const IconLive({super.key, super.size, super.color, super.strokeWidth});
  @override
  void paintIcon(Canvas canvas, Size s, Paint p) {
    final path1 = Path()
      ..moveTo(s.width * 0.30, s.height * 0.18)
      ..lineTo(s.width * 0.55, s.height * 0.50)
      ..lineTo(s.width * 0.30, s.height * 0.82);
    canvas.drawPath(path1, p);
    final path2 = Path()
      ..moveTo(s.width * 0.55, s.height * 0.18)
      ..lineTo(s.width * 0.80, s.height * 0.50)
      ..lineTo(s.width * 0.55, s.height * 0.82);
    canvas.drawPath(path2, p);
  }
}

class IconSettings extends AppStrokeIcon {
  const IconSettings({super.key, super.size, super.color, super.strokeWidth});
  @override
  void paintIcon(Canvas canvas, Size s, Paint p) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final innerR = s.width * 0.16;
    canvas.drawCircle(Offset(cx, cy), innerR, p);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final cos = math.cos(angle);
      final sin = math.sin(angle);
      final x1 = cx + (innerR + 1) * cos;
      final y1 = cy + (innerR + 1) * sin;
      final x2 = cx + (innerR + s.width * 0.18) * cos;
      final y2 = cy + (innerR + s.width * 0.18) * sin;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);
    }
  }
}

class IconInfo extends AppStrokeIcon {
  const IconInfo({super.key, super.size, super.color, super.strokeWidth});
  @override
  void paintIcon(Canvas canvas, Size s, Paint p) {
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * 0.40, p);
    canvas.drawLine(Offset(s.width / 2, s.height * 0.46),
        Offset(s.width / 2, s.height * 0.72), p);
    final dot = Paint()
      ..color = p.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(s.width / 2, s.height * 0.32), p.strokeWidth, dot);
  }
}

class IconUpload extends AppStrokeIcon {
  const IconUpload({super.key, super.size, super.color, super.strokeWidth});
  @override
  void paintIcon(Canvas canvas, Size s, Paint p) {
    canvas.drawLine(Offset(s.width / 2, s.height * 0.20),
        Offset(s.width / 2, s.height * 0.66), p);
    canvas.drawLine(Offset(s.width * 0.30, s.height * 0.40),
        Offset(s.width / 2, s.height * 0.20), p);
    canvas.drawLine(Offset(s.width * 0.70, s.height * 0.40),
        Offset(s.width / 2, s.height * 0.20), p);
    canvas.drawLine(Offset(s.width * 0.20, s.height * 0.84),
        Offset(s.width * 0.80, s.height * 0.84), p);
  }
}

class IconCopy extends AppStrokeIcon {
  const IconCopy({super.key, super.size, super.color, super.strokeWidth});
  @override
  void paintIcon(Canvas canvas, Size s, Paint p) {
    final r1 = Rect.fromLTWH(s.width * 0.20, s.height * 0.30,
        s.width * 0.50, s.height * 0.55);
    final r2 = Rect.fromLTWH(s.width * 0.30, s.height * 0.15,
        s.width * 0.50, s.height * 0.55);
    canvas.drawRRect(
        RRect.fromRectAndRadius(r1, const Radius.circular(2)), p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(r2, const Radius.circular(2)), p);
  }
}
