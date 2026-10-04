import 'package:flutter/material.dart';

import '../../ui/theme/app_theme.dart';
import '../../ui/theme/motion.dart';
import '../../ui/theme/responsive.dart';
import '../../ui/theme/tokens.dart';

/// Theme-aware shimmer sweep. Static (no sweep) when reduced motion is on.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const Shimmer({super.key, required this.child, this.duration = const Duration(milliseconds: 1400)});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final base = _skeletonColor(context);
    final highlight = context.isDark ? cs.surfaceContainerHighest : cs.surfaceContainerLowest;
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (context, child) {
              final dx = -2.5 + (_controller.value * 5.0);
              return ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment(dx, -0.4),
                  end: Alignment(dx + 1.2, 0.4),
                  colors: [base, highlight, base],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

Color _skeletonColor(BuildContext context) =>
    context.isDark ? context.colors.surfaceContainerHigh : context.colors.surfaceContainerHigh;

/// A versatile rounded placeholder rectangle
class SkeletonContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonContainer({super.key, this.width, this.height, this.borderRadius = 12, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(color: _skeletonColor(context), borderRadius: BorderRadius.circular(borderRadius)),
    );
  }
}

/// Circular placeholder for avatars and icons
class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({super.key, required this.size, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(color: _skeletonColor(context), shape: BoxShape.circle),
    );
  }
}

/// Text line placeholder. [widthFactor] lets lines adapt to any screen.
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double widthFactor;
  final double height;
  final EdgeInsetsGeometry? margin;

  const SkeletonLine({super.key, this.width, this.widthFactor = 1, this.height = 12, this.margin});

  @override
  Widget build(BuildContext context) {
    final line = Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: _skeletonColor(context), borderRadius: BorderRadius.circular(height / 2)),
    );
    if (width != null) return line;
    return FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: widthFactor, child: line);
  }
}

/// A list-row placeholder: avatar + two lines + trailing pill.
class SkeletonListTile extends StatelessWidget {
  final bool trailing;
  const SkeletonListTile({super.key, this.trailing = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        borderRadius: Radii.brLg,
        border: Border.all(color: _skeletonColor(context)),
      ),
      child: Row(
        children: [
          const SkeletonCircle(size: 44),
          const SizedBox(width: Space.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(widthFactor: 0.6, height: 14),
                SkeletonLine(widthFactor: 0.4, height: 10),
              ],
            ),
          ),
          if (trailing) const SkeletonContainer(width: 56, height: 22, borderRadius: 11),
        ],
      ),
    );
  }
}

/// Generic padded list of skeleton tiles.
class _SkeletonList extends StatelessWidget {
  final int count;
  final Widget? header;
  const _SkeletonList({this.count = 6, this.header});

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(pad, Space.md, pad, Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) header!,
            for (var i = 0; i < count; i++) ...[
              const SkeletonListTile(),
              const SizedBox(height: Space.sm),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dashboard: greeting, hero card, stat grid, recent orders.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;
    return SafeArea(
      child: Shimmer(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(widthFactor: 0.4, height: 12),
                        SkeletonLine(widthFactor: 0.7, height: 22),
                      ],
                    ),
                  ),
                  SkeletonCircle(size: 48),
                ],
              ),
              const SizedBox(height: Space.lg),
              const SkeletonContainer(height: 140, borderRadius: Radii.xl),
              const SizedBox(height: Space.lg),
              const Row(
                children: [
                  Expanded(child: SkeletonContainer(height: 104, borderRadius: Radii.lg)),
                  SizedBox(width: Space.sm),
                  Expanded(child: SkeletonContainer(height: 104, borderRadius: Radii.lg)),
                ],
              ),
              const SizedBox(height: Space.sm),
              const Row(
                children: [
                  Expanded(child: SkeletonContainer(height: 104, borderRadius: Radii.lg)),
                  SizedBox(width: Space.sm),
                  Expanded(child: SkeletonContainer(height: 104, borderRadius: Radii.lg)),
                ],
              ),
              const SizedBox(height: Space.lg),
              const SkeletonLine(widthFactor: 0.35, height: 16),
              const SizedBox(height: Space.sm),
              for (var i = 0; i < 3; i++) ...[
                const SkeletonListTile(),
                const SizedBox(height: Space.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OrdersListSkeleton extends StatelessWidget {
  const OrdersListSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const _SkeletonList(count: 6);
}

class CustomersListSkeleton extends StatelessWidget {
  const CustomersListSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const _SkeletonList(count: 7);
}

class TasksListSkeleton extends StatelessWidget {
  const TasksListSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const _SkeletonList(
        count: 5,
        header: Padding(
          padding: EdgeInsets.only(bottom: Space.md),
          child: Row(
            children: [
              Expanded(child: SkeletonContainer(height: 84, borderRadius: Radii.lg)),
              SizedBox(width: Space.sm),
              Expanded(child: SkeletonContainer(height: 84, borderRadius: Radii.lg)),
              SizedBox(width: Space.sm),
              Expanded(child: SkeletonContainer(height: 84, borderRadius: Radii.lg)),
            ],
          ),
        ),
      );
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(pad),
        child: Column(
          children: [
            const SizedBox(height: Space.lg),
            const SkeletonCircle(size: 88),
            const SizedBox(height: Space.md),
            const SkeletonLine(width: 160, height: 18),
            const SkeletonLine(width: 110, height: 12),
            const SizedBox(height: Space.lg),
            for (var i = 0; i < 5; i++) ...[
              const SkeletonContainer(height: 60, borderRadius: Radii.md),
              const SizedBox(height: Space.sm),
            ],
          ],
        ),
      ),
    );
  }
}
