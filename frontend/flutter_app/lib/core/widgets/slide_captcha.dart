import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/ui.dart';

/// Simple "Slide to verify" check (runs fully on-device, no setup needed).
/// The user drags the handle to the end; a too-fast, robotic swipe is rejected.
class SlideCaptcha extends StatefulWidget {
  final ValueChanged<bool> onChanged;
  final bool enabled;
  const SlideCaptcha({super.key, required this.onChanged, this.enabled = true});

  @override
  State<SlideCaptcha> createState() => _SlideCaptchaState();
}

class _SlideCaptchaState extends State<SlideCaptcha> with SingleTickerProviderStateMixin {
  static const double _height = 52;
  static const double _thumb = 44;

  double _pos = 0; // 0..1
  bool _verified = false;
  bool _dragging = false;
  DateTime? _dragStart;
  String? _hint;

  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..addListener(() => setState(() => _pos = _backFrom * (1 - _back.value)));
  double _backFrom = 0;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _onStart(DragStartDetails _) {
    if (_verified || !widget.enabled) return;
    _back.stop();
    _dragStart = DateTime.now();
    setState(() {
      _dragging = true;
      _hint = null;
    });
  }

  void _onUpdate(DragUpdateDetails d, double track) {
    if (_verified || !_dragging) return;
    setState(() => _pos = (_pos + d.delta.dx / track).clamp(0.0, 1.0));
  }

  void _onEnd(DragEndDetails _) {
    if (_verified || !_dragging) return;
    _dragging = false;
    final ms = DateTime.now().difference(_dragStart ?? DateTime.now()).inMilliseconds;
    if (_pos >= 0.95 && ms >= 250) {
      HapticFeedback.lightImpact();
      setState(() {
        _pos = 1;
        _verified = true;
      });
      widget.onChanged(true);
    } else {
      if (_pos >= 0.95) _hint = 'Whoa, that was quick! Try sliding a little slower.';
      _backFrom = _pos;
      _back.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final st = context.status;
    final accent = _verified ? st.success : cs.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, c) {
          final track = c.maxWidth - _thumb - 8;
          final left = 4 + track * _pos;
          return Container(
            height: _height,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(_height / 2),
              border: Border.all(color: _verified ? st.success.withValues(alpha: 0.6) : cs.outlineVariant),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // filled progress
                Container(
                  width: left + _thumb,
                  height: _height,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(_height / 2),
                  ),
                ),
                Center(
                  child: Text(
                    _verified ? 'All set, thanks!' : 'Slide to continue',
                    style: context.text.bodyMedium?.copyWith(
                      color: _verified ? st.success : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  left: left,
                  child: GestureDetector(
                    onHorizontalDragStart: _onStart,
                    onHorizontalDragUpdate: (d) => _onUpdate(d, track),
                    onHorizontalDragEnd: _onEnd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _thumb,
                      height: _thumb,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Icon(
                        _verified ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (_hint != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.xxs, left: Space.sm),
            child: Text(_hint!, style: context.text.bodySmall?.copyWith(color: st.danger)),
          ),
      ],
    );
  }
}
