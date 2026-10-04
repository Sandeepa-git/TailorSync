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

/// Clean, professional indeterminate spinner: a gradient "comet" arc that
/// orbits a hairline track, its length easing in and out, with a softly
/// glowing head. Single painter, 60fps, static ring for reduced motion.
class OrbitLoader extends StatefulWidget {
  final double size;
  final Color color;
  final Color? highlight;
  final Color? trackColor;
  final double strokeWidth;

  const OrbitLoader({
    super.key,
    this.size = 44,
    required this.color,
    this.highlight,
    this.trackColor,
    this.strokeWidth = 3,
  });

  @override
  State<OrbitLoader> createState() => _OrbitLoaderState();
}

class _OrbitLoaderState extends State<OrbitLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.value = 0.25;
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
            painter: _OrbitPainter(
              anim: _c,
              color: widget.color,
              highlight: widget.highlight ?? widget.color,
              track: widget.trackColor ?? Colors.white.withValues(alpha: 0.10),
              stroke: widget.strokeWidth,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final Animation<double> anim;
  final Color color;
  final Color highlight;
  final Color track;
  final double stroke;
  _OrbitPainter({
    required this.anim,
    required this.color,
    required this.highlight,
    required this.track,
    required this.stroke,
  }) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final c = size.center(Offset.zero);
    final r = (size.shortestSide - stroke * 2) / 2;
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);

    // Hairline track.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.6,
    );

    // Arc length grows then shrinks (eased) while the whole thing rotates.
    final phase = t < 0.5 ? t * 2 : (1 - t) * 2;
    final len = (0.10 + 0.62 * Curves.easeInOutCubic.transform(phase)) * 2 * math.pi;
    const maxLen = 0.72 * 2 * math.pi;
    // While shrinking, the tail catches up to the head (Material rhythm).
    // Base speed chosen so the loop is seamless: 1.38 + 0.62 = 2 full turns.
    final rotation = t * 2 * math.pi * 1.38 + (t < 0.5 ? 0.0 : maxLen - len);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation - math.pi / 2);

    canvas.drawArc(
      rect,
      0,
      len,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          endAngle: len,
          colors: [color.withValues(alpha: 0), color, highlight],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(rect),
    );

    // Glowing head.
    final head = Offset(math.cos(len), math.sin(len)) * r;
    canvas.drawCircle(
      head,
      stroke * 1.6,
      Paint()
        ..color = highlight.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 1.2),
    );
    canvas.drawCircle(head, stroke * 0.62, Paint()..color = highlight);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) =>
      old.color != color || old.highlight != highlight || old.track != track || old.stroke != stroke;
}
