import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

enum TsButtonVariant { primary, secondary, tonal, text, danger }

/// Primary building block for actions.
///
/// * Scales down slightly on press with a spring back.
/// * When [loading] is true a full-width button morphs into a circular
///   progress indicator; when [success] is true it morphs into a check.
class TsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final TsButtonVariant variant;
  final bool loading;
  final bool success;
  final bool expand;
  final bool haptic;

  const TsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = TsButtonVariant.primary,
    this.loading = false,
    this.success = false,
    this.expand = true,
    this.haptic = true,
  });

  const TsButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.success = false,
    this.expand = true,
    this.haptic = false,
  }) : variant = TsButtonVariant.secondary;

  const TsButton.tonal({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.success = false,
    this.expand = true,
    this.haptic = false,
  }) : variant = TsButtonVariant.tonal;

  const TsButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
  })  : variant = TsButtonVariant.text,
        loading = false,
        success = false,
        haptic = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final busy = loading || success;
    const height = 52.0;

    final (Color bg, Color fg, BorderSide? side) = switch (variant) {
      TsButtonVariant.primary => (cs.primary, cs.onPrimary, null),
      TsButtonVariant.danger => (cs.error, cs.onError, null),
      TsButtonVariant.tonal => (cs.secondaryContainer, cs.onSecondaryContainer, null),
      TsButtonVariant.secondary => (Colors.transparent, cs.primary, BorderSide(color: cs.outlineVariant)),
      TsButtonVariant.text => (Colors.transparent, cs.primary, null),
    };
    final disabled = onPressed == null && !busy;
    final effectiveBg = disabled && bg != Colors.transparent ? cs.onSurface.withValues(alpha: 0.12) : bg;
    final effectiveFg = disabled ? cs.onSurface.withValues(alpha: 0.38) : fg;
    final finalBg = success && variant != TsButtonVariant.text ? context.status.success : effectiveBg;

    Widget content;
    if (success) {
      content = Icon(Icons.check_rounded, key: const ValueKey('ok'), color: Colors.white, size: 26);
    } else if (loading) {
      content = SizedBox(
        key: const ValueKey('busy'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: effectiveFg),
      );
    } else {
      content = Row(
        key: const ValueKey('label'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: effectiveFg),
            const SizedBox(width: Space.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelLarge?.copyWith(color: effectiveFg, fontSize: 15),
            ),
          ),
        ],
      );
    }

    final dur = Motion.of(context, Motion.medium);

    Widget button(double? fullWidth) {
      final w = busy ? height : fullWidth;
      return AnimatedContainer(
        duration: dur,
        curve: Motion.emphasized,
        width: w,
        height: height,
        decoration: BoxDecoration(
          color: finalBg,
          borderRadius: BorderRadius.circular(busy ? height / 2 : Radii.md),
          border: side == null ? null : Border.fromBorderSide(side),
          boxShadow: variant == TsButtonVariant.primary && !disabled ? Shadows.raised(cs) : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(busy ? height / 2 : Radii.md),
            onTap: busy || onPressed == null
                ? null
                : () {
                    if (haptic) HapticFeedback.lightImpact();
                    onPressed!();
                  },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: busy ? 0 : Space.lg),
              child: Center(
                child: AnimatedSwitcher(
                  duration: Motion.of(context, Motion.short),
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: ScaleTransition(scale: Tween(begin: 0.6, end: 1.0).animate(a), child: c),
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: !disabled,
      label: loading ? '$label, loading' : label,
      child: Pressable(
        enabled: !busy && onPressed != null,
        child: expand
            ? LayoutBuilder(
                builder: (context, c) => Center(child: button(c.maxWidth.isFinite ? c.maxWidth : null)),
              )
            : button(null),
      ),
    );
  }
}

/// Round icon button with a soft tonal background and a 48dp target.
class TsIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool filled;
  final Color? color;

  const TsIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.filled = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Pressable(
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: filled ? cs.surfaceContainerHigh : Colors.transparent,
          foregroundColor: color ?? cs.onSurface,
          minimumSize: const Size(kMinTouch, kMinTouch),
          shape: const CircleBorder(),
        ),
        icon: Icon(icon, size: 22),
      ),
    );
  }
}
