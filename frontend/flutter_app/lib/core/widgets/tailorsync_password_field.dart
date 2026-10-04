import 'package:flutter/material.dart';

import '../../ui/theme/app_theme.dart';
import '../../ui/theme/motion.dart';

/// Password field with a morphing visibility toggle.
class TailorSyncPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  const TailorSyncPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.autofillHints,
  });

  @override
  State<TailorSyncPasswordField> createState() => _TailorSyncPasswordFieldState();
}

class _TailorSyncPasswordFieldState extends State<TailorSyncPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscureText,
      validator: widget.validator,
      textInputAction: widget.textInputAction ?? TextInputAction.next,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints ?? const [AutofillHints.password],
      keyboardType: TextInputType.visiblePassword,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          tooltip: _obscureText ? 'Show password' : 'Hide password',
          onPressed: () => setState(() => _obscureText = !_obscureText),
          icon: AnimatedSwitcher(
            duration: Motion.of(context, Motion.short),
            transitionBuilder: (c, a) => RotationTransition(
              turns: Tween(begin: 0.75, end: 1.0).animate(a),
              child: FadeTransition(opacity: a, child: c),
            ),
            child: Icon(
              _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              key: ValueKey(_obscureText),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
