import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/orders_provider.dart';
import '../../models/order.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
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

  Color _statusColor(String? status) {
    switch (status) {
      case 'Order Received': return const Color(0xFF5C6BC0);
      case 'Cutting': return const Color(0xFFEF5350);
      case 'Sewing': return const Color(0xFFFF9800);
      case 'Fitting': return const Color(0xFF8E44AD);
      case 'Quality Check': return const Color(0xFF26A69A);
      case 'Ready': return const Color(0xFF66BB6A);
      case 'Delivered': return const Color(0xFF78909C);
      default: return const Color(0xFF5C6BC0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        title: Text('Orders', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 19, letterSpacing: -0.3)),
        centerTitle: true,
      ),
      body: asyncOrders.when(
        data: (items) {
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

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ordersProvider);
            },
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 84,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Input
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by Order ID, Customer, or Garment',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E9E9E)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9E9E9E), size: 20),
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
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Horizontal Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', ..._stages].map((f) {
                        final isSelected = _selectedStatusFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: isSelected,
                            onSelected: (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedStatusFilter = f);
                            },
                            selectedColor: AppTheme.primary,
                            backgroundColor: AppTheme.surface,
                            labelStyle: GoogleFonts.inter(
                              color: isSelected ? Colors.white : AppTheme.textCaption,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.divider),
                            ),
                            elevation: isSelected ? 2 : 0,
                            shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // List Content or Empty State
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.tertiary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long, size: 32, color: AppTheme.secondary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              items.isEmpty ? 'No orders yet' : 'No matching orders found',
                              style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              items.isEmpty ? 'Create your first order to get started.' : 'Try adjusting your search query or filters.',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/orders/new'),
                              icon: const Icon(Icons.add),
                              label: const Text('Create First Order'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final Order o = filtered[i];
                        final color = _statusColor(o.status);
                        final stageIdx = _stages.indexOf(o.status ?? 'Order Received');
                        final progress = ((stageIdx >= 0 ? stageIdx : 0) + 1) / _stages.length.toDouble();

                        return _OrderCardItem(
                          key: ValueKey(o.id),
                          order: o,
                          statusColor: color,
                          progressFraction: progress,
                          stageIndex: stageIdx >= 0 ? stageIdx : 0,
                          totalStages: _stages.length,
                          onTap: () => context.go('/orders/details', extra: o),
                          onDelete: () => _confirmDeleteOrder(context, ref, o),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const OrdersListSkeleton(),
        error: (e, st) => Center(
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
              Text('Error loading orders', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(ordersProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text('New Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          HapticFeedback.selectionClick();
          context.go('/orders/new');
        },
      ),
    );
  }

  void _confirmDeleteOrder(BuildContext context, WidgetRef ref, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        content: Text('Are you sure you want to delete order #ORD-${order.id.toString().padLeft(4, '0')}?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppTheme.error));
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

class _OrderCardItem extends StatelessWidget {
  final Order order;
  final Color statusColor;
  final double progressFraction;
  final int stageIndex;
  final int totalStages;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _OrderCardItem({
    super.key,
    required this.order,
    required this.statusColor,
    required this.progressFraction,
    required this.stageIndex,
    required this.totalStages,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials = order.customerName != null && order.customerName!.isNotEmpty
        ? order.customerName!.split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'C';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored left accent strip
            Container(width: 4, color: statusColor),
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Status Chip & Order ID & Delete Icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              order.status ?? 'Pending',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '#ORD-${order.id.toString().padLeft(4, '0')}',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textCaption),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Delete Order',
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 18),
                              onPressed: onDelete,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Garment Type
                      Text(
                        order.garmentType,
                        style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Customer & Priority Row
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Center(
                              child: Text(initials, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.customerName ?? 'Customer #${order.customerId}',
                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textCaption),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (order.priority != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: order.priority == 'High' ? const Color(0xFFFFEBEE) : AppTheme.tertiary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.priority!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: order.priority == 'High' ? const Color(0xFFC62828) : AppTheme.textCaption,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Stage progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Stage Progress',
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF757575)),
                              ),
                              Text(
                                '${stageIndex + 1} of $totalStages',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressFraction,
                              minHeight: 5,
                              backgroundColor: AppTheme.divider,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
