import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ts_card.dart';

/// Visual mapping for order stages and priorities. Pure presentation:
/// it only looks at the strings the backend already returns.
abstract final class StageStyle {
  static const stages = [
    'Order Received',
    'Cutting',
    'Sewing',
    'Fitting',
    'Quality Check',
    'Ready',
    'Delivered',
  ];

  static Color color(BuildContext context, String? status) {
    final s = context.status;
    final cs = context.colors;
    switch (status) {
      case 'Order Received':
        return cs.primary;
      case 'Cutting':
        return context.isDark ? const Color(0xFFFF9E9E) : const Color(0xFFC62828);
      case 'Sewing':
        return s.warning;
      case 'Fitting':
        return context.isDark ? const Color(0xFFD7B2F0) : const Color(0xFF7B2FA6);
      case 'Quality Check':
        return context.isDark ? const Color(0xFF7FDCCF) : const Color(0xFF00796B);
      case 'Ready':
        return s.success;
      case 'Delivered':
        return cs.onSurfaceVariant;
      default:
        return cs.primary;
    }
  }

  static IconData icon(String? status) {
    switch (status) {
      case 'Order Received':
        return Icons.inventory_2_outlined;
      case 'Cutting':
        return Icons.content_cut_rounded;
      case 'Sewing':
        return Icons.gesture_rounded;
      case 'Fitting':
        return Icons.accessibility_new_rounded;
      case 'Quality Check':
        return Icons.fact_check_outlined;
      case 'Ready':
        return Icons.check_circle_outline_rounded;
      case 'Delivered':
        return Icons.local_shipping_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  static Color priorityColor(BuildContext context, String? priority) {
    switch (priority) {
      case 'High':
      case 'Urgent':
        return context.status.danger;
      case 'Medium':
        return context.status.warning;
      default:
        return context.colors.onSurfaceVariant;
    }
  }
}

/// Status pill for an order stage.
class StagePill extends StatelessWidget {
  final String? status;
  final bool dense;
  const StagePill({super.key, required this.status, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: status ?? 'Draft',
      color: StageStyle.color(context, status),
      icon: StageStyle.icon(status),
      dense: dense,
    );
  }
}

/// Thin animated progress bar for stage progress (0..1).
class StageProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  const StageProgressBar({super.key, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progress ${(value * 100).round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: MediaQuery.maybeDisableAnimationsOf(context) == true
              ? Duration.zero
              : const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: 6,
            color: color,
            backgroundColor: color.withValues(alpha: 0.14),
          ),
        ),
      ),
    );
  }
}
