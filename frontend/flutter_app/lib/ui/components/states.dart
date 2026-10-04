import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'ts_button.dart';

/// Gently floating icon inside a soft halo – the illustration used by
/// empty / error states. Pure Flutter, so no asset downloads are needed.
class FloatingIllustration extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final double size;
  const FloatingIllustration({super.key, required this.icon, this.color, this.size = 112});

  @override
  State<FloatingIllustration> createState() => _FloatingIllustrationState();
}

class _FloatingIllustrationState extends State<FloatingIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
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
    final c = widget.color ?? cs.primary;
    final s = widget.size;
    return RepaintBoundary(
      child: SizedBox(
        width: s * 1.3,
        height: s * 1.3,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_c.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 0.92 + 0.08 * t,
                  child: Container(
                    width: s * 1.25,
                    height: s * 1.25,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.06)),
                  ),
                ),
                Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.10)),
                ),
                Transform.translate(
                  offset: Offset(0, -6 * t + 3),
                  child: Transform.rotate(
                    angle: (t - 0.5) * 0.12,
                    child: Icon(widget.icon, size: s * 0.46, color: c),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Friendly empty state with optional call-to-action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: EntranceFade(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingIllustration(icon: icon, size: context.isShortScreen ? 84 : 112),
                const SizedBox(height: Space.md),
                Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
                if (message != null) ...[
                  const SizedBox(height: Space.xs),
                  Text(message!, textAlign: TextAlign.center, style: context.text.bodyMedium),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: Space.lg),
                  TsButton(label: actionLabel!, icon: actionIcon, onPressed: onAction, expand: false),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error state with retry.
class ErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.title = 'Something went wrong', this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: title,
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      actionIcon: Icons.refresh_rounded,
      onAction: onRetry,
    );
  }
}

/// Animated check mark drawn stroke-by-stroke inside a filled circle,
/// with a small radial burst. Used for meaningful completions.
class SuccessCheck extends StatefulWidget {
  final double size;
  const SuccessCheck({super.key, this.size = 96});

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else if (_c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.status.success;
    return Semantics(
      label: 'Success',
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(painter: _CheckPainter(_c.value, color)),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double t;
  final Color color;
  _CheckPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final circleT = Curves.easeOutBack.transform((t / 0.45).clamp(0.0, 1.0));
    final checkT = Curves.easeOutCubic.transform(((t - 0.35) / 0.45).clamp(0.0, 1.0));
    final burstT = ((t - 0.4) / 0.6).clamp(0.0, 1.0);

    // Burst particles
    if (burstT > 0 && burstT < 1) {
      final p = Paint()..color = color.withValues(alpha: 1 - burstT);
      for (var i = 0; i < 10; i++) {
        final a = i * (math.pi * 2 / 10);
        final d = r * (0.85 + 0.45 * Curves.easeOut.transform(burstT));
        canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * d, r * 0.06 * (1 - burstT), p);
      }
    }

    canvas.drawCircle(c, r * 0.78 * circleT, Paint()..color = color);

    if (checkT > 0) {
      final path = Path()
        ..moveTo(c.dx - r * 0.32, c.dy + r * 0.02)
        ..lineTo(c.dx - r * 0.08, c.dy + r * 0.26)
        ..lineTo(c.dx + r * 0.36, c.dy - r * 0.22);
      final metric = path.computeMetrics().first;
      final partial = metric.extractPath(0, metric.length * checkT);
      canvas.drawPath(
        partial,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = r * 0.13,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.t != t || old.color != color;
}

/// Number that counts up from its previous value.
class AnimatedCount extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimals;

  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: Motion.of(context, const Duration(milliseconds: 700)),
      curve: Motion.emphasizedDecelerate,
      builder: (context, v, _) => Text(
        '$prefix${v.toStringAsFixed(decimals)}$suffix',
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

extension on BuildContext {
  bool get isShortScreen => MediaQuery.sizeOf(this).height < 640;
}
