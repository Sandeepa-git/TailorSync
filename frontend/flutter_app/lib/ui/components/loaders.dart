import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Tailoring-themed loader: a needle travels around a ring, leaving a
/// dashed "stitch" trail behind it while a soft halo breathes underneath.
/// Indeterminate, 60fps-friendly (single painter in a RepaintBoundary),
/// and static (a calm full ring) when reduced motion is on.
class StitchLoader extends StatefulWidget {
  final double size;
  final Color color;
  final Color? trackColor;
  final Widget? center;

  const StitchLoader({
    super.key,
    this.size = 88,
    required this.color,
    this.trackColor,
    this.center,
  });

  @override
  State<StitchLoader> createState() => _StitchLoaderState();
}

class _StitchLoaderState extends State<StitchLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.value = 0.35;
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: _StitchPainter(
              anim: _c,
              color: widget.color,
              track: widget.trackColor ?? widget.color.withValues(alpha: 0.16),
            ),
            child: widget.center == null ? null : Center(child: widget.center),
          ),
        ),
      ),
    );
  }
}

class _StitchPainter extends CustomPainter {
  final Animation<double> anim;
  final Color color;
  final Color track;
  _StitchPainter({required this.anim, required this.color, required this.track}) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * 0.78;
    final stroke = size.shortestSide * 0.045;

    // Breathing halo.
    final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    canvas.drawCircle(
      c,
      r * (1.08 + 0.06 * breathe),
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.18 * (0.6 + 0.4 * breathe)), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r * 1.3)),
    );

    // Dotted track.
    final trackPaint = Paint()..color = track;
    const dots = 36;
    for (var i = 0; i < dots; i++) {
      final a = i / dots * 2 * math.pi;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(p, stroke * 0.3, trackPaint);
    }

    // Stitch trail: dashes that grow then shrink (classic material spinner
    // rhythm) but drawn as discrete stitches.
    final head = (t * 2 * math.pi * 1.0) - math.pi / 2;
    final sweepPhase = (t * 2) % 1.0;
    final sweep = (0.25 + 0.6 * Curves.easeInOut.transform(sweepPhase < 0.5 ? sweepPhase * 2 : (1 - sweepPhase) * 2)) * math.pi * 2;
    const stitchLen = 0.16; // radians
    const gap = 0.09;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: c, radius: r);
    var a = head - sweep;
    var k = 0;
    while (a < head - stitchLen * 0.5) {
      final fade = ((a - (head - sweep)) / sweep).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: 0.25 + 0.75 * fade);
      canvas.drawArc(rect, a, stitchLen, false, paint);
      a += stitchLen + gap;
      k++;
      if (k > 60) break;
    }

    // Needle at the head.
    final needlePos = c + Offset(math.cos(head), math.sin(head)) * r;
    final tangent = head + math.pi / 2;
    final needleLen = size.shortestSide * 0.16;
    final dir = Offset(math.cos(tangent), math.sin(tangent));
    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = stroke * 0.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(needlePos - dir * needleLen * 0.35, needlePos + dir * needleLen * 0.65, needlePaint);
    // Needle eye.
    canvas.drawCircle(
      needlePos - dir * needleLen * 0.25,
      stroke * 0.55,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(needlePos + dir * needleLen * 0.65, stroke * 0.35, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StitchPainter old) => old.color != color || old.track != track;
}
