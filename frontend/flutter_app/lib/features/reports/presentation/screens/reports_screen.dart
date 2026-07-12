import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers/api_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedPeriod = 'This Month';
  bool _loading = true;
  bool _exporting = false;
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

  Future<void> _exportToCsv() async {
    setState(() => _exporting = true);
    try {
      final csvFile = File('C:\\Users\\Sandeepa\\Desktop\\TailorSync_Report.csv');
      final sink = csvFile.openWrite();
      sink.writeln('Order ID,Customer Name,Garment Type,Priority,Status,Due Date,Staff ID');
      for (final o in _allOrders) {
        sink.writeln('${o['id']},${o['customer_name']},${o['garment_type']},${o['priority']},${o['status']},${o['due_date'] ?? 'N/A'},${o['staff_id'] ?? 'Unassigned'}');
      }
      await sink.close();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report successfully exported to Desktop: TailorSync_Report.csv'), backgroundColor: Color(0xFF2ECC71)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e'), backgroundColor: const Color(0xFFD32F2F)),
        );
      }
    }
    setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Reports & Analytics',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1A237E)),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report Settings coming soon'))),
          ),
        ],
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
                        selectedColor: const Color(0xFF1A237E),
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.inter(color: isSelected ? Colors.white : const Color(0xFF5C6BC0), fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6))),
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
                _KpiCard(icon: Icons.people, title: 'Total Customers', value: _stats?['total_customers']?.toString() ?? '0', iconColor: const Color(0xFF5C6BC0)),
                _KpiCard(icon: Icons.shopping_bag_outlined, title: 'Total Orders', value: _stats?['total_orders']?.toString() ?? '0', iconColor: const Color(0xFF5C6BC0)),
                _KpiCard(icon: Icons.more_horiz, title: 'Ongoing Orders', value: _stats?['ongoing_orders']?.toString() ?? '0', iconColor: const Color(0xFFE67E22)),
                _KpiCard(icon: Icons.check_circle_outline, title: 'Completed Orders', value: _stats?['completed_orders']?.toString() ?? '0', iconColor: const Color(0xFF2ECC71)),
              ],
            ),
            const SizedBox(height: 24),

            // Order Insights
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EAF6)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Insights', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                  const SizedBox(height: 16),
                  Text('Status Breakdown', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0))),
                  const SizedBox(height: 8),
                  
                  // Empty Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: [
                        Expanded(child: Container(height: 12, color: const Color(0xFFE8EAF6))), // Empty
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Legend
                  Row(
                    children: [
                      Expanded(child: _LegendItem(color: const Color(0xFF1A237E), label: 'Sewing (0%)')),
                      Expanded(child: _LegendItem(color: const Color(0xFF5C6BC0), label: 'Cutting (0%)')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _LegendItem(color: const Color(0xFF9FA8DA), label: 'Other (0%)')),
                      Expanded(child: _LegendItem(color: const Color(0xFFE8EAF6), label: 'Ready (0%)')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Rows
                  _InsightRow(label: 'Orders This Week', value: '0', color: const Color(0xFF9FA8DA)),
                  const SizedBox(height: 12),
                  _InsightRow(label: 'Orders This Month', value: '0', color: const Color(0xFFE8EAF6)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Staff Performance
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EAF6)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Staff Performance', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
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
                        padding: const EdgeInsets.only(bottom: 12),
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
            const SizedBox(height: 32),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/orders');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F175A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('View Detailed Report', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _exporting ? null : _exportToCsv,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFE8EAF6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_exporting)
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A237E)))
                    else
                      const Icon(Icons.file_download_outlined, color: Color(0xFF1A237E), size: 18),
                    const SizedBox(width: 8),
                    Text(_exporting ? 'Exporting...' : 'Export to PDF/CSV', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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

  const _KpiCard({required this.icon, required this.title, required this.value, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAF6)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5C6BC0)), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
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
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5C6BC0))),
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
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1A237E))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
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
        CircleAvatar(radius: 20, backgroundColor: color, child: Text(initials, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A237E))),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE8EAF6),
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1A237E)),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$completed', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
            Text('completed', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5C6BC0))),
          ],
        ),
      ],
    );
  }
}
