import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _user;
  List<dynamic> _tasks = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final api = ref.read(apiClientProvider);
      final statsResp = await api.getOrderStats();
      final userResp = await api.getMe();
      final ordersResp = await api.listOrders();

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
        });
      }
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
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBg,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'TailorSync',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 20, letterSpacing: -0.3),
          ),
          centerTitle: true,
        ),
        body: const DashboardSkeleton(),
      );
    }

    if (_error) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBg,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text('TailorSync', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 20, letterSpacing: -0.3)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, size: 32, color: AppTheme.error),
              ),
              const SizedBox(height: 16),
              Text('Failed to load dashboard', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
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

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'TailorSync',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 20, letterSpacing: -0.3),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 84,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with time-based greeting & user avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()} 👋',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textCaption,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          firstName,
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.surface,
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'T',
                          style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stat Cards Grid
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Active Orders',
                          value: '$activeOrders',
                          icon: Icons.work_outline_rounded,
                          color: const Color(0xFF1565C0),
                          bgColor: const Color(0xFFE3F2FD),
                          onTap: () => context.go('/tasks'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Due Today',
                          value: '$dueTodayCount',
                          icon: Icons.schedule_rounded,
                          color: const Color(0xFFE65100),
                          bgColor: const Color(0xFFFFF3E0),
                          onTap: () => context.go('/tasks'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Overdue',
                          value: '$overdueCount',
                          icon: Icons.warning_amber_rounded,
                          color: overdueCount > 0 ? const Color(0xFFC62828) : const Color(0xFF757575),
                          bgColor: overdueCount > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFF5F5F5),
                          onTap: () => context.go('/tasks'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Completed',
                          value: '$completedCount',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF2E7D32),
                          bgColor: const Color(0xFFE8F5E9),
                          onTap: () => context.go('/tasks'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Hero "New Order" Card
              _NewOrderHeroCard(onTap: () => context.go('/orders/new')),
              const SizedBox(height: 24),

              // Shortcut Grid (SliverGridDelegateWithMaxCrossAxisExtent 180, mainAxisExtent 112)
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisExtent: 118,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                children: [
                  _ShortcutCard(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Orders',
                    subtitle: 'Track and update orders',
                    badgeText: '$activeOrders active',
                    iconColor: const Color(0xFF1565C0),
                    iconBgColor: const Color(0xFFE3F2FD),
                    onTap: () => context.go('/orders'),
                  ),
                  _ShortcutCard(
                    icon: Icons.people_outline_rounded,
                    title: 'Customers',
                    subtitle: 'Manage client records',
                    iconColor: const Color(0xFF00695C),
                    iconBgColor: const Color(0xFFE0F2F1),
                    onTap: () => context.go('/customers'),
                  ),
                  _ShortcutCard(
                    icon: Icons.assignment_outlined,
                    title: 'My Tasks',
                    subtitle: 'View assigned work',
                    badgeText: overdueCount > 0 ? '$overdueCount overdue' : null,
                    badgeColor: overdueCount > 0 ? const Color(0xFFC62828) : null,
                    iconColor: const Color(0xFFE65100),
                    iconBgColor: const Color(0xFFFFF3E0),
                    onTap: () => context.go('/tasks'),
                  ),
                  if (_user?['role'] != 'staff' && _user?['role'] != 'STAFF')
                    _ShortcutCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Reports',
                      subtitle: 'Business insights',
                      iconColor: const Color(0xFF6A1B9A),
                      iconBgColor: const Color(0xFFF3E5F5),
                      onTap: () => context.go('/reports'),
                    ),
                ],
              ),
              const SizedBox(height: 28),

              // Recent Orders Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Orders',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.3),
                  ),
                  TextButton(
                    onPressed: () => context.go('/orders'),
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Recent Orders List (Max 3 items with empty state fallback)
              Consumer(
                builder: (context, ref, child) {
                  final ordersAsync = ref.watch(ordersProvider);
                  return ordersAsync.when(
                    data: (orders) {
                      if (orders.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppTheme.tertiary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.receipt_long_outlined, size: 28, color: AppTheme.secondary),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No recent orders yet',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.secondary),
                                ),
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () => context.go('/orders/new'),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Create First Order'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final recent = orders.take(3).toList();
                      return Column(
                        children: recent.map((o) {
                          final initials = o.customerName != null && o.customerName!.isNotEmpty
                              ? o.customerName!.split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
                              : 'C';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: InkWell(
                              onTap: () => context.go('/orders/details', extra: o),
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [AppTheme.primary, AppTheme.secondary],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(initials, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            o.customerName ?? 'Customer #${o.customerId}',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${o.garmentType} • #ORD-${o.id.toString().padLeft(4, '0')}',
                                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textCaption),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        o.status ?? 'Draft',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Shimmer(
                      child: Column(
                        children: [
                          SkeletonContainer(height: 64, borderRadius: 18),
                          SizedBox(height: 12),
                          SkeletonContainer(height: 64, borderRadius: 18),
                        ],
                      ),
                    ),
                    error: (e, st) => const Center(child: Text('Error loading orders')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewOrderHeroCard extends StatefulWidget {
  final VoidCallback onTap;

  const _NewOrderHeroCard({required this.onTap});

  @override
  State<_NewOrderHeroCard> createState() => _NewOrderHeroCardState();
}

class _NewOrderHeroCardState extends State<_NewOrderHeroCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF283593), Color(0xFF1A237E), Color(0xFF0D1042)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative watermark
              Positioned(
                right: -10,
                bottom: -14,
                child: Icon(
                  Icons.content_cut_rounded,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'New Order',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a customer order quickly.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  if (badgeText != null)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? AppTheme.primary).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeColor ?? AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textCaption,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
