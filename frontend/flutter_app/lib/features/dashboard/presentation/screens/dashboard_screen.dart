import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/providers/api_provider.dart';
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
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'TailorSync',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
          ),
          centerTitle: true,
        ),
        body: const DashboardSkeleton(),
      );
    }

    if (_error) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text('TailorSync', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFD32F2F)),
              const SizedBox(height: 16),
              Text('Failed to load dashboard', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'TailorSync',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
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
                          '${_getGreeting()}, $firstName',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A237E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Here is your dashboard overview.',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5C6BC0)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF1A237E),
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'T',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3 Compact Stat Cards Row (Active, Due Today, Overdue)
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Active',
                      value: '$activeOrders',
                      icon: Icons.work_outline,
                      color: const Color(0xFF1A237E),
                      bgColor: Colors.white,
                      borderColor: const Color(0xFFE8EAF6),
                      onTap: () => context.go('/tasks'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Due Today',
                      value: '$dueTodayCount',
                      icon: Icons.calendar_today_outlined,
                      color: const Color(0xFF1A237E),
                      bgColor: const Color(0xFFE8EAF6),
                      borderColor: const Color(0xFFE8EAF6),
                      onTap: () => context.go('/tasks'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Overdue',
                      value: '$overdueCount',
                      icon: Icons.warning_amber_rounded,
                      color: overdueCount > 0 ? const Color(0xFFD32F2F) : const Color(0xFF757575),
                      bgColor: overdueCount > 0 ? const Color(0xFFFFEBEE) : Colors.white,
                      borderColor: overdueCount > 0 ? const Color(0xFFFFCDD2) : const Color(0xFFE8EAF6),
                      onTap: () => context.go('/tasks'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hero "New Order" Card
              _NewOrderHeroCard(onTap: () => context.go('/orders/new')),
              const SizedBox(height: 20),

              // Shortcut Grid (SliverGridDelegateWithMaxCrossAxisExtent 180, mainAxisExtent 112)
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisExtent: 112,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                children: [
                  _ShortcutCard(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Orders',
                    subtitle: 'Track and update orders',
                    badgeText: '$activeOrders active',
                    iconColor: const Color(0xFF1A237E),
                    iconBgColor: const Color(0xFFE8EAF6),
                    onTap: () => context.go('/orders'),
                  ),
                  _ShortcutCard(
                    icon: Icons.people_outline,
                    title: 'Customers',
                    subtitle: 'Manage client records',
                    iconColor: const Color(0xFF343A40),
                    iconBgColor: const Color(0xFFF1F3F5),
                    onTap: () => context.go('/customers'),
                  ),
                  _ShortcutCard(
                    icon: Icons.assignment_outlined,
                    title: 'My Tasks',
                    subtitle: 'View assigned work',
                    badgeText: overdueCount > 0 ? '$overdueCount overdue' : null,
                    badgeColor: overdueCount > 0 ? const Color(0xFFD32F2F) : null,
                    iconColor: const Color(0xFF1A237E),
                    iconBgColor: const Color(0xFFE8EAF6),
                    onTap: () => context.go('/tasks'),
                  ),
                  if (_user?['role'] != 'staff')
                    _ShortcutCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Reports',
                      subtitle: 'Business insights',
                      iconColor: const Color(0xFF343A40),
                      iconBgColor: const Color(0xFFF1F3F5),
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
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
                  ),
                  TextButton(
                    onPressed: () => context.go('/orders'),
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A237E)),
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
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8EAF6)),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 44, color: Color(0xFF9FA8DA)),
                                const SizedBox(height: 8),
                                Text(
                                  'No recent orders yet',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF5C6BC0)),
                                ),
                                const SizedBox(height: 12),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8EAF6)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1A237E).withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () => context.go('/orders/details', extra: o),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFFE8EAF6),
                                      foregroundColor: const Color(0xFF1A237E),
                                      child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            o.customerName ?? 'Customer #${o.customerId}',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E), fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${o.garmentType} • #ORD-${o.id.toString().padLeft(4, '0')}',
                                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        o.status ?? 'Draft',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1A237E),
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
                          SkeletonContainer(height: 64, borderRadius: 16),
                          SizedBox(height: 12),
                          SkeletonContainer(height: 64, borderRadius: 16),
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
  final Color borderColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 16, color: color),
                  Text(
                    value,
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
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
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0F175A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'New Order',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a customer order quickly.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 24),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? const Color(0xFF1A237E)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText!,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: badgeColor ?? const Color(0xFF1A237E),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF5C6BC0),
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
