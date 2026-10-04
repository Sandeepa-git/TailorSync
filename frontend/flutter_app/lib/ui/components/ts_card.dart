import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// Rounded surface card with soft layered shadow and press feedback.
class TsCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final BorderRadius? radius;
  final bool shadow;
  final bool border;

  const TsCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(Space.md),
    this.color,
    this.gradient,
    this.radius,
    this.shadow = true,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final br = radius ?? Radii.brLg;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? cs.surfaceContainerLowest) : null,
        gradient: gradient,
        borderRadius: br,
        border: border && gradient == null
            ? Border.all(color: cs.outlineVariant.withValues(alpha: context.isDark ? 0.35 : 0.45))
            : null,
        boxShadow: shadow ? Shadows.soft(cs) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: br,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (onTap == null && onLongPress == null) return card;
    return Pressable(child: card);
  }
}

/// Section title with optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: Space.sm)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Small rounded icon container used in tiles and stats.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? background;
  final double size;

  const IconBadge({super.key, required this.icon, this.color, this.background, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final fg = color ?? cs.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? fg.withValues(alpha: context.isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}

/// Tonal pill for statuses / priorities.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;
  final bool dense;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.icon,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? Space.xs : 10, vertical: dense ? 2 : Space.xxs),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: context.isDark ? 0.20 : 0.12),
        borderRadius: Radii.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circle avatar with initials and a deterministic tonal colour.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  const InitialsAvatar({super.key, required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.length == 1 ? parts.first[0] : '${parts.first[0]}${parts.last[0]}').toUpperCase();
    final palette = [cs.primary, cs.tertiary, context.status.info, context.status.success, context.status.warning];
    final c = palette[name.hashCode.abs() % palette.length];
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.withValues(alpha: context.isDark ? 0.22 : 0.12),
        ),
        child: Text(
          initials,
          style: context.text.titleSmall?.copyWith(color: c, fontWeight: FontWeight.w800, fontSize: size * 0.36),
        ),
      ),
    );
  }
}
