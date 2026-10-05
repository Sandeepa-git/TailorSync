import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../ui/ui.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _user;
  int _lowStock = 0; // owners: fabrics low/out of stock
  List<dynamic> _tasks = [];
  bool _loading = true;
  bool _error = false;
  int? _errorStatus; // HTTP status of the failed load, for a clear message
  String? _errorDetail;
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorStatus = null;
      _errorDetail = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      // Perf: fire the three independent requests together.
      final results = await Future.wait([api.getOrderStats(), api.getMe(), api.listOrders()]);
      final statsResp = results[0];
      final userResp = results[1];
      final ordersResp = results[2];

      _loadInventoryAlerts();
      if (mounted) {
        setState(() {
          _stats = statsResp.data;
          _user = userResp.data;
          _tasks = ordersResp.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
          if (e is DioException) {
            _errorStatus = e.response?.statusCode;
            final data = e.response?.data;
            _errorDetail = data is Map && data['detail'] != null ? data['detail'].toString() : e.message;
          } else {
            _errorDetail = e.toString();
          }
        });
      }
    }
  }
  Future<void> _loadInventoryAlerts() async {
    try {
      final resp = await ref.read(apiClientProvider).inventoryAlerts();
      if (mounted) setState(() => _lowStock = (resp.data['count'] as num?)?.toInt() ?? 0);
    } catch (_) {
      // inventory is optional; never break the dashboard
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(refreshTriggerProvider, (prev, next) {
      if (next != prev && mounted) {
        _loadData();
      }
    });

    if (_loading) {
      return const Scaffold(body: DashboardSkeleton());
    }

    if (_error) {
      final sessionExpired = _errorStatus == 401 || _errorStatus == 403;
      return Scaffold(
        body: SafeArea(
          child: sessionExpired
              ? EmptyState(
                  icon: Icons.lock_clock_rounded,
                  title: 'Your session has expired',
                  message: 'Please sign in again to load your dashboard.',
                  actionLabel: 'Sign in again',
                  actionIcon: Icons.login_rounded,
                  onAction: () => context.go('/login'),
                )
              : ErrorState(
                  title: 'Failed to load dashboard',
                  message: _errorStatus == null
                      ? 'Check your connection and try again.${_errorDetail != null ? '\n($_errorDetail)' : ''}'
                      : 'The server returned an error ($_errorStatus). ${_errorDetail ?? ''}',
                  onRetry: _loadData,
                ),
        ),
      );
    }

    final firstName = _user?['full_name']?.split(' ').first ?? 'Tailor';
    final activeOrders = _stats?['ongoing_orders'] ?? _tasks.where((t) => t['status'] != 'Delivered' && t['status'] != 'Ready').length;
    
    final dueTodayCount = _tasks.where((t) {
      if (t['due_date'] == null) return false;
      final due = DateTime.parse(t['due_date']);
      final now = DateTime.now();
      return due.year == now.year && due.month == now.month && due.day == now.day;
    }).length;

    final overdueCount = _tasks.where((t) {
      if (t['due_date'] == null || t['status'] == 'Delivered' || t['status'] == 'Ready') return false;
      final due = DateTime.parse(t['due_date']);
      return due.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    }).length;

    final completedCount = _tasks.where((t) => t['status'] == 'Delivered' || t['status'] == 'Ready').length;

    final cs = context.colors;
    final st = context.status;
    final pad = context.pagePadding;
    final gap = context.gridGap;
    final isStaffUser = _user?['role'] == 'staff' || _user?['role'] == 'STAFF';

    final stats = [
      _StatData('Active Orders', activeOrders is num ? activeOrders : int.tryParse('$activeOrders') ?? 0,
          Icons.work_outline_rounded, st.info, () => context.go('/tasks')),
      _StatData('Due Today', dueTodayCount, Icons.schedule_rounded, st.warning, () => context.go('/tasks')),
      _StatData('Overdue', overdueCount, Icons.warning_amber_rounded,
          overdueCount > 0 ? st.danger : cs.onSurfaceVariant, () => context.go('/tasks')),
      _StatData('Completed', completedCount, Icons.check_circle_outline_rounded, st.success, () => context.go('/tasks')),
    ];

    final shortcuts = [
      _ShortcutData(Icons.shopping_bag_outlined, 'Orders', 'Track and update orders', st.info,
          badge: '$activeOrders active', onTap: () => context.go('/orders')),
      _ShortcutData(Icons.people_outline_rounded, 'Customers', 'Manage client records',
          context.isDark ? const Color(0xFF7FDCCF) : const Color(0xFF00796B), onTap: () => context.go('/customers')),
      _ShortcutData(Icons.assignment_outlined, 'My Tasks', 'View assigned work', st.warning,
          badge: overdueCount > 0 ? '$overdueCount overdue' : null,
          badgeColor: overdueCount > 0 ? st.danger : null,
          onTap: () => context.go('/tasks')),
      if (!isStaffUser)
        _ShortcutData(Icons.bar_chart_rounded, 'Reports', 'Business insights', cs.tertiary,
            onTap: () => context.go('/reports')),
      if (!isStaffUser)
        _ShortcutData(Icons.inventory_2_outlined, 'Inventory', 'Fabric stock levels',
            context.isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00),
            badge: _lowStock > 0 ? '$_lowStock low' : null,
            badgeColor: _lowStock > 0 ? st.danger : null,
            onTap: () => context.push('/inventory')),
    ];

    return Scaffold(
      body: TsScrollPage(
        watermark: TailorAccessory.scissors,
        title: 'TailorSync',
        // Wordmark in the same type style as the splash screen's "TailorSync".
        titleWidget: Text(
          'TailorSync',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.displaySmall?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            fontSize: context.isSmallPhone ? 24 : 27,
            height: 1.1,
          ),
        ),
        automaticallyImplyLeading: false,
        padSlivers: false,
        onRefresh: _loadData,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: ProfileRingAvatar(
              name: _user?['full_name'] ?? firstName,
              isOwner: !isStaffUser,
              size: 46,
              onTap: () => context.push('/profile'),
            ),
          ),
          const SizedBox(width: Space.xs),
        ],
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverList.list(
              children: [
                  MaxWidthBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EntranceFade(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_getGreeting(),
                                  style: context.text.bodyMedium?.copyWith(
                                      color: context.isDark ? const Color(0xFFB8C2FF) : const Color(0xFF3949AB),
                                      fontWeight: FontWeight.w600)),
                              Text(
                                firstName,
                                style: context.text.headlineMedium?.copyWith(
                                    color: context.isDark ? Colors.white : const Color(0xFF1A237E)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Space.md),
                        EntranceFade(
                          delay: Motion.staggerStep,
                          child: _NewOrderHeroCard(
                            activeOrders: stats.first.value,
                            onTap: () => context.go('/orders/new'),
                          ),
                        ),
                        const SizedBox(height: Space.sm),
                        EntranceFade(
                          delay: Motion.staggerStep * 2,
                          child: _TryOnHeroCard(onTap: () => context.push('/tryon')),
                        ),
                        if (!isStaffUser && _lowStock > 0) ...[
                          const SizedBox(height: Space.sm),
                          TsCard(
                            onTap: () => context.push('/inventory'),
                            color: st.danger.withValues(alpha: 0.08),
                            padding: const EdgeInsets.all(Space.sm + 2),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: st.danger),
                                const SizedBox(width: Space.sm),
                                Expanded(
                                  child: Text(
                                    _lowStock == 1 ? '1 fabric is running low' : '$_lowStock fabrics are running low',
                                    style: context.text.titleSmall,
                                  ),
                                ),
                                Text('View', style: context.text.labelLarge?.copyWith(color: cs.primary)),
                              ],
                            ),
                          ),
                        ],
                        const SectionHeader(title: 'Today at a glance'),
                        GridView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: adaptiveGrid(
                            maxTileWidth: context.isWide ? 220 : 240,
                            mainAxisExtent: context.isSmallPhone ? 120 : 128,
                            spacing: gap,
                          ),
                          itemCount: stats.length,
                          itemBuilder: (context, i) => EntranceFade.indexed(i + 2, child: _StatCard(data: stats[i])),
                        ),
                        const SectionHeader(title: 'Shortcuts'),
                        GridView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: adaptiveGrid(
                            maxTileWidth: context.isWide ? 220 : 240,
                            mainAxisExtent: context.isSmallPhone ? 122 : 128,
                            spacing: gap,
                          ),
                          itemCount: shortcuts.length,
                          itemBuilder: (context, i) => EntranceFade.indexed(i + 4, child: _ShortcutCard(data: shortcuts[i])),
                        ),
                        SectionHeader(
                          title: 'Recent Orders',
                          actionLabel: 'View All',
                          onAction: () => context.go('/orders'),
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final ordersAsync = ref.watch(ordersProvider);
                            return AnimatedSwitcher(
                              duration: Motion.of(context, Motion.medium),
                              child: ordersAsync.when(
                                data: (orders) {
                                  if (orders.isEmpty) {
                                    return TsCard(
                                      key: const ValueKey('empty'),
                                      padding: const EdgeInsets.symmetric(vertical: Space.lg, horizontal: Space.md),
                                      child: Column(
                                        children: [
                                          const FloatingIllustration(icon: Icons.receipt_long_outlined, size: 72),
                                          const SizedBox(height: Space.xs),
                                          Text('No recent orders yet', style: context.text.titleSmall),
                                          const SizedBox(height: Space.md),
                                          TsButton.secondary(
                                            label: 'Create First Order',
                                            icon: Icons.add_rounded,
                                            expand: false,
                                            onPressed: () => context.go('/orders/new'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  final recent = orders.take(3).toList();
                                  return Column(
                                    key: const ValueKey('data'),
                                    children: [
                                      for (var i = 0; i < recent.length; i++)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: Space.sm),
                                          child: EntranceFade.indexed(
                                            i,
                                            child: _RecentOrderTile(
                                              title: recent[i].customerName ?? 'Customer #${recent[i].customerId}',
                                              subtitle:
                                                  '${recent[i].garmentType} • #ORD-${recent[i].id.toString().padLeft(4, '0')}',
                                              status: recent[i].status,
                                              onTap: () => context.go('/orders/details', extra: recent[i]),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                                loading: () => const Shimmer(
                                  key: ValueKey('loading'),
                                  child: Column(
                                    children: [
                                      SkeletonListTile(),
                                      SizedBox(height: Space.sm),
                                      SkeletonListTile(),
                                    ],
                                  ),
                                ),
                                error: (e, st) => ErrorState(
                                  key: const ValueKey('error'),
                                  title: 'Error loading orders',
                                  onRetry: () => ref.invalidate(ordersProvider),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + Space.xl)),
          ],
      ),
    );
  }
}

/// Gradient hero CTA with a slow ambient shimmer and decorative needle arc.
class _NewOrderHeroCard extends StatelessWidget {
  final num activeOrders;
  final VoidCallback onTap;
  const _NewOrderHeroCard({required this.activeOrders, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final compact = context.isSmallPhone;
    return Semantics(
      button: true,
      label: 'Create new order',
      child: Pressable(
        onTap: onTap,
        haptic: true,
        child: ClipRRect(
          borderRadius: Radii.brXl,
          child: Container(
            decoration: BoxDecoration(gradient: Gradients.hero(cs), boxShadow: Shadows.raised(cs)),
            child: Stack(
              children: [
                const Positioned.fill(child: _HeroGlow()),
                Positioned(
                  right: -24,
                  bottom: -28,
                  child: Icon(Icons.content_cut_rounded, size: 140, color: Colors.white.withValues(alpha: 0.07)),
                ),
                Padding(
                  padding: EdgeInsets.all(compact ? Space.md : Space.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusPill(
                              label: 'AI-assisted measurements',
                              icon: Icons.auto_awesome_rounded,
                              color: Colors.white,
                              background: Colors.white.withValues(alpha: 0.16),
                              dense: true,
                            ),
                            const SizedBox(height: Space.sm),
                            Text('New Order', style: context.text.headlineSmall?.copyWith(color: Colors.white)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                AnimatedCount(
                                  value: activeOrders,
                                  style: context.text.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    ' orders in progress',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Container(
                        width: compact ? 48 : 56,
                        height: compact ? 48 : 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: Radii.brLg,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: Icon(Icons.add_rounded, color: cs.primary, size: 30),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary hero card that opens the AI Virtual Try-On screen.
class _TryOnHeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _TryOnHeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final compact = context.isSmallPhone;
    final dark = context.isDark;
    return Semantics(
      button: true,
      label: 'Open virtual try-on',
      child: Pressable(
        onTap: onTap,
        haptic: true,
        child: ClipRRect(
          borderRadius: Radii.brXl,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [Color(0xFF5B2A86), Color(0xFF3A1A5E)]
                    : const [Color(0xFF7B3FB5), Color(0xFF4A1F7A)],
              ),
              boxShadow: Shadows.raised(context.colors),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -24,
                  child: Icon(Icons.checkroom_rounded, size: 132, color: Colors.white.withValues(alpha: 0.08)),
                ),
                Padding(
                  padding: EdgeInsets.all(compact ? Space.md : Space.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusPill(
                              label: 'New · AI image',
                              icon: Icons.auto_awesome_rounded,
                              color: Colors.white,
                              background: Colors.white.withValues(alpha: 0.16),
                              dense: true,
                            ),
                            const SizedBox(height: Space.sm),
                            Text('Virtual Try-On', style: context.text.headlineSmall?.copyWith(color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(
                              'See a design on your customer before cutting',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Container(
                        width: compact ? 48 : 56,
                        height: compact ? 48 : 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: Radii.brLg,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: const Icon(Icons.checkroom_rounded, color: Color(0xFF5B2A86), size: 28),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slow drifting radial glow inside the hero card.
class _HeroGlow extends StatefulWidget {
  const _HeroGlow();

  @override
  State<_HeroGlow> createState() => _HeroGlowState();
}

class _HeroGlowState extends State<_HeroGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_c.value);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.9 + 1.4 * t, -0.8 + 0.6 * t),
                radius: 1.1,
                colors: [const Color(0xFF8C9EFF).withValues(alpha: 0.35), Colors.transparent],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatData {
  final String label;
  final num value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _StatData(this.label, this.value, this.icon, this.color, this.onTap);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${data.label}: ${data.value}',
      excludeSemantics: true,
      child: TsCard(
        onTap: data.onTap,
        padding: const EdgeInsets.all(Space.md - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconBadge(icon: data.icon, color: data.color, size: 36),
                const Spacer(),
                Icon(Icons.arrow_outward_rounded, size: 16, color: context.colors.onSurfaceVariant),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCount(value: data.value, style: context.text.headlineSmall),
                Text(data.label, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;
  _ShortcutData(this.icon, this.title, this.subtitle, this.color, {this.badge, this.badgeColor, required this.onTap});
}

class _ShortcutCard extends StatelessWidget {
  final _ShortcutData data;
  const _ShortcutCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return TsCard(
      onTap: data.onTap,
      padding: const EdgeInsets.all(Space.md - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: data.icon, color: data.color, size: 40),
              const Spacer(),
              if (data.badge != null)
                Flexible(
                  flex: 3,
                  child: StatusPill(label: data.badge!, color: data.badgeColor ?? data.color, dense: true),
                ),
            ],
          ),
          const Spacer(),
          Text(data.title, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(data.subtitle, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback onTap;
  const _RecentOrderTile({required this.title, required this.subtitle, required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.sm + 2),
      child: Row(
        children: [
          InitialsAvatar(name: title),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: Space.xs),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.screenWidth * 0.32),
            child: StagePill(status: status, dense: true),
          ),
        ],
      ),
    );
  }
}
