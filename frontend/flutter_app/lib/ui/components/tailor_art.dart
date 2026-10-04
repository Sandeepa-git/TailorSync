import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Scissors drawing (shared by the loader and the Home watermark)
// ─────────────────────────────────────────────────────────────────────────────

/// Draws a pair of scissors with its pivot at [pivot], blades pointing along
/// +x. [length] is the full length (handle ring to blade tip) and [open] is
/// the opening angle in radians.
void paintScissors(Canvas canvas, Offset pivot, double length, double open, Color color) {
  final fill = Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;
  final ring = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = length * 0.045
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;
  final shank = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = length * 0.06
    ..strokeCap = StrokeCap.round;

  void half(double angle, double mirror) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.scale(length, length * mirror);
    // Blade: flat back, curved cutting edge, sharp tip.
    final blade = Path()
      ..moveTo(-0.03, -0.045)
      ..quadraticBezierTo(0.30, -0.055, 0.62, 0.004)
      ..quadraticBezierTo(0.32, 0.030, -0.03, 0.022)
      ..close();
    canvas.drawPath(blade, fill);
    // Shank down to the finger ring (drawn in unit space, so scale widths).
    canvas.drawLine(const Offset(-0.02, 0.0), const Offset(-0.20, 0.13),
        Paint()
          ..color = color
          ..strokeWidth = shank.strokeWidth / length
          ..strokeCap = StrokeCap.round);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-0.29, 0.19), width: 0.22, height: 0.17),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.strokeWidth / length,
    );
    canvas.restore();
  }

  half(-open / 2, 1);
  half(open / 2, -1);
  // Pivot screw.
  canvas.drawCircle(pivot, length * 0.035, fill);
  canvas.drawCircle(pivot, length * 0.014, Paint()..color = color.withValues(alpha: 0.35));
}

// ─────────────────────────────────────────────────────────────────────────────
// Scissor loader – replaces the spinning circle
// ─────────────────────────────────────────────────────────────────────────────

/// Scissors snipping along a dashed tailor's cut line. Indeterminate loader.
class ScissorLoader extends StatefulWidget {
  final double size; // width; height is ~half
  final Color? color;
  final String? label;
  const ScissorLoader({super.key, this.size = 120, this.color, this.label});

  @override
  State<ScissorLoader> createState() => _ScissorLoaderState();
}

class _ScissorLoaderState extends State<ScissorLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.value = 0.5;
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
    final color = widget.color ?? context.colors.primary;
    final loader = Semantics(
      label: 'Loading',
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size * 0.5,
          child: CustomPaint(painter: _CutPainter(_c, color)),
        ),
      ),
    );
    if (widget.label == null) return loader;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      loader,
      const SizedBox(height: Space.sm),
      Text(widget.label!, style: context.text.bodyMedium, textAlign: TextAlign.center),
    ]);
  }
}

class _CutPainter extends CustomPainter {
  final Animation<double> anim;
  final Color color;
  _CutPainter(this.anim, this.color) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final w = size.width, h = size.height;
    final y = h * 0.5;
    final start = w * 0.04, end = w * 0.96;
    final len = w * 0.44;
    // Ease the travel so the scissors glide, then fade + reset.
    final travel = Curves.easeInOut.transform(t);
    final pivotX = w * 0.20 + w * 0.42 * travel;
    final cutX = pivotX + len * 0.08;
    final fade = t < 0.1 ? t / 0.1 : (t > 0.9 ? (1 - t) / 0.1 : 1.0);
    final open = 0.08 + 0.55 * math.pow(math.sin(t * math.pi * 5).abs(), 1.4);

