import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/orders_provider.dart';
import '../../models/order.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/network/providers/user_provider.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../ui/ui.dart';
import 'package:dio/dio.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  Timer? _pollingTimer;
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
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
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(ordersProvider);
      }
    });
  }
  @override
  void dispose() {
    _pollingTimer?.cancel();
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

  // UI-only: extended FAB collapses while scrolling down.
  bool _fabExtended = true;

  Color _statusColor(String? status) => StageStyle.color(context, status);

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(ordersProvider);
    final asyncUser = ref.watch(userProvider);
    final isOwner = asyncUser.value?['role'] == 'OWNER';
    final pad = context.pagePadding;

    Widget content(List<Order> items) {
      final filtered = items.where((o) {
        bool matchesStatus = true;
        if (_selectedStatusFilter != 'All') {
          matchesStatus = o.status == _selectedStatusFilter;
        }

          bool matchesSearch = true;
          if (_searchQuery.isNotEmpty) {
            final idStr = '#ORD-${o.id.toString().padLeft(4, '0')}'.toLowerCase();
            final cust = (o.customerName ?? '').toLowerCase();
            final garm = o.garmentType.toLowerCase();
            matchesSearch = idStr.contains(_searchQuery) || cust.contains(_searchQuery) || garm.contains(_searchQuery);
          }

        return matchesStatus && matchesSearch;
      }).toList();

      if (filtered.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: items.isEmpty ? Icons.receipt_long_rounded : Icons.search_off_rounded,
            title: items.isEmpty ? 'It\'s quiet in here...' : 'Hmm, we couldn\'t find that.',
            message: items.isEmpty
                ? 'Looks like you don\'t have any orders yet.\nLet\'s create your first one and get to work!'
                : 'Try adjusting your search query or filters to find what you need.',
            actionLabel: 'Create First Order',
            actionIcon: Icons.add_rounded,
            onAction: () => context.go('/orders/new'),
          ),
        );
      }

      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: pad),
        sliver: SliverList.separated(
          itemCount: filtered.length,
          separatorBuilder: (context, index) => SizedBox(height: context.gridGap),
          itemBuilder: (context, i) {
            final Order o = filtered[i];
            final color = _statusColor(o.status);
            final stageIdx = _stages.indexOf(o.status ?? 'Order Received');
            final progress = ((stageIdx >= 0 ? stageIdx : 0) + 1) / _stages.length.toDouble();

            final card = _OrderCardItem(
              order: o,
              statusColor: color,
              progressFraction: progress,
              stageIndex: stageIdx >= 0 ? stageIdx : 0,
              totalStages: _stages.length,
              isOwner: isOwner,
              onTap: () => context.go('/orders/details', extra: o),
              onDelete: () => _confirmDeleteOrder(context, ref, o),
            );

            return EntranceFade.indexed(
              i,
              key: ValueKey(o.id),
              child: isOwner
                  ? _SwipeToDelete(
                      key: ValueKey('swipe-${o.id}'),
                      onSwipe: () => _confirmDeleteOrder(context, ref, o),
                      child: card,
                    )
                  : card,
            );
          },
        ),
      );
    }

    return NotificationListener<UserScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical) {
          final ext = n.direction != ScrollDirection.reverse;
          if (ext != _fabExtended && n.direction != ScrollDirection.idle) setState(() => _fabExtended = ext);
        }
        return false;
      },
      child: TsScrollPage(
        watermark: TailorAccessory.hanger, watermarkLeft: true,
        title: 'Orders',
        automaticallyImplyLeading: false,
        padSlivers: false,
        onRefresh: () async {
          ref.invalidate(ordersProvider);
        },
        headerBottom: TsSearchField(
          controller: _searchController,
          hint: 'Find an order, customer, or garment...',
          onClear: () {
            _searchController.clear();
            setState(() => _searchQuery = '');
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab-new-order',
          isExtended: _fabExtended,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Order'),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.go('/orders/new');
          },
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: Space.xs, bottom: Space.sm),
              child: FilterChipsRow(
                padding: EdgeInsets.symmetric(horizontal: pad),
                options: ['All', ..._stages],
                selected: _selectedStatusFilter,
                onSelected: (f) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedStatusFilter = f);
                },
              ),
            ),
          ),
          ...asyncOrders.when(
            data: (items) => [content(items)],
            loading: () => [const SliverToBoxAdapter(child: OrdersListSkeleton())],
            error: (e, st) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(
                  title: 'Error loading orders',
                  onRetry: () => ref.invalidate(ordersProvider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteOrder(BuildContext context, WidgetRef ref, Order order) {
    showTsDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: Theme.of(ctx).colorScheme.error, size: 32),
        title: const Text('Delete Order', textAlign: TextAlign.center),
        content: Text('Are you sure you want to delete order #ORD-${order.id.toString().padLeft(4, '0')}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error, foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(apiClientProvider).deleteOrder(order.id!);
                ref.invalidate(ordersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order deleted')));
                }
              } catch (e) {
                String err = 'Failed to delete order';
                if (e is DioException && e.response?.data != null) {
                  final data = e.response!.data;
                  if (data is Map && data.containsKey('detail')) {
                    err = data['detail'].toString();
                  }
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Theme.of(context).colorScheme.error));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Swipe left to reveal a delete action. The swipe only opens the existing
/// confirmation flow; the card always springs back.
class _SwipeToDelete extends StatelessWidget {
  final Widget child;
  final VoidCallback onSwipe;
  const _SwipeToDelete({super.key, required this.child, required this.onSwipe});

  @override
  Widget build(BuildContext context) {
    final s = context.status;
    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.35},
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        onSwipe();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        decoration: BoxDecoration(color: s.dangerContainer, borderRadius: Radii.brLg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Delete', style: context.text.labelLarge?.copyWith(color: s.onDangerContainer)),
            const SizedBox(width: Space.xs),
            Icon(Icons.delete_outline_rounded, color: s.onDangerContainer),
          ],
        ),
      ),
      child: child,
    );
  }
}

