import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Slow-moving soft colour blobs on a brand gradient. Cheap: a single
/// CustomPainter in a RepaintBoundary, 20s loop, paused for reduced motion.
class AmbientBackground extends StatefulWidget {
  final Widget? child;
  final bool vivid; // true = dark brand gradient (splash), false = light tint
  const AmbientBackground({super.key, this.child, this.vivid = false});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 20));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
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
    final dark = context.isDark;
    final List<Color> base = widget.vivid
        ? (dark ? const [Color(0xFF12164A), Color(0xFF080A24)] : const [Color(0xFF283593), Color(0xFF141A63)])
        : [cs.surface, cs.surfaceContainerLow];
    final blobs = widget.vivid
        ? [const Color(0xFF5C6BC0), const Color(0xFF7C4DFF), const Color(0xFF3949AB)]
        : [cs.primary, cs.tertiary, cs.secondary];
    final alpha = widget.vivid ? 0.45 : (dark ? 0.16 : 0.10);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: base),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _BlobPainter(_c, blobs.map((c) => c.withValues(alpha: alpha)).toList()),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Animation<double> anim;
  final List<Color> colors;
  _BlobPainter(this.anim, this.colors) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value * 2 * math.pi;
    final s = size.shortestSide;
    final centers = [
      Offset(size.width * (0.15 + 0.10 * math.sin(t)), size.height * (0.18 + 0.05 * math.cos(t))),
      Offset(size.width * (0.90 + 0.08 * math.cos(t * 1.3)), size.height * (0.40 + 0.08 * math.sin(t))),
      Offset(size.width * (0.35 + 0.12 * math.cos(t)), size.height * (0.92 + 0.04 * math.sin(t * 0.7))),
    ];
    final radii = [s * 0.55, s * 0.50, s * 0.60];
    for (var i = 0; i < 3; i++) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [colors[i], colors[i].withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: centers[i], radius: radii[i]));
      canvas.drawCircle(centers[i], radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) => old.colors != colors;
}

/// Floating "back to top" button that fades/scales in after scrolling.
class ScrollToTopButton extends StatefulWidget {
  final ScrollController controller;
  final double showAfter;
  const ScrollToTopButton({super.key, required this.controller, this.showAfter = 600});

  @override
  State<ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<ScrollToTopButton> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listen);
  }

  void _listen() {
    if (!widget.controller.hasClients) return;
    final s = widget.controller.offset > widget.showAfter;
    if (s != _show) setState(() => _show = s);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_show,
      child: AnimatedScale(
        scale: _show ? 1 : 0.6,
        duration: Motion.of(context, Motion.short),
        curve: Motion.spring,
        child: AnimatedOpacity(
          opacity: _show ? 1 : 0,
          duration: Motion.of(context, Motion.short),
          child: FloatingActionButton.small(
            heroTag: null,
            tooltip: 'Scroll to top',
            backgroundColor: context.colors.surfaceContainerHighest,
            foregroundColor: context.colors.onSurface,
            onPressed: () => widget.controller.animateTo(
              0,
              duration: Motion.of(context, Motion.long),
              curve: Motion.emphasized,
            ),
            child: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
        ),
      ),
    );
  }
}