    // Uncut part: dashed line ahead of the blades.
    final dash = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = math.max(1.5, h * 0.035)
      ..strokeCap = StrokeCap.round;
    final step = w * 0.045;
    for (double x = cutX; x < end; x += step) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + step * 0.55, end), y), dash);
    }
    // Cut part: the fabric separates behind the scissors.
    if (cutX > start) {
      final gap = h * 0.06;
      final cut = Paint()
        ..color = color.withValues(alpha: 0.30 * fade + 0.1)
        ..strokeWidth = math.max(1.2, h * 0.028)
        ..strokeCap = StrokeCap.round;
      final top = Path()..moveTo(start, y - gap);
      final bottom = Path()..moveTo(start, y + gap);
      top.quadraticBezierTo((start + cutX) / 2, y - gap * 1.6, cutX, y);
      bottom.quadraticBezierTo((start + cutX) / 2, y + gap * 1.6, cutX, y);
      canvas.drawPath(top, cut..style = PaintingStyle.stroke);
      canvas.drawPath(bottom, cut);
    }
    paintScissors(canvas, Offset(pivotX, y), len, open.toDouble(), color.withValues(alpha: fade.clamp(0.0, 1.0).toDouble()));
  }

  @override
  bool shouldRepaint(covariant _CutPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Background watermarks – one tailoring accessory per main page
// ─────────────────────────────────────────────────────────────────────────────

enum TailorAccessory { scissors, hanger, tape, spool, button }

/// A large, faint, slowly-moving tailoring accessory behind a page's content.
class PageWatermark extends StatefulWidget {
  final TailorAccessory accessory;
  final bool left;
  const PageWatermark({super.key, required this.accessory, this.left = false});

  @override
  State<PageWatermark> createState() => _PageWatermarkState();
}

class _PageWatermarkState extends State<PageWatermark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 12));

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
    final cs = context.colors;
    final color = context.isDark ? const Color(0xFF8FA0FF) : cs.primary;
    final opacity = context.isDark ? 0.08 : 0.075;
    return LayoutBuilder(builder: (context, c) {
      final s = math.min(c.maxWidth * 0.78, 380.0);
      return Stack(children: [
        Positioned(
          top: c.maxHeight * 0.20,
          left: widget.left ? -s * 0.28 : null,
          right: widget.left ? null : -s * 0.28,
          width: s,
          height: s,
          child: IgnorePointer(
            child: RepaintBoundary(
              child: Opacity(
                opacity: opacity,
                child: CustomPaint(painter: _AccessoryPainter(_c, widget.accessory, color)),
              ),
            ),
          ),
        ),
      ]);
    });
  }
}

class _AccessoryPainter extends CustomPainter {
  final Animation<double> anim;
  final TailorAccessory kind;
  final Color color;
  _AccessoryPainter(this.anim, this.kind, this.color) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final t = anim.value;
    final wave = math.sin(t * 2 * math.pi);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    canvas.save();
    // Gentle float + sway for every accessory.
    canvas.translate(s / 2, s / 2 + wave * s * 0.02);
    canvas.rotate(wave * 0.05);
    canvas.translate(-s / 2, -s / 2);

