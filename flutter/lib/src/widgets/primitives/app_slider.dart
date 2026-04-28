import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

/// Custom slider matching the Svelte range input — gradient track on the
/// filled portion, hairline track on the empty portion, custom round thumb.
class AppSlider extends StatefulWidget {
  const AppSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.semanticLabel,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? semanticLabel;

  @override
  State<AppSlider> createState() => _AppSliderState();
}

class _AppSliderState extends State<AppSlider> {
  bool _hovered = false;
  bool _dragging = false;

  double get _normalized {
    final range = widget.max - widget.min;
    if (range == 0) return 0;
    return ((widget.value - widget.min) / range).clamp(0.0, 1.0);
  }

  void _emit(double pos) {
    if (widget.onChanged == null) return;
    var v = widget.min + pos * (widget.max - widget.min);
    if (widget.divisions != null && widget.divisions! > 0) {
      final step = (widget.max - widget.min) / widget.divisions!;
      v = (v - widget.min) / step;
      v = v.roundToDouble();
      v = widget.min + v * step;
    }
    v = v.clamp(widget.min, widget.max).toDouble();
    if (v != widget.value) widget.onChanged!(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final accent = theme.accent;
    final palette = theme.palette;

    return Semantics(
      slider: true,
      value: widget.value.toStringAsFixed(2),
      label: widget.semanticLabel,
      child: Opacity(
        opacity: widget.onChanged == null ? 0.4 : 1.0,
        child: MouseRegion(
          cursor: widget.onChanged == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: SizedBox(
            height: 28,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final filled = w * _normalized;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: widget.onChanged == null
                      ? null
                      : (d) {
                          setState(() => _dragging = true);
                          _emit((d.localPosition.dx / w).clamp(0.0, 1.0));
                        },
                  onPanUpdate: widget.onChanged == null
                      ? null
                      : (d) =>
                          _emit((d.localPosition.dx / w).clamp(0.0, 1.0)),
                  onPanEnd: widget.onChanged == null
                      ? null
                      : (_) => setState(() => _dragging = false),
                  onTapDown: widget.onChanged == null
                      ? null
                      : (d) =>
                          _emit((d.localPosition.dx / w).clamp(0.0, 1.0)),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Track
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 9),
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.hairlineStrong,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Filled
                      Container(
                        margin: const EdgeInsets.only(left: 9),
                        width: (filled - 9).clamp(0.0, w - 18),
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent.soft, accent.mid],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Thumb
                      Positioned(
                        left: filled - 9,
                        child: AnimatedContainer(
                          duration: AppDurations.fast,
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: accent.mid,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.ink,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x33000000),
                                blurRadius: _hovered || _dragging ? 6 : 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
