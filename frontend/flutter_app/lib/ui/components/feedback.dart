import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

enum ToastType { info, success, error, warning }

/// Modern floating snackbar with an icon. Returns the controller so callers
/// can still await `closed` if needed.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final status = context.status;
  final (IconData icon, Color accent) = switch (type) {
    ToastType.success => (Icons.check_circle_rounded, status.success),
    ToastType.error => (Icons.error_rounded, status.danger),
    ToastType.warning => (Icons.warning_amber_rounded, status.warning),
    ToastType.info => (Icons.info_rounded, context.colors.inversePrimary),
  };
  if (type == ToastType.error) {
    HapticFeedback.mediumImpact();
  } else if (type == ToastType.success) {
    HapticFeedback.lightImpact();
  }
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      duration: duration,
      content: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(message, maxLines: 4, overflow: TextOverflow.ellipsis)),
        ],
      ),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ),
  );
}

/// Bottom sheet that rises with a spring over a dimmed, blurred backdrop,
/// adapts its width on wide screens and never exceeds the screen.
Future<T?> showTsSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
  double maxHeightFactor = 0.9,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    useRootNavigator: useRootNavigator,
    showDragHandle: true,
    sheetAnimationStyle: AnimationStyle(
      duration: Motion.of(context, Motion.long),
      reverseDuration: Motion.of(context, Motion.short),
      curve: Motion.emphasizedDecelerate,
    ),
    builder: (ctx) {
      final h = MediaQuery.sizeOf(ctx).height;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h * maxHeightFactor),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: builder(ctx),
        ),
      );
    },
  );
}

/// Dialog that scales + fades in from the centre over a blurred backdrop.
Future<T?> showTsDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final reduced = Motion.reduced(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.40),
    useRootNavigator: useRootNavigator,
    transitionDuration: reduced ? Duration.zero : Motion.medium,
    pageBuilder: (ctx, a1, a2) => SafeArea(child: Builder(builder: builder)),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Motion.emphasizedDecelerate, reverseCurve: Motion.exit);
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6 * anim.value, sigmaY: 6 * anim.value),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
        ),
      );
    },
  );
}

/// Standard confirmation dialog. Returns true when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) async {
  final res = await showTsDialog<bool>(
    context: context,
    builder: (ctx) {
      final cs = ctx.colors;
      return AlertDialog(
        icon: icon == null
            ? null
            : Icon(icon, color: destructive ? cs.error : cs.primary, size: 32),
        title: Text(title, textAlign: icon == null ? TextAlign.start : TextAlign.center),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelLabel)),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError) : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return res ?? false;
}
