import 'package:flutter/material.dart';

/// Core Shimmer effect controller providing a smooth, continuous ambient light sweep
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE5E8F0),
    this.highlightColor = const Color(0xFFF7F8FC),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = _controller.value;
        final double dx = -2.5 + (progress * 5.0);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(dx, -0.4),
              end: Alignment(dx + 1.2, 0.4),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A versatile rounded placeholder rectangle
class SkeletonContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Circular placeholder for avatars and icons
class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({
    super.key,
    required this.size,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: const BoxDecoration(
        color: Color(0xFFE5E8F0),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Text line placeholder
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry? margin;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E8F0),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

// ==========================================
// Specialized Pre-Composed Screen Skeletons
// ==========================================

/// Dashboard Skeleton: Greeting, Metric Grid, Quick Actions, and Recent Orders
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting shimmer
            const SkeletonLine(width: 220, height: 26),
            const SizedBox(height: 6),
            const SkeletonLine(width: 170, height: 14),
            const SizedBox(height: 24),

            // 4 Stats Cards Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                4,
                (index) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonCircle(size: 38),
                          SkeletonContainer(width: 44, height: 20, borderRadius: 10),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 60, height: 24),
                          SizedBox(height: 6),
                          SkeletonLine(width: 90, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Quick Actions section title
            const SkeletonLine(width: 140, height: 18),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: SkeletonContainer(height: 52, borderRadius: 12)),
                SizedBox(width: 12),
                Expanded(child: SkeletonContainer(height: 52, borderRadius: 12)),
              ],
            ),
            const SizedBox(height: 28),

            // Recent Orders section header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLine(width: 130, height: 18),
                SkeletonLine(width: 60, height: 14),
              ],
            ),
            const SizedBox(height: 12),

            // Order Cards placeholders
            ...List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Row(
                  children: [
                    SkeletonCircle(size: 44),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 140, height: 16),
                          SizedBox(height: 6),
                          SkeletonLine(width: 90, height: 12),
                        ],
                      ),
                    ),
                    SkeletonContainer(width: 70, height: 24, borderRadius: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Orders List Skeleton
class OrdersListSkeleton extends StatelessWidget {
  const OrdersListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 6,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SkeletonContainer(width: 65, height: 24, borderRadius: 6),
                      SizedBox(width: 8),
                      SkeletonLine(width: 110, height: 16),
                    ],
                  ),
                  SkeletonContainer(width: 80, height: 24, borderRadius: 12),
                ],
              ),
              SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLine(width: 130, height: 14),
                  SkeletonLine(width: 90, height: 14),
                ],
              ),
              SizedBox(height: 10),
              Divider(height: 1, color: Color(0xFFEEEEEE)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLine(width: 100, height: 14),
                  Row(
                    children: [
                      SkeletonCircle(size: 28),
                      SizedBox(width: 8),
                      SkeletonCircle(size: 28),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Customers List Skeleton
class CustomersListSkeleton extends StatelessWidget {
  const CustomersListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 8,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: const Row(
            children: [
              SkeletonCircle(size: 46),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 140, height: 16),
                    SizedBox(height: 6),
                    SkeletonLine(width: 100, height: 12),
                  ],
                ),
              ),
              Row(
                children: [
                  SkeletonCircle(size: 32),
                  SizedBox(width: 6),
                  SkeletonCircle(size: 32),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tasks List Skeleton
class TasksListSkeleton extends StatelessWidget {
  const TasksListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter chips shimmer
            Row(
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: SkeletonContainer(
                    width: index == 0 ? 55 : 85,
                    height: 36,
                    borderRadius: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Summary metrics
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: const Column(
                      children: [
                        SkeletonLine(width: 30, height: 20),
                        SizedBox(height: 4),
                        SkeletonLine(width: 50, height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Task item cards
            ...List.generate(
              5,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonLine(width: 140, height: 16),
                        SkeletonContainer(width: 80, height: 22, borderRadius: 11),
                      ],
                    ),
                    SizedBox(height: 12),
                    SkeletonLine(width: 180, height: 13),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonLine(width: 100, height: 12),
                        SkeletonLine(width: 80, height: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile Skeleton: Avatar header, info cards, and list tile placeholders
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(child: SkeletonCircle(size: 90)),
            const SizedBox(height: 16),
            const Center(child: SkeletonLine(width: 160, height: 22)),
            const SizedBox(height: 8),
            const Center(child: SkeletonLine(width: 120, height: 14)),
            const SizedBox(height: 32),

            ...List.generate(
              4,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Row(
                  children: [
                    SkeletonCircle(size: 24),
                    SizedBox(width: 16),
                    Expanded(child: SkeletonLine(height: 15)),
                    SizedBox(width: 16),
                    SkeletonContainer(width: 16, height: 16, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
