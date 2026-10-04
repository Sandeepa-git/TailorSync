import 'package:flutter/material.dart';

import '../../ui/theme/app_theme.dart';
import '../../ui/theme/motion.dart';

class TailorSyncPasswordRequirements extends StatelessWidget {
  final String password;

  const TailorSyncPasswordRequirements({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final hasLength = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$&*~]'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password requirements', style: context.text.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RequirementItem(label: '8+ characters', isMet: hasLength),
            _RequirementItem(label: 'Uppercase', isMet: hasUpper),
            _RequirementItem(label: 'Lowercase', isMet: hasLower),
            _RequirementItem(label: 'Number', isMet: hasNumber),
            _RequirementItem(label: 'Special character', isMet: hasSpecial),
          ],
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RequirementItem({required this.label, required this.isMet});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final color = isMet ? context.status.success : cs.onSurfaceVariant;
    return Semantics(
      label: '$label ${isMet ? 'met' : 'not met'}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.short),
        curve: Motion.standard,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isMet ? color.withValues(alpha: 0.12) : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: Motion.of(context, Motion.short),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                key: ValueKey(isMet),
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(label, style: context.text.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
