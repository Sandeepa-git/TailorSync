import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/ui.dart';

/// Lightweight "I'm not a robot" check: tap the box, then solve a small
/// addition. Runs fully on-device (no keys / network needed).
class SimpleCaptcha extends StatefulWidget {
  final ValueChanged<bool> onChanged;
  final bool enabled;
  const SimpleCaptcha({super.key, required this.onChanged, this.enabled = true});

  @override
  State<SimpleCaptcha> createState() => _SimpleCaptchaState();
}

enum _Stage { idle, challenge, verified }

class _SimpleCaptchaState extends State<SimpleCaptcha> {
  final _rng = Random.secure();
  final _answerCtrl = TextEditingController();
  final _focus = FocusNode();
  _Stage _stage = _Stage.idle;
  late int _a, _b;
  String? _error;
  int _wrongAttempts = 0;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _newQuestion() {
    _a = 2 + _rng.nextInt(9); // 2..10
    _b = 1 + _rng.nextInt(9); // 1..9
    _answerCtrl.clear();
  }

  void _start() {
    if (!widget.enabled || _stage != _Stage.idle) return;
    HapticFeedback.selectionClick();
    setState(() {
      _stage = _Stage.challenge;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _check() {
    final value = int.tryParse(_answerCtrl.text.trim());
    if (value == _a + _b) {
      HapticFeedback.lightImpact();
      FocusScope.of(context).unfocus();
      setState(() {
        _stage = _Stage.verified;
        _error = null;
        _wrongAttempts = 0;
      });
      widget.onChanged(true);
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _wrongAttempts++;
        _error = _wrongAttempts >= 3 ? 'Too many tries — here is a new one.' : 'Not quite, try again.';
        if (_wrongAttempts >= 3) {
          _wrongAttempts = 0;
          _newQuestion();
        } else {
          _answerCtrl.clear();
        }
      });
    }
  }

  void _refresh() {
    setState(() {
      _newQuestion();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final st = context.status;
    final verified = _stage == _Stage.verified;

    return AnimatedContainer(
      duration: Motion.of(context, Motion.medium),
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
      decoration: BoxDecoration(
        color: verified ? st.success.withValues(alpha: 0.08) : cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: Radii.brMd,
        border: Border.all(color: verified ? st.success.withValues(alpha: 0.6) : cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: Radii.brSm,
            onTap: _stage == _Stage.idle ? _start : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xxs),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.short),
                    child: verified
                        ? Icon(Icons.check_circle_rounded, key: const ValueKey('ok'), color: st.success, size: 30)
                        : Container(
                            key: const ValueKey('box'),
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: cs.outline, width: 2),
                            ),
                          ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      verified ? 'Verified — you\'re human!' : 'I\'m not a robot',
                      style: context.text.titleSmall,
                    ),
                  ),
                  Icon(Icons.verified_user_outlined, size: 22, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.medium),
            curve: Curves.easeOutCubic,
            child: _stage != _Stage.challenge
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Space.xs, bottom: Space.xxs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text('What is $_a + $_b ?', style: context.text.titleMedium),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: TextField(
                                controller: _answerCtrl,
                                focusNode: _focus,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _check(),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Answer',
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'New question',
                              icon: const Icon(Icons.refresh_rounded),
                              onPressed: _refresh,
                            ),
                            FilledButton(
                              onPressed: _check,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                                minimumSize: const Size(0, 40),
                              ),
                              child: const Text('Verify'),
                            ),
                          ],
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: Space.xxs),
                            child: Text(_error!, style: context.text.bodySmall?.copyWith(color: st.danger)),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