class _OrderCardItem extends StatelessWidget {
  final Order order;
  final Color statusColor;
  final double progressFraction;
  final int stageIndex;
  final int totalStages;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _OrderCardItem({
    required this.order,
    required this.statusColor,
    required this.progressFraction,
    required this.stageIndex,
    required this.totalStages,
    required this.isOwner,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final customer = order.customerName ?? 'Customer #${order.customerId}';
    return TsCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: Radii.brLg,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.xs, Space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: StagePill(status: order.status ?? 'Pending', dense: true)),
                          const SizedBox(width: Space.xs),
                          const Spacer(),
                          Text(
                            '#ORD-${order.id.toString().padLeft(4, '0')}',
                            style: context.text.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          if (isOwner)
                            IconButton(
                              tooltip: 'Delete Order',
                              icon: Icon(Icons.delete_outline_rounded, color: cs.error, size: 20),
                              onPressed: onDelete,
                            )
                          else
                            const SizedBox(width: Space.xs, height: kMinTouch),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: Space.xs),
                        child: Text(
                          order.garmentType,
                          style: context.text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      Padding(
                        padding: const EdgeInsets.only(right: Space.xs),
                        child: Row(
                          children: [
                            InitialsAvatar(name: customer, size: 26),
                            const SizedBox(width: Space.xs),
                            Expanded(
                              child: Text(customer, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            if (order.priority != null) ...[
                              const SizedBox(width: Space.xs),
                              StatusPill(
                                label: order.priority!,
                                color: StageStyle.priorityColor(context, order.priority),
                                icon: order.priority == 'High' ? Icons.local_fire_department_rounded : null,
                                dense: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      Padding(
                        padding: const EdgeInsets.only(right: Space.xs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('Stage progress', style: context.text.labelSmall?.copyWith(color: cs.onSurfaceVariant))),
                                Text(
                                  '${stageIndex + 1} of $totalStages',
                                  style: context.text.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            StageProgressBar(value: progressFraction, color: statusColor),
                          ],
                        ),
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
