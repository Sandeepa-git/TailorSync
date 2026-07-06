import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/providers/api_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _selectedFilter = 'All';
  Map<String, dynamic>? _user;

  bool _loading = true;
  List<dynamic> _allOrders = [];
  List<dynamic> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ref.read(apiClientProvider);
      final userResp = await api.getMe();
      final ordersResp = await api.dio.get('/orders');
      
      if (mounted) {
        setState(() {
          _user = userResp.data;
          _allOrders = ordersResp.data;
          
          if (_user?['role'] == 'staff') {
            _tasks = _allOrders.where((o) => o['staff_id'] == _user?['id']).toList();
          } else {
            _tasks = _allOrders.where((o) => o['status'] != 'Delivered').toList();
          }
          
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Filter tasks based on selected chip
    final filteredTasks = _tasks.where((t) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Active') return t['status'] != 'Completed' && t['status'] != 'On Hold' && t['status'] != 'Delivered';
      if (_selectedFilter == 'Completed') return t['status'] == 'Ready' || t['status'] == 'Delivered';
      if (_selectedFilter == 'On Hold') return t['status'] == 'On Hold';
      return true;
    }).toList();

    // Stats
    final activeCount = _tasks.where((t) => t['status'] != 'Delivered' && t['status'] != 'Ready').length;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => context.go('/home'),
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF5C6BC0),
              child: Text(
                _user?['full_name'] != null && _user!['full_name'].isNotEmpty 
                  ? _user!['full_name'][0].toUpperCase() 
                  : 'M',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text('${_user?['full_name']?.split(' ').first ?? 'Your'} Tasks', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
            const SizedBox(height: 16),
            
            // Summary Cards Row
            Row(
              children: [
                Expanded(child: _SummaryCard(label: 'Active Tasks', value: '$activeCount', color: const Color(0xFF1A237E), bgColor: Colors.white, borderColor: const Color(0xFFE8EAF6))),
                const SizedBox(width: 8),
                Expanded(child: _SummaryCard(label: 'Due Today', value: '$dueTodayCount', color: const Color(0xFF9FA8DA), bgColor: const Color(0xFF1A237E), borderColor: const Color(0xFF1A237E))),
                const SizedBox(width: 8),
                Expanded(child: _SummaryCard(label: 'Overdue', value: '$overdueCount', color: const Color(0xFFD32F2F), bgColor: const Color(0xFFFFEBEE), borderColor: const Color(0xFFFFEBEE))),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by Order ID or Customer Name',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E9E9E)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
                filled: true,
                fillColor: const Color(0xFFEEEEEE),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Active', 'Completed', 'On Hold'].map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (v) => setState(() => _selectedFilter = f),
                      selectedColor: const Color(0xFF1A237E),
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.inter(color: isSelected ? Colors.white : const Color(0xFF5C6BC0), fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),

            // Tasks List
            if (filteredTasks.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF9FA8DA)),
                    const SizedBox(height: 16),
                    Text('No tasks available', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF5C6BC0))),
                    Text('New orders will appear here.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E))),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTasks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  final isHighPriority = task['priority'] == 'High';
                  return _TaskCard(
                    orderId: '#ORD-${task['id'].toString().padLeft(4, '0')}',
                    priority: task['priority'] ?? 'Medium',
                    priorityColor: isHighPriority ? const Color(0xFFD32F2F) : const Color(0xFF1A237E),
                    priorityBg: isHighPriority ? const Color(0xFFFFEBEE) : const Color(0xFFE8EAF6),
                    customerName: task['customer_name'] ?? 'Unknown Customer',
                    garmentType: task['garment_type'] ?? 'Unknown',
                    stage: task['status'] ?? 'Order Received',
                    stageColor: const Color(0xFF1A237E),
                    stageBg: const Color(0xFFE8EAF6),
                    stageIcon: Icons.cut,
                    dueDate: task['due_date'] != null ? task['due_date'].toString().split('T')[0] : 'N/A',
                    isHighPriority: isHighPriority,
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.bgColor, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color == Colors.white ? Colors.white70 : color.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String orderId;
  final String priority;
  final Color priorityColor;
  final Color priorityBg;
  final String customerName;
  final String garmentType;
  final String stage;
  final Color stageColor;
  final Color stageBg;
  final IconData stageIcon;
  final String dueDate;
  final bool isHighPriority;

  const _TaskCard({
    required this.orderId,
    required this.priority,
    required this.priorityColor,
    required this.priorityBg,
    required this.customerName,
    required this.garmentType,
    required this.stage,
    required this.stageColor,
    required this.stageBg,
    required this.stageIcon,
    required this.dueDate,
    this.isHighPriority = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAF6)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (isHighPriority)
              Container(width: 4, color: const Color(0xFF1A237E)), // Left edge indicator
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(orderId, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF5C6BC0))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: priorityBg == Colors.white ? const Color(0xFFE0E0E0) : priorityBg),
                          ),
                          child: Text(priority, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: priorityColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(customerName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF212121))),
                    Text(garmentType, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF757575))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: stageBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(stageIcon, size: 14, color: stageColor),
                              const SizedBox(width: 6),
                              Text(stage, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: stageColor)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.calendar_today, size: 14, color: const Color(0xFF757575)),
                        const SizedBox(width: 4),
                        Text('Due: $dueDate', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF757575))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('Update Stage', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF1A237E)),
                          ],
                        ),
                        Icon(Icons.description_outlined, size: 20, color: const Color(0xFF757575)),
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