    switch (kind) {
      case TailorAccessory.scissors:
        // Slow snip, tilted diagonally.
        canvas.save();
        canvas.translate(s * 0.5, s * 0.5);
        canvas.rotate(-math.pi / 5);
        final open = 0.12 + 0.30 * (0.5 + 0.5 * math.sin(t * 4 * math.pi));
        paintScissors(canvas, Offset(-s * 0.10, 0), s * 0.95, open, color);
        canvas.restore();
      case TailorAccessory.hanger:
        final hook = Path()
          ..addArc(Rect.fromCircle(center: Offset(s * 0.5, s * 0.16), radius: s * 0.07), math.pi, math.pi * 1.5);
        canvas.drawPath(hook, stroke);
        final body = Path()
          ..moveTo(s * 0.5, s * 0.23)
          ..lineTo(s * 0.5, s * 0.30)
          ..lineTo(s * 0.08, s * 0.60)
          ..quadraticBezierTo(s * 0.03, s * 0.66, s * 0.11, s * 0.66)
          ..lineTo(s * 0.89, s * 0.66)
          ..quadraticBezierTo(s * 0.97, s * 0.66, s * 0.92, s * 0.60)
          ..lineTo(s * 0.5, s * 0.30);
        canvas.drawPath(body, stroke);
        // A folded garment draped over the bar.
        final cloth = Path()
          ..moveTo(s * 0.30, s * 0.66)
          ..lineTo(s * 0.28, s * 0.90 + wave * s * 0.01)
          ..lineTo(s * 0.72, s * 0.90 - wave * s * 0.01)
          ..lineTo(s * 0.70, s * 0.66);
        canvas.drawPath(cloth, stroke..strokeWidth = s * 0.02);
      case TailorAccessory.tape:
        // Tape case.
        final cc = Offset(s * 0.32, s * 0.36);
        canvas.drawCircle(cc, s * 0.22, stroke);
        canvas.drawCircle(cc, s * 0.10, stroke..strokeWidth = s * 0.02);
        canvas.drawCircle(cc, s * 0.03, fill);
        // Ribbon flowing out with tick marks; the wave rolls slowly.
        Offset p(double u) => Offset(
              s * (0.50 + 0.44 * u),
              s * (0.50 + 0.36 * u + 0.06 * math.sin(2 * math.pi * (1.3 * u + t))),
            );
        final edgeA = Path(), edgeB = Path();
        const n = 60;
        for (var i = 0; i <= n; i++) {
          final u = i / n;
          final a = p(u), b = p(math.min(1.0, u + 0.01));
          final d = b - a;
          final norm = Offset(-d.dy, d.dx) / (d.distance == 0 ? 1 : d.distance);
          final o1 = a + norm * s * 0.045, o2 = a - norm * s * 0.045;
          if (i == 0) {
            edgeA.moveTo(o1.dx, o1.dy);
            edgeB.moveTo(o2.dx, o2.dy);
          } else {
            edgeA.lineTo(o1.dx, o1.dy);
            edgeB.lineTo(o2.dx, o2.dy);
          }
          if (i % 3 == 0 && i > 0) {
            final l = (i % 9 == 0) ? 0.05 : 0.028;
            canvas.drawLine(o1, o1 - norm * s * l, Paint()
              ..color = color
              ..strokeWidth = s * 0.008);
          }
        }
        stroke.strokeWidth = s * 0.018;
        canvas.drawPath(edgeA, stroke);
        canvas.drawPath(edgeB, stroke);
      case TailorAccessory.spool:
        final top = RRect.fromRectAndRadius(Rect.fromLTRB(s * 0.18, s * 0.12, s * 0.66, s * 0.21), Radius.circular(s * 0.03));
        final bottom = RRect.fromRectAndRadius(Rect.fromLTRB(s * 0.18, s * 0.79, s * 0.66, s * 0.88), Radius.circular(s * 0.03));
        canvas.drawRRect(top, stroke..strokeWidth = s * 0.025);
        canvas.drawRRect(bottom, stroke);
        canvas.drawRect(Rect.fromLTRB(s * 0.25, s * 0.21, s * 0.59, s * 0.79), stroke);
        // Wound thread.
        final thread = Paint()
          ..color = color
          ..strokeWidth = s * 0.01;
        for (var y = 0.25; y < 0.77; y += 0.04) {
          canvas.drawLine(Offset(s * 0.25, s * y), Offset(s * 0.59, s * (y + 0.025)), thread);
        }
        // Loose thread curling up to a needle that bobs.
        final bob = wave * s * 0.03;
        final eye = Offset(s * 0.84, s * 0.22 + bob);
        final loose = Path()
          ..moveTo(s * 0.59, s * 0.55)
          ..cubicTo(s * 0.80, s * 0.70, s * 0.95, s * 0.45, eye.dx, eye.dy + s * 0.02);
        canvas.drawPath(loose, Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012);
        canvas.drawLine(Offset(s * 0.84, s * 0.08 + bob), Offset(s * 0.84, s * 0.70 + bob), stroke..strokeWidth = s * 0.022);
      case TailorAccessory.button:
        canvas.save();
        canvas.translate(s / 2, s / 2);
        canvas.rotate(t * 2 * math.pi * 0.25);
        canvas.drawCircle(Offset.zero, s * 0.40, stroke..strokeWidth = s * 0.03);
        canvas.drawCircle(Offset.zero, s * 0.31, stroke..strokeWidth = s * 0.015);
        const holes = [Offset(-1, -1), Offset(1, -1), Offset(1, 1), Offset(-1, 1)];
        for (final hOff in holes) {
          canvas.drawCircle(hOff * s * 0.085, s * 0.045, stroke..strokeWidth = s * 0.018);
        }
        // Cross-stitched thread through the holes.
        final x = Paint()
          ..color = color
          ..strokeWidth = s * 0.022
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(holes[0] * s * 0.085, holes[2] * s * 0.085, x);
        canvas.drawLine(holes[1] * s * 0.085, holes[3] * s * 0.085, x);
        canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AccessoryPainter old) => old.kind != kind || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Blue page backdrop
// ─────────────────────────────────────────────────────────────────────────────

/// White-and-blue page background: a brand-blue wash at the top fading to
/// white, plus a soft indigo glow. Optional accessory watermark on top.
class PageBackdrop extends StatelessWidget {
  final TailorAccessory? watermark;
  final bool watermarkLeft;
  const PageBackdrop({super.key, this.watermark, this.watermarkLeft = false});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final cs = context.colors;
    return Stack(fit: StackFit.expand, children: [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.32, 0.75, 1.0],
            colors: dark
                ? [const Color(0xFF1C2366), const Color(0xFF141A44), cs.surface, cs.surface]
                : const [Color(0xFFCFD8FF), Color(0xFFE8EDFF), Color(0xFFF7F9FF), Colors.white],
          ),
        ),
      ),
      // Indigo glows top-right and bottom-left.
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.1, -1.0),
            radius: 0.9,
            colors: [const Color(0xFF3949AB).withValues(alpha: dark ? 0.35 : 0.22), Colors.transparent],
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-1.2, 1.0),
            radius: 0.8,
            colors: [const Color(0xFF5C6BC0).withValues(alpha: dark ? 0.18 : 0.10), Colors.transparent],
          ),
        ),
      ),
      if (watermark != null) PageWatermark(accessory: watermark!, left: watermarkLeft),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile avatar with a ring (gold for the business owner)
