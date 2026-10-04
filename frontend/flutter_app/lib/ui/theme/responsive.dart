import 'package:flutter/material.dart';

import 'tokens.dart';

/// Phone-first breakpoints (logical width in dp).
///
///  xs  < 360   old / budget phones, iPhone SE 1st gen
///  sm  < 390   most common Android
///  md  < 430   most modern phones
///  lg  < 600   Plus / Pro Max / large phones
///  xl  ≥ 600   unfolded foldables, small tablets
enum Breakpoint { xs, sm, md, lg, xl }

abstract final class Breakpoints {
  static const double sm = 360;
  static const double md = 390;
  static const double lg = 430;
  static const double xl = 600;

  static Breakpoint of(double width) {
    if (width < sm) return Breakpoint.xs;
    if (width < md) return Breakpoint.sm;
    if (width < lg) return Breakpoint.md;
    if (width < xl) return Breakpoint.lg;
    return Breakpoint.xl;
  }
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  Breakpoint get breakpoint => Breakpoints.of(screenWidth);

  bool get isSmallPhone => screenWidth < Breakpoints.sm;
  bool get isCompact => screenWidth < Breakpoints.md;
  bool get isLargePhone => screenWidth >= Breakpoints.lg;
  bool get isWide => screenWidth >= Breakpoints.xl;

  /// Very short screens (≈568dp and below) or landscape phones.
  bool get isShort => screenHeight < 640;

  /// Pick a value per breakpoint; missing values fall back to the
  /// nearest smaller breakpoint, then to [xs].
  T responsive<T>({required T xs, T? sm, T? md, T? lg, T? xl}) {
    switch (breakpoint) {
      case Breakpoint.xl:
        return xl ?? lg ?? md ?? sm ?? xs;
      case Breakpoint.lg:
        return lg ?? md ?? sm ?? xs;
      case Breakpoint.md:
        return md ?? sm ?? xs;
      case Breakpoint.sm:
        return sm ?? xs;
      case Breakpoint.xs:
        return xs;
    }
  }

  /// Horizontal page gutter: 16 / 16 / 20 / 24 / 32.
  double get pagePadding => responsive<double>(xs: Space.md, md: 20, lg: Space.lg, xl: Space.xl);

  /// Gap between grid / list cards.
  double get gridGap => responsive<double>(xs: Space.xs + 2, sm: Space.sm, lg: Space.md);

  /// Scale for hero elements (logo, illustrations). Never shrinks
  /// below 0.8 or grows beyond 1.2.
  double get heroScale => (screenWidth / 390).clamp(0.8, 1.2);
}

/// Centres its child and caps its width on wide screens.
class MaxWidthBox extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  final Alignment alignment;

  const MaxWidthBox({
    super.key,
    this.maxWidth = MaxWidth.content,
    this.alignment = Alignment.topCenter,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Grid delegate whose column count adapts to width:
/// 2 on phones, 3 on large phones/foldables, 4+ on wide screens.
SliverGridDelegate adaptiveGrid({
  double maxTileWidth = 200,
  double mainAxisExtent = 120,
  double spacing = Space.sm,
}) =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxTileWidth,
      mainAxisExtent: mainAxisExtent,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );

/// Clamp text scaling for a single widget subtree that cannot reflow
/// (e.g. a fixed-height nav bar label). Never use globally.
class ClampedTextScale extends StatelessWidget {
  final double max;
  final Widget child;
  const ClampedTextScale({super.key, this.max = 1.3, required this.child});

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: max);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: child,
    );
  }
}
