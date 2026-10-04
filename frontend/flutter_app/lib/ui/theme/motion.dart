import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared motion language. Every animation in the app pulls from here so
/// timing feels consistent and reduced-motion is honoured in one place.
abstract final class Motion {
  // Durations
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 400);
  static const Duration hero = Duration(milliseconds: 800);

  // Stagger for list/grid entrances (capped so long lists never feel slow).
  static const Duration staggerStep = Duration(milliseconds: 50);
  static const int staggerMaxItems = 8;

  // Curves
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve spring = Curves.easeOutBack;

  /// True when the OS asks for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns [d], or zero when reduced motion is on.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  /// Stagger delay for the item at [index].
  static Duration stagger(int index) =>
      staggerStep * (index < staggerMaxItems ? index : staggerMaxItems);
}

/// Fades + slides its child up once when first built. Cheap, implicit,
/// and respects reduced motion. Use for list items, cards and sections.
class EntranceFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY; // fraction of child height
  final double beginScale;

  const EntranceFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.long,
    this.offsetY = 0.08,
    this.beginScale = 1.0,
  });

  /// Convenience for staggered lists.
  factory EntranceFade.indexed(int index, {Key? key, required Widget child}) =>
      EntranceFade(key: key, delay: Motion.stagger(index), child: child);

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Motion.emphasizedDecelerate);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _c.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: FractionalTranslation(
            translation: Offset(0, widget.offsetY * (1 - v)),
            child: widget.beginScale == 1.0
                ? child
                : Transform.scale(scale: widget.beginScale + (1 - widget.beginScale) * v, child: child),
          ),
        );
      },
    );
  }
}

/// A one-shot horizontal shake, triggered by changing [trigger].
class ShakeOnChange extends StatefulWidget {
  final Object? trigger;
  final Widget child;
  const ShakeOnChange({super.key, required this.trigger, required this.child});

  @override
  State<ShakeOnChange> createState() => _ShakeOnChangeState();
}

class _ShakeOnChangeState extends State<ShakeOnChange> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(covariant ShakeOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger != null && !Motion.reduced(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        // Damped sine: 3 oscillations, fading out.
        final dx = (1 - t) * 0.025 * math.sin(t * 3 * 2 * math.pi);
        return FractionalTranslation(translation: Offset(dx, 0), child: child);
      },
    );
  }
}
