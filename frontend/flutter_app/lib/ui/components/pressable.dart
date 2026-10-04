import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/motion.dart';

/// Wraps any child with a subtle press-down scale (0.97) and spring back.
/// Gestures pass through to the child's own InkWell etc. – this only listens.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;
  final bool enabled;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.haptic = false,
    this.enabled = true,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final scaled = AnimatedScale(
      scale: _down && !reduced ? widget.pressedScale : 1.0,
      duration: _down ? Motion.instant : Motion.short,
      curve: _down ? Motion.enter : Motion.spring,
      child: widget.child,
    );
    // When no tap handler is supplied we only observe pointer events so the
    // child's own buttons keep working.
    if (widget.onTap == null && widget.onLongPress == null) {
      return Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: scaled,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.enabled && widget.onTap != null
          ? () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: scaled,
    );
  }
}
