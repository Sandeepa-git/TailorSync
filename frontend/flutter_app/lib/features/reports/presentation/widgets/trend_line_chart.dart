import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';

/// Validated categorical series colours (light surface): blue, orange, aqua.
const kSeriesBlue = Color(0xFF2A78D6);
const kSeriesOrange = Color(0xFFEB6834);
const kSeriesAqua = Color(0xFF1BAF7A);

class ChartSeries {
  final String name;
  final Color color;
  final List<double> values;
  const ChartSeries(this.name, this.color, this.values);
}

/// Lightweight line chart (no package needed): recessive grid, 2px lines,
/// legend for 2+ series, and a touch crosshair + tooltip with exact values.
class TrendLineChart extends StatefulWidget {
  final List<String> labels;
  final List<ChartSeries> series;
  final String Function(double v) format;
  final double height;
  final bool fillFirst;

  const TrendLineChart({
    super.key,
    required this.labels,
    required this.series,
    required this.format,
    this.height = 190,
    this.fillFirst = false,
  });

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int? _sel;
  static const _leftPad = 40.0, _bottomPad = 22.0, _topPad = 8.0, _rightPad = 8.0;

  double get _maxY {
    final m = widget.series.expand((s) => s.values).fold<double>(0, math.max);
    return _niceMax(m <= 0 ? 1 : m);
  }

  static double _niceMax(double v) {
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final f in [1, 2, 2.5, 5, 10]) {
      if (f * mag >= v) return f * mag;
    }
    return 10 * mag;
  }

  void _pick(Offset p, double width) {
    final n = widget.labels.length;
    if (n == 0) return;
    final plotW = width - _leftPad - _rightPad;
    final x = (p.dx - _leftPad).clamp(0, plotW);
    final i = n == 1 ? 0 : (x / plotW * (n - 1)).round();
    setState(() => _sel = i.clamp(0, n - 1));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final n = widget.labels.length;
    final empty = n == 0 || widget.series.every((s) => s.values.every((v) => v == 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.series.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Wrap(
              spacing: Space.md,
              runSpacing: Space.xxs,
              children: [
                for (final s in widget.series)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 14, height: 3, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text(s.name, style: context.text.bodySmall?.copyWith(color: cs.onSurface)),
                  ]),
              ],
            ),
          ),
        SizedBox(
          height: widget.height,
          child: empty
              ? Center(child: Text('No data for this period', style: context.text.bodySmall))
              : LayoutBuilder(builder: (context, c) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _pick(d.localPosition, c.maxWidth),
                    onHorizontalDragUpdate: (d) => _pick(d.localPosition, c.maxWidth),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ChartPainter(
                              labels: widget.labels,
                              series: widget.series,
                              maxY: _maxY,
                              format: widget.format,
                              selected: _sel,
                              fillFirst: widget.fillFirst,
                              grid: cs.outlineVariant.withValues(alpha: 0.5),
                              axisText: context.text.labelSmall!.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
                              surface: cs.surface,
                              pad: const EdgeInsets.fromLTRB(_leftPad, _topPad, _rightPad, _bottomPad),
                            ),
                          ),
                        ),
                        if (_sel != null) _tooltip(context, c.maxWidth),
                      ],
                    ),
                  );
                }),
        ),
      ],
    );
  }

  Widget _tooltip(BuildContext context, double width) {
    final i = _sel!;
    final n = widget.labels.length;
    final plotW = width - _leftPad - _rightPad;
    final x = _leftPad + (n == 1 ? plotW / 2 : plotW * i / (n - 1));
    const tipW = 132.0;
    final left = (x + 10 + tipW > width) ? x - tipW - 10 : x + 10;
    return Positioned(
      left: left.clamp(0, math.max(0, width - tipW)),
      top: 0,
      width: tipW,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: context.colors.inverseSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.labels[i], style: context.text.labelSmall?.copyWith(color: context.colors.onInverseSurface)),
              for (final s in widget.series)
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelSmall?.copyWith(color: context.colors.onInverseSurface)),
                  ),
                  Text(widget.format(i < s.values.length ? s.values[i] : 0),
                      style: context.text.labelSmall?.copyWith(
                          color: context.colors.onInverseSurface, fontWeight: FontWeight.w700)),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<String> labels;
  final List<ChartSeries> series;
  final double maxY;
  final String Function(double) format;
  final int? selected;
  final bool fillFirst;
  final Color grid, surface;
  final TextStyle axisText;
  final EdgeInsets pad;

  _ChartPainter({
    required this.labels,
    required this.series,
    required this.maxY,
    required this.format,
    required this.selected,
    required this.fillFirst,
    required this.grid,
    required this.axisText,
    required this.surface,
    required this.pad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(pad.left, pad.top, size.width - pad.right, size.height - pad.bottom);
    final n = labels.length;
    double xOf(int i) => n == 1 ? plot.center.dx : plot.left + plot.width * i / (n - 1);
    double yOf(double v) => plot.bottom - (v / maxY) * plot.height;

    // grid + y labels (4 steps)
    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final v = maxY * k / 4;
      final y = yOf(v);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gp);
      _text(canvas, format(v), Offset(plot.left - 6, y), alignRight: true);
    }
    // x labels (at most ~5)
    final step = math.max(1, (n / 5).ceil());
    for (var i = 0; i < n; i += step) {
      _text(canvas, labels[i], Offset(xOf(i), plot.bottom + 4), center: true);
    }

    // series
    for (var si = 0; si < series.length; si++) {
      final s = series[si];
      if (s.values.isEmpty) continue;
      final path = Path();
      for (var i = 0; i < s.values.length && i < n; i++) {
        final o = Offset(xOf(i), yOf(s.values[i]));
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      if (si == 0 && fillFirst && n > 1) {
        final area = Path.from(path)
          ..lineTo(xOf(math.min(s.values.length, n) - 1), plot.bottom)
          ..lineTo(xOf(0), plot.bottom)
          ..close();
        canvas.drawPath(area, Paint()..color = s.color.withValues(alpha: 0.10));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      if (n <= 16 || n == 1) {
        for (var i = 0; i < s.values.length && i < n; i++) {
          canvas.drawCircle(Offset(xOf(i), yOf(s.values[i])), 3, Paint()..color = s.color);
        }
      }
    }

    // crosshair
    if (selected != null && selected! < n) {
      final x = xOf(selected!);
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), Paint()
        ..color = grid.withValues(alpha: 1)
        ..strokeWidth = 1);
      for (final s in series) {
        if (selected! >= s.values.length) continue;
        final o = Offset(x, yOf(s.values[selected!]));
        canvas.drawCircle(o, 6, Paint()..color = surface);
        canvas.drawCircle(o, 4.5, Paint()..color = s.color);
      }
    }
  }

  void _text(Canvas canvas, String t, Offset at, {bool alignRight = false, bool center = false}) {
    final tp = TextPainter(text: TextSpan(text: t, style: axisText), textDirection: TextDirection.ltr, maxLines: 1)
      ..layout(maxWidth: 60);
    var dx = at.dx;
    var dy = at.dy;
    if (alignRight) {
      dx -= tp.width;
      dy -= tp.height / 2;
    } else if (center) {
      dx -= tp.width / 2;
    }
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.selected != selected || old.series != series || old.labels != labels || old.maxY != maxY;
}
