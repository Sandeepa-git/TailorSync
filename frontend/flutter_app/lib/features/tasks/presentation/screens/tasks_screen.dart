import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/skeleton_loading.dart';

class TasksScreen extends ConsumerStatefulWidget {
  final String? initialFilter;

  const TasksScreen({super.key, this.initialFilter});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  late String _selectedFilter;
  Map<String, dynamic>? _user;

  bool _loading = true;
  bool _error = false;
  List<dynamic> _allOrders = [];
  List<dynamic> _tasks = [];

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'All';
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final api = ref.read(apiClientProvider);
      final userResp = await api.getMe();
      final ordersResp = await api.listOrders();

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
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  static const List<String> _stages = [
    'Order Received',
    'Cutting',
    'Sewing',
    'Fitting',
    'Quality Check',
    'Ready',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          centerTitle: true,
          title: Text('Tasks', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        ),
        body: const TasksListSkeleton(),
      );
    }

    if (_error) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          centerTitle: true,
          title: Text('Tasks', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFD32F2F)),
              const SizedBox(height: 16),
              Text('Failed to load tasks', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
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

    // Filter tasks based on selected chip and search query
    final filteredTasks = _tasks.where((t) {
      final status = t['status'] ?? '';
      
      // Category Filter
      bool matchesCategory = true;
      if (_selectedFilter == 'Active') {
        matchesCategory = status != 'Completed' && status != 'On Hold' && status != 'Delivered';
      } else if (_selectedFilter == 'Completed') {
        matchesCategory = status == 'Ready' || status == 'Delivered';
      } else if (_selectedFilter == 'On Hold') {
        matchesCategory = status == 'On Hold';
      } else if (_selectedFilter == 'Due Today') {
        if (t['due_date'] == null) {
          matchesCategory = false;
        } else {
          final due = DateTime.parse(t['due_date']);
          final now = DateTime.now();
          matchesCategory = due.year == now.year && due.month == now.month && due.day == now.day;
        }
      } else if (_selectedFilter == 'Overdue') {
        if (t['due_date'] == null || status == 'Delivered' || status == 'Ready') {
          matchesCategory = false;
        } else {
          final due = DateTime.parse(t['due_date']);
          matchesCategory = due.isBefore(DateTime.now().subtract(const Duration(days: 1)));
        }
      }

      // Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final orderId = '#ORD-${t['id'].toString().padLeft(4, '0')}'.toLowerCase();
        final customer = (t['customer_name'] ?? '').toString().toLowerCase();
        final garment = (t['garment_type'] ?? '').toString().toLowerCase();
        final matchesSearch = orderId.contains(_searchQuery) || customer.contains(_searchQuery) || garment.contains(_searchQuery);
        return matchesCategory && matchesSearch;
      }

      return matchesCategory;
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
        title: Text(
          'Tasks',
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
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 84,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_user?['full_name']?.split(' ').first ?? 'Your'} Tasks',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
              ),
              const SizedBox(height: 16),
              
              // Summary Cards Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = 'Active'),
                      borderRadius: BorderRadius.circular(12),
                      child: _SummaryCard(
                        label: 'Active Tasks',
                        value: '$activeCount',
                        color: const Color(0xFF1A237E),
                        bgColor: Colors.white,
                        borderColor: _selectedFilter == 'Active' ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6),
                        isSelected: _selectedFilter == 'Active',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = 'Due Today'),
                      borderRadius: BorderRadius.circular(12),
                      child: _SummaryCard(
                        label: 'Due Today',
                        value: '$dueTodayCount',
                        color: const Color(0xFF1A237E),
                        bgColor: const Color(0xFFE8EAF6),
                        borderColor: _selectedFilter == 'Due Today' ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6),
                        isSelected: _selectedFilter == 'Due Today',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = 'Overdue'),
                      borderRadius: BorderRadius.circular(12),
                      child: _SummaryCard(
                        label: 'Overdue',
                        value: '$overdueCount',
                        color: overdueCount > 0 ? const Color(0xFFD32F2F) : const Color(0xFF757575),
                        bgColor: overdueCount > 0 ? const Color(0xFFFFEBEE) : Colors.white,
                        borderColor: _selectedFilter == 'Overdue' ? const Color(0xFFD32F2F) : const Color(0xFFE8EAF6),
                        isSelected: _selectedFilter == 'Overdue',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Order ID or Customer Name',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E9E9E)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Color(0xFF757575)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAF6))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAF6))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Active', 'Due Today', 'Overdue', 'Completed', 'On Hold'].map((f) {
                    final isSelected = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: isSelected,
                        onSelected: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFilter = f);
                        },
                        selectedColor: const Color(0xFF1A237E),
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.inter(
                          color: isSelected ? Colors.white : const Color(0xFF5C6BC0),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Tasks List
              if (filteredTasks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_outlined, size: 56, color: Color(0xFF9FA8DA)),
                        const SizedBox(height: 16),
                        Text('No tasks found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5C6BC0))),
                        const SizedBox(height: 4),
                        Text('Try adjusting your search or filters.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E))),
                        if (_selectedFilter != 'All' || _searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedFilter = 'All';
                              });
                            },
                            child: const Text('Clear Filters'),
                          ),
                        ],
                      ],
                    ),
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
                    final currentStage = task['status'] ?? 'Order Received';
                    final stageIdx = _stages.indexOf(currentStage);
                    final isOverdue = task['due_date'] != null &&
                        currentStage != 'Delivered' &&
                        currentStage != 'Ready' &&
                        DateTime.parse(task['due_date']).isBefore(DateTime.now().subtract(const Duration(days: 1)));

                    return RepaintBoundary(
                      child: _TaskCard(
                        key: ValueKey(task['id']),
                        orderId: '#ORD-${task['id'].toString().padLeft(4, '0')}',
                        priority: task['priority'] ?? 'Medium',
                        priorityColor: isHighPriority
                            ? const Color(0xFFD32F2F)
                            : (task['priority'] == 'Medium' ? const Color(0xFFF39C12) : const Color(0xFF757575)),
                        priorityBg: isHighPriority
                            ? const Color(0xFFFFEBEE)
                            : (task['priority'] == 'Medium' ? const Color(0xFFFEF5E7) : const Color(0xFFF5F5F5)),
                        customerName: task['customer_name'] ?? 'Unknown Customer',
                        garmentType: task['garment_type'] ?? 'Unknown',
                        stage: currentStage,
                        stageIndex: stageIdx >= 0 ? stageIdx : 0,
                        totalStages: _stages.length,
                        dueDate: task['due_date'] != null ? task['due_date'].toString().split('T')[0] : 'N/A',
                        isHighPriority: isHighPriority,
                        isOverdue: isOverdue,
                        onUpdateStage: () => _showUpdateStageDialog(context, task),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateStageDialog(BuildContext context, dynamic task) {
    final currentStage = task['status'] ?? 'Order Received';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String selectedStage = currentStage;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(modalContext).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Task Stage',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order #ORD-${task['id'].toString().padLeft(4, '0')} • ${task['customer_name'] ?? 'Customer'}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Flexible Timeline List
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _stages.length,
                      itemBuilder: (context, index) {
                        final stage = _stages[index];
                        final isSelected = stage == selectedStage;
                        final isCurrentInTask = stage == currentStage;
                        final isCompleted = index < _stages.indexOf(selectedStage);

                        return Container(
                          constraints: const BoxConstraints(minHeight: 52),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1A237E).withValues(alpha: 0.06) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1A237E) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() => selectedStage = stage);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  // Leading Status Icon
                                  if (isSelected || isCompleted)
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF1A237E), size: 22)
                                  else if (isCurrentInTask)
                                    const Icon(Icons.radio_button_checked, color: Color(0xFF5C6BC0), size: 22)
                                  else
                                    const Icon(Icons.radio_button_unchecked, color: Color(0xFFB0BEC5), size: 22),
                                  const SizedBox(width: 14),
                                  // Stage Title
                                  Expanded(
                                    child: Text(
                                      stage,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? const Color(0xFF1A237E) : const Color(0xFF37474F),
                                      ),
                                    ),
                                  ),
                                  // Current Tag
                                  if (isCurrentInTask)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A237E),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Current',
                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Pinned Bottom Confirmation Button
                  Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 12,
                      bottom: MediaQuery.of(modalContext).padding.bottom + 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          Navigator.pop(modalContext);
                          if (selectedStage == currentStage) return;

                          try {
                            final api = ref.read(apiClientProvider);
                            await api.updateOrder(task['id'], {
                              'status': selectedStage,
                              'customer_id': task['customer_id'],
                              'garment_type': task['garment_type'],
                            });
                            _loadData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Task stage updated to $selectedStage'),
                                  backgroundColor: const Color(0xFF2ECC71),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to update task stage'),
                                  backgroundColor: Color(0xFFD32F2F),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          'Update Stage',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final bool isSelected;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        boxShadow: isSelected
            ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
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
  final int stageIndex;
  final int totalStages;
  final String dueDate;
  final bool isHighPriority;
  final bool isOverdue;
  final VoidCallback? onUpdateStage;

  const _TaskCard({
    super.key,
    required this.orderId,
    required this.priority,
    required this.priorityColor,
    required this.priorityBg,
    required this.customerName,
    required this.garmentType,
    required this.stage,
    required this.stageIndex,
    required this.totalStages,
    required this.dueDate,
    this.isHighPriority = false,
    this.isOverdue = false,
    this.onUpdateStage,
  });

  @override
  Widget build(BuildContext context) {
    final double progressFraction = ((stageIndex + 1) / totalStages).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (isHighPriority)
              Container(width: 4, color: const Color(0xFFD32F2F)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Order ID and Priority badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          orderId,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF5C6BC0)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: priorityColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            priority,
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Customer & Garment
                    Text(
                      customerName,
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      garmentType,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),

                    // Stage Progress Indicator bar ("Stage X of 7")
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Stage: $stage',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
                            ),
                            Text(
                              '${stageIndex + 1} of $totalStages',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF757575), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressFraction,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE8EAF6),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Due date & Actions row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Due date indicator
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: isOverdue ? const Color(0xFFD32F2F) : const Color(0xFF757575),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Due: $dueDate',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                color: isOverdue ? const Color(0xFFD32F2F) : const Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),

                        // Action buttons
                        Row(
                          children: [
                            Tooltip(
                              message: 'Order Document',
                              child: IconButton(
                                icon: const Icon(Icons.description_outlined, size: 20, color: Color(0xFF757575)),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Viewing order document'), duration: Duration(seconds: 1)),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            OutlinedButton.icon(
                              onPressed: onUpdateStage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1A237E),
                                side: const BorderSide(color: Color(0xFF1A237E), width: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(0, 32),
                              ),
                              icon: const Icon(Icons.swap_horiz, size: 16),
                              label: Text(
                                'Update Stage',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
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