// ─────────────────────────────────────────────────────────────────────────────

class ProfileRingAvatar extends StatelessWidget {
  final String name;
  final bool isOwner;
  final double size;
  final VoidCallback? onTap;
  const ProfileRingAvatar({super.key, required this.name, this.isOwner = false, this.size = 46, this.onTap});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.length == 1 ? parts.first[0] : '${parts.first[0]}${parts.last[0]}').toUpperCase();
    final ring = isOwner
        ? const SweepGradient(colors: [
            Color(0xFFE2C27D), Color(0xFFF6E7C1), Color(0xFF3949AB), Color(0xFF1A237E), Color(0xFFE2C27D),
          ])
        : const SweepGradient(colors: [Color(0xFF5C6BC0), Color(0xFF9FA8DA), Color(0xFF1A237E), Color(0xFF5C6BC0)]);
    final ringW = size * 0.075;

    return Semantics(
      button: true,
      label: isOwner ? 'Profile, business owner' : 'Profile',
      child: Tooltip(
        message: isOwner ? 'Owner profile' : 'Profile',
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: size + 4,
            height: size + 4,
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: size,
                height: size,
                padding: EdgeInsets.all(ringW),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ring,
                  boxShadow: [
                    BoxShadow(
                      color: (isOwner ? const Color(0xFFE2C27D) : const Color(0xFF3949AB)).withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: ringW * 0.6),
                    gradient: Gradients.hero(context.colors),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.32),
                  ),
                ),
              ),
              if (isOwner)
                Positioned(
                  right: -2,
                  bottom: 0,
                  child: Container(
                    width: size * 0.40,
                    height: size * 0.40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE2C27D),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(Icons.workspace_premium_rounded, size: size * 0.26, color: const Color(0xFF1A237E)),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
