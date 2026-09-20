import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/theme/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedPeriod = 'This Month';
  bool _loading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _allOrders = [];
  List<dynamic> _staffList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ref.read(apiClientProvider);
      final statsResp = await api.getOrderStats();
      final ordersResp = await api.listOrders();
      final staffResp = await api.listStaff();
      if (mounted) {
        setState(() {
          _stats = statsResp.data;
          _allOrders = ordersResp.data;
          _staffList = staffResp.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        title: Text(
          'Reports & Analytics',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Filter
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['This Month', 'Today', 'This Week'].map((p) {
                    final isSelected = _selectedPeriod == p;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(p),
                        selected: isSelected,
                        onSelected: (v) => setState(() => _selectedPeriod = p),
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.surface,
                        labelStyle: GoogleFonts.inter(color: isSelected ? Colors.white : AppTheme.textCaption, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.divider)),
                        elevation: isSelected ? 2 : 0,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // KPI Grid
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _KpiCard(icon: Icons.people_rounded, title: 'Total Customers', value: _stats?['total_customers']?.toString() ?? '0', iconColor: const Color(0xFF1565C0), iconBgColor: const Color(0xFFE3F2FD)),
                _KpiCard(icon: Icons.shopping_bag_rounded, title: 'Total Orders', value: _stats?['total_orders']?.toString() ?? '0', iconColor: const Color(0xFF6A1B9A), iconBgColor: const Color(0xFFF3E5F5)),
                _KpiCard(icon: Icons.pending_actions_rounded, title: 'Ongoing Orders', value: _stats?['ongoing_orders']?.toString() ?? '0', iconColor: const Color(0xFFE65100), iconBgColor: const Color(0xFFFFF3E0)),
                _KpiCard(icon: Icons.check_circle_rounded, title: 'Completed Orders', value: _stats?['completed_orders']?.toString() ?? '0', iconColor: const Color(0xFF2E7D32), iconBgColor: const Color(0xFFE8F5E9)),
              ],
            ),
            const SizedBox(height: 24),

            // Order Insights
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.insights_rounded, size: 16, color: Color(0xFF1565C0)),
                      ),
                      const SizedBox(width: 10),
                      Text('Order Insights', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.3)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Status Breakdown', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textCaption)),
                  const SizedBox(height: 8),
                  
                  // Empty Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: [
                        Expanded(child: Container(height: 10, color: AppTheme.divider)), // Empty
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Legend
                  Row(
                    children: [
                      Expanded(child: _LegendItem(color: AppTheme.primary, label: 'Sewing (0%)')),
                      Expanded(child: _LegendItem(color: AppTheme.secondary, label: 'Cutting (0%)')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _LegendItem(color: const Color(0xFF9FA8DA), label: 'Other (0%)')),
                      Expanded(child: _LegendItem(color: AppTheme.divider, label: 'Ready (0%)')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Rows
                  _InsightRow(label: 'Orders This Week', value: '0', color: const Color(0xFFE3F2FD)),
                  const SizedBox(height: 12),
                  _InsightRow(label: 'Orders This Month', value: '0', color: const Color(0xFFF3E5F5)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Staff Performance
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.groups_rounded, size: 16, color: Color(0xFF6A1B9A)),
                      ),
                      const SizedBox(width: 10),
                      Text('Staff Performance', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.3)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_staffList.isEmpty)
                    Center(child: Text('No staff data available', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E))))
                  else
                    ..._staffList.map((s) {
                      final staffOrders = _allOrders.where((o) => o['staff_id'] == s['id']).toList();
                      final completedCount = staffOrders.where((o) => o['status'] == 'Delivered' || o['status'] == 'Ready').length;
                      final totalAssigned = staffOrders.length;
                      final progress = totalAssigned > 0 ? (completedCount / totalAssigned) : 0.0;
                      final name = s['full_name']?.toString() ?? 'Staff';
                      final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'S';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _StaffProgress(
                          initials: initials,
                          name: name,
                          completed: completedCount,
                          progress: progress,
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color iconBgColor;

  const _KpiCard({required this.icon, required this.title, required this.value, required this.iconColor, required this.iconBgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(value, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.5)),
            ),
          ),
          Text(title, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textCaption, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textCaption)),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InsightRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
          child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ),
      ],
    );
  }
}

class _StaffProgress extends StatelessWidget {
  final String initials;
  final String name;
  final int completed;
  final double progress;
  final Color color;

  const _StaffProgress({required this.initials, required this.name, required this.completed, required this.progress, this.color = const Color(0xFF1A237E)});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(initials, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$completed', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            Text('completed', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textCaption)),
          ],
        ),
      ],
    );
  }
}
