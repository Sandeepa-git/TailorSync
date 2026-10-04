import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/motion.dart';

/// Fade-through page used when switching between bottom-nav destinations.
Page<void> fadeThroughPage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: Motion.medium,
      reverseTransitionDuration: Motion.short,
      transitionsBuilder: (context, animation, secondary, child) {
        if (Motion.reduced(context)) return child;
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondary,
          fillColor: Theme.of(context).colorScheme.surface,
          child: child,
        );
      },
    );

/// Gentle fade + scale used for splash → auth → app.
Page<void> fadeScalePage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: Motion.long,
      transitionsBuilder: (context, animation, secondary, child) {
        if (Motion.reduced(context)) return child;
        return FadeScaleTransition(animation: animation, child: child);
      },
    );

/// Vertical shared-axis page for full-screen flows (e.g. new order wizard).
Page<void> sharedAxisVerticalPage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: Motion.long,
      transitionsBuilder: (context, animation, secondary, child) {
        if (Motion.reduced(context)) return child;
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          transitionType: SharedAxisTransitionType.vertical,
          fillColor: Theme.of(context).colorScheme.surface,
          child: child,
        );
      },
    );
