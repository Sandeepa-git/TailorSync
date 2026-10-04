import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/ui.dart';

/// Simple "I'm not a robot" checkbox (runs on-device, no internet or keys).
/// Tap the box → short check animation → green tick.
class RobotCheck extends StatefulWidget {
  final ValueChanged<bool> onChanged;
  final bool enabled;
  const RobotCheck({super.key, required this.onChanged, this.enabled = true});

  @override
  State<RobotCheck> createState() => _RobotCheckState();
}

enum _State { idle, checking, done }

class _RobotCheckState extends State<RobotCheck> {
  _State _state = _State.idle;

  Future<void> _tap() async {
    if (!widget.enabled || _state != _State.idle) return;
    HapticFeedback.selectionClick();
    setState(() => _state = _State.checking);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _state = _State.done);
    widget.onChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final st = context.status;

    Widget box;
    switch (_state) {
      case _State.idle:
        box = Container(
          key: const ValueKey('idle'),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFFC1C1C1), width: 2),
          ),
        );
      case _State.checking:
        box = SizedBox(
          key: const ValueKey('checking'),
          width: 28,
          height: 28,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: CircularProgressIndicator(strokeWidth: 3, color: cs.primary),
          ),
        );
      case _State.done:
        box = Icon(Icons.check_rounded, key: const ValueKey('done'), color: st.success, size: 32);
    }

    return Material(
      color: const Color(0xFFF9F9F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Color(0xFFD3D3D3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: _state == _State.idle ? _tap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.md),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: box),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  'I\'m not a robot',
                  style: context.text.bodyLarge?.copyWith(color: const Color(0xFF222222)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security_rounded, color: cs.primary, size: 26),
                  const SizedBox(height: 2),
                  Text(
                    'Secure check',
                    style: context.text.labelSmall?.copyWith(fontSize: 9, color: const Color(0xFF555555)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
