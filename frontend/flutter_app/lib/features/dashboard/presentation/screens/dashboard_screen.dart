import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ref.read(apiClientProvider);
      final statsResp = await api.dio.get('/orders/stats');
      final userResp = await api.getMe();
      if (mounted) {
        setState(() {
          _stats = statsResp.data;
          _user = userResp.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _user?['full_name']?.split(' ').first ?? 'Tailor';
    final activeOrders = _stats?['ongoing_orders'] ?? 0;
    
    // Initialize to 0 for a fresh state
    final dueToday = 0;
    final overdue = 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1A237E)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'TailorSync',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1A237E)),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close the drawer
                context.go('/profile');
              },
              child: UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A237E),
                ),
                accountName: Text(
                  _user?['full_name'] ?? 'Loading...',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                accountEmail: Text(
                  _user?['email'] ?? '',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9FA8DA)),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    (_user?['full_name'] ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF5C6BC0)),
              title: Text('Home', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Color(0xFF5C6BC0)),
              title: Text('New Order', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                context.push('/orders/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF5C6BC0)),
              title: Text('Orders', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                context.go('/orders');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline, color: Color(0xFF5C6BC0)),
              title: Text('Customers', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                context.go('/customers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined, color: Color(0xFF5C6BC0)),
              title: Text('My Tasks', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                context.go('/tasks');
              },
            ),
            if (_user?['role'] != 'staff')
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined, color: Color(0xFF5C6BC0)),
                title: Text('Reports', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/reports');
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF5C6BC0)),
              title: Text('Profile & Settings', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
              title: Text('Logout', style: GoogleFonts.inter(color: const Color(0xFFD32F2F), fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context); // Close the drawer first
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                    content: Text('Are you sure you want to log out?', style: GoogleFonts.inter(color: const Color(0xFF5C6BC0))),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('No', style: GoogleFonts.inter(color: const Color(0xFF5C6BC0))),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Yes', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final api = ref.read(apiClientProvider);
                  api.clearToken();
                  if (context.mounted) context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      'Good Morning, $firstName',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is your dashboard overview.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF5C6BC0),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Pills Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatPill(
                            label: 'Active Orders: $activeOrders',
                            backgroundColor: const Color(0xFF1A237E),
                            textColor: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          _StatPill(
                            label: 'Due Today: $dueToday',
                            backgroundColor: const Color(0xFFFFEBEB),
                            textColor: const Color(0xFFD32F2F),
                          ),
                          const SizedBox(width: 8),
                          _StatPill(
                            label: 'Overdue: $overdue',
                            backgroundColor: const Color(0xFFF1F3F5),
                            textColor: const Color(0xFF495057),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Big New Order Card
                    GestureDetector(
                      onTap: () => context.go('/orders/new'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F175A), // Very dark blue
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A237E).withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'New Order',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a customer order quickly.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions Grid
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.4,
                      children: [
                        _QuickActionCard(
                          icon: Icons.assignment_outlined,
                          label: 'Orders',
                          subtitle: 'Track and update orders',
                          iconColor: const Color(0xFF1A237E),
                          iconBgColor: const Color(0xFFE8EAF6),
                          onTap: () => context.go('/orders'),
                        ),
                        _QuickActionCard(
                          icon: Icons.people_outline,
                          label: 'Customers',
                          subtitle: 'Manage records',
                          iconColor: const Color(0xFF343A40),
                          iconBgColor: const Color(0xFFF8F9FA),
                          onTap: () => context.go('/customers'),
                        ),
                        _QuickActionCard(
                          icon: Icons.check_circle_outline,
                          label: 'My Tasks',
                          subtitle: 'View assigned work',
                          iconColor: const Color(0xFF1A237E),
                          iconBgColor: const Color(0xFFE8EAF6),
                          onTap: () => context.go('/tasks'),
                        ),
                        if (_user?['role'] != 'staff')
                          _QuickActionCard(
                            icon: Icons.bar_chart,
                            label: 'Reports',
                            subtitle: 'Business insights',
                            iconColor: const Color(0xFF343A40),
                            iconBgColor: const Color(0xFFF8F9FA),
                            onTap: () => context.go('/reports'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Recent Orders
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Orders',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A237E),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/orders'),
                          child: Text(
                            'View All',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A237E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Fetch recent orders from provider
                    Consumer(
                      builder: (context, ref, child) {
                        final ordersAsync = ref.watch(ordersProvider);
                        return ordersAsync.when(
                          data: (orders) {
                            if (orders.isEmpty) {
                              return const Center(child: Text('No recent orders'));
                            }
                            // Take top 3
                            final recent = orders.take(3).toList();
                            return Column(
                              children: recent.map((o) {
                                final initials = o.customerName?.split(' ').map((e) => e[0]).take(2).join('').toUpperCase() ?? 'C';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE8EAF6)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1A237E).withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFFE8EAF6),
                                        foregroundColor: const Color(0xFF1A237E),
                                        child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              o.customerName ?? 'Unknown',
                                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              o.garmentType,
                                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5C6BC0)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: o.status == 'Cutting' ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          o.status ?? 'Draft',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: o.status == 'Cutting' ? Colors.white : const Color(0xFF5C6BC0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, st) => Center(child: Text('Error loading orders')),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _StatPill({required this.label, required this.backgroundColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EAF6)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A237E).withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF5C6BC0),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
