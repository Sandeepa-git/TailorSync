import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../orders/models/order.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../ui/ui.dart';

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

          if (_user?['role'] == 'staff' || _user?['role'] == 'STAFF') {
            _tasks = _allOrders.where((o) => o['staff_id'] == _user?['id']).toList();
          } else {
            _tasks = List.from(_allOrders);
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
  Future<void> _updateDueDateOnly(BuildContext context, dynamic task) async {
    final currentDueDateStr = task['due_date']?.toString();
    final initialDate = currentDueDateStr != null ? DateTime.tryParse(currentDueDateStr) : DateTime.now().add(const Duration(days: 7));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      final newDateIso = picked.toIso8601String();
      if (currentDueDateStr?.split('T')[0] == newDateIso.split('T')[0]) return; // no change
      
      try {
        final api = ref.read(apiClientProvider);
        await api.updateOrder(task['id'], {
          'due_date': newDateIso,
        });
        ref.read(refreshTriggerProvider.notifier).state++;
        _loadData();
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Due date updated'),
               backgroundColor: Color(0xFF2ECC71),
               behavior: SnackBarBehavior.floating,
             ),
           );
        }
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Failed to update due date'),
               backgroundColor: AppTheme.error,
               behavior: SnackBarBehavior.floating,
             ),
           );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return TsScrollPage(
        watermark: TailorAccessory.spool, watermarkLeft: true,
        title: 'Tasks',
        automaticallyImplyLeading: false,
        padSlivers: false,
        slivers: const [SliverToBoxAdapter(child: TasksListSkeleton())],
      );
    }

    if (_error) {
      return TsScrollPage(
        watermark: TailorAccessory.spool, watermarkLeft: true,
        title: 'Tasks',
        automaticallyImplyLeading: false,
        onRefresh: _loadData,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(title: 'Failed to load tasks', onRetry: _loadData),
          ),
        ],
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

    final pad = context.pagePadding;
    final st = context.status;

    return TsScrollPage(
        watermark: TailorAccessory.spool, watermarkLeft: true,
      title: '${_user?['full_name']?.split(' ').first ?? 'Your'} Tasks',
      automaticallyImplyLeading: false,
      padSlivers: false,
      onRefresh: _loadData,
      headerBottom: TsSearchField(
        controller: _searchController,
        hint: 'Search by Order ID or Customer Name',
        onClear: () {
          _searchController.clear();
          setState(() => _searchQuery = '');
        },
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, Space.xs, pad, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Active Tasks',
                    value: activeCount,
                    icon: Icons.work_outline_rounded,
                    color: st.info,
                    isSelected: _selectedFilter == 'Active',
                    onTap: () => setState(() => _selectedFilter = 'Active'),
                  ),
                ),
                SizedBox(width: context.gridGap),
                Expanded(
                  child: _SummaryCard(
                    label: 'Due Today',
                    value: dueTodayCount,
                    icon: Icons.schedule_rounded,
                    color: st.warning,
                    isSelected: _selectedFilter == 'Due Today',
                    onTap: () => setState(() => _selectedFilter = 'Due Today'),
                  ),
                ),
                SizedBox(width: context.gridGap),
                Expanded(
                  child: _SummaryCard(
                    label: 'Overdue',
                    value: overdueCount,
                    icon: Icons.warning_amber_rounded,
                    color: overdueCount > 0 ? st.danger : context.colors.onSurfaceVariant,
                    isSelected: _selectedFilter == 'Overdue',
                    onTap: () => setState(() => _selectedFilter = 'Overdue'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: FilterChipsRow(
              padding: EdgeInsets.symmetric(horizontal: pad),
              options: const ['All', 'Active', 'Due Today', 'Overdue', 'Completed', 'On Hold'],
              selected: _selectedFilter,
              onSelected: (f) {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = f);
              },
            ),
          ),
        ),
        if (filteredTasks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.assignment_turned_in_outlined,
              title: 'No tasks found',
              message: 'Try adjusting your search or filters.',
              actionLabel: (_selectedFilter != 'All' || _searchQuery.isNotEmpty) ? 'Clear Filters' : null,
              actionIcon: Icons.filter_alt_off_rounded,
              onAction: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                });
              },
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverList.separated(
              itemCount: filteredTasks.length,
              separatorBuilder: (context, index) => SizedBox(height: context.gridGap),
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                final isHighPriority = task['priority'] == 'High';
                final currentStage = task['status'] ?? 'Order Received';
                final stageIdx = _stages.indexOf(currentStage);
                final parsedDate = task['due_date'] != null ? DateTime.tryParse(task['due_date'].toString()) : null;
                final isOverdue = parsedDate != null &&
                    currentStage != 'Delivered' &&
                    currentStage != 'Ready' &&
                    parsedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

                return EntranceFade.indexed(
                  index,
                  key: ValueKey(task['id']),
                  child: RepaintBoundary(
                    child: _TaskCard(
                      orderId: '#ORD-${task['id'].toString().padLeft(4, '0')}',
                      priority: task['priority'] ?? 'Medium',
                      priorityColor: StageStyle.priorityColor(context, task['priority'] ?? 'Medium'),
                      customerName: task['customer_name'] ?? 'Unknown Customer',
                      garmentType: task['garment_type'] ?? 'Unknown',
                      stage: currentStage,
                      stageIndex: stageIdx >= 0 ? stageIdx : 0,
                      totalStages: _stages.length,
                      dueDate: task['due_date'] != null ? task['due_date'].toString().split('T')[0] : 'N/A',
                      isHighPriority: isHighPriority,
                      isOverdue: isOverdue,
                      onUpdateStage: () => _showUpdateStageDialog(context, task),
                      onUpdateDueDate: () => _updateDueDateOnly(context, task),
                      onViewDocument: () {
                        HapticFeedback.selectionClick();
                        final orderObj = Order.fromJson(task);
                        context.push('/orders/details', extra: orderObj);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showUpdateStageDialog(BuildContext context, dynamic task) {
    final currentStage = task['status'] ?? 'Order Received';
    String selectedStage = currentStage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      sheetAnimationStyle: AnimationStyle(duration: Motion.of(context, Motion.long), curve: Motion.emphasizedDecelerate),
      builder: (ctx) {
        String selectedStage = currentStage;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final cs = Theme.of(modalContext).colorScheme;
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
                          style: Theme.of(modalContext).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order #ORD-${task['id'].toString().padLeft(4, '0')} • ${task['customer_name'] ?? 'Customer'}',
                          style: Theme.of(modalContext).textTheme.bodySmall,
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

                        return AnimatedContainer(
                          duration: Motion.of(context, Motion.short),
                          curve: Motion.standard,
                          constraints: const BoxConstraints(minHeight: 52),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? cs.primaryContainer.withValues(alpha: 0.6) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? cs.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() => selectedStage = stage);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  // Leading Status Icon
                                  AnimatedSwitcher(
                                    duration: Motion.of(context, Motion.short),
                                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                                    child: (isSelected || isCompleted)
                                        ? Icon(Icons.check_circle_rounded, key: const ValueKey('done'), color: cs.primary, size: 22)
                                        : isCurrentInTask
                                            ? Icon(Icons.radio_button_checked, key: const ValueKey('cur'), color: cs.secondary, size: 22)
                                            : Icon(Icons.radio_button_unchecked, key: const ValueKey('todo'), color: cs.outline, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  // Stage Title
                                  Expanded(
                                    child: Text(
                                      stage,
                                      style: Theme.of(modalContext).textTheme.bodyLarge?.copyWith(
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                        color: isSelected ? cs.primary : cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  // Current Tag
                                  if (isCurrentInTask)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Current',
                                        style: Theme.of(modalContext).textTheme.labelSmall?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w800),
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
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                        ),
                        onPressed: () async {
                          Navigator.pop(modalContext);
                          if (selectedStage == currentStage) return;

                          try {
                            final api = ref.read(apiClientProvider);
                            final updateData = <String, dynamic>{
                              'status': selectedStage,
                            };
                            await api.updateOrder(task['id'], updateData);
                            ref.read(refreshTriggerProvider.notifier).state++;
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
                                  backgroundColor: AppTheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Update Stage'),
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
  final int value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label: $value',
      excludeSemantics: true,
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.short),
          curve: Motion.standard,
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: context.isDark ? 0.22 : 0.10) : cs.surfaceContainerLowest,
            borderRadius: Radii.brLg,
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.6) : cs.outlineVariant.withValues(alpha: 0.45),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6))] : Shadows.soft(cs),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: icon, color: color, size: 30),
              const SizedBox(height: Space.xs),
              AnimatedCount(value: value, style: context.text.titleLarge?.copyWith(color: color)),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String orderId;
  final String priority;
  final Color priorityColor;
  final String customerName;
  final String garmentType;
  final String stage;
  final int stageIndex;
  final int totalStages;
  final String dueDate;
  final bool isHighPriority;
  final bool isOverdue;
  final VoidCallback? onUpdateStage;
  final VoidCallback? onUpdateDueDate;
  final VoidCallback? onViewDocument;

  const _TaskCard({
    required this.orderId,
    required this.priority,
    required this.priorityColor,
    required this.customerName,
    required this.garmentType,
    required this.stage,
    required this.stageIndex,
    required this.totalStages,
    required this.dueDate,
    this.isHighPriority = false,
    this.isOverdue = false,
    this.onUpdateStage,
    this.onUpdateDueDate,
    this.onViewDocument,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final st = context.status;
    final double progressFraction = ((stageIndex + 1) / totalStages).clamp(0.0, 1.0);
    final stageColor = StageStyle.color(context, stage);
    final dueColor = isOverdue ? st.danger : cs.onSurfaceVariant;

    return TsCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: Radii.brLg,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isHighPriority) Container(width: 4, color: st.danger),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.sm, Space.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(orderId, style: context.text.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                          const Spacer(),
                          if (isOverdue) ...[
                            StatusPill(label: 'OVERDUE', color: st.danger, icon: Icons.error_outline_rounded, dense: true),
                            const SizedBox(width: 6),
                          ],
                          StatusPill(label: priority, color: priorityColor, dense: true),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      Text(customerName, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(garmentType, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: Space.sm),
                      Row(
                        children: [
                          Icon(StageStyle.icon(stage), size: 14, color: stageColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stage,
                              style: context.text.labelMedium?.copyWith(color: stageColor, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('${stageIndex + 1} of $totalStages', style: context.text.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      StageProgressBar(value: progressFraction, color: stageColor),
                      const SizedBox(height: Space.xs),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 0,
                        spacing: Space.xs,
                        children: [
                          TextButton.icon(
                            onPressed: onUpdateDueDate,
                            style: TextButton.styleFrom(
                              foregroundColor: dueColor,
                              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                            ),
                            icon: const Icon(Icons.event_rounded, size: 16),
                            label: Text(
                              'Due: $dueDate',
                              style: context.text.labelMedium?.copyWith(
                                color: dueColor,
                                fontWeight: isOverdue ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Order Document',
                                icon: Icon(Icons.description_outlined, size: 20, color: cs.onSurfaceVariant),
                                onPressed: onViewDocument,
                              ),
                              FilledButton.tonalIcon(
                                onPressed: onUpdateStage,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                                  shape: RoundedRectangleBorder(borderRadius: Radii.brSm),
                                ),
                                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                                label: const Text('Update Stage'),
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
      ),
    );
  }
}
