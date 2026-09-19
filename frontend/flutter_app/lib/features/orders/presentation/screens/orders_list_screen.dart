import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/orders_provider.dart';
import '../../models/order.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/skeleton_loading.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
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

  Color _statusColor(String? status) {
    switch (status) {
      case 'Order Received': return const Color(0xFF5C6BC0);
      case 'Cutting': return const Color(0xFFFF6B6B);
      case 'Sewing': return const Color(0xFFF39C12);
      case 'Fitting': return const Color(0xFF8E44AD);
      case 'Quality Check': return const Color(0xFF16A085);
      case 'Ready': return const Color(0xFF2ECC71);
      case 'Delivered': return const Color(0xFF7F8C8D);
      default: return const Color(0xFF5C6BC0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: Text('Orders', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
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
                  // Search Input
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Order ID, Customer, or Garment',
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
                  const SizedBox(height: 12),

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

                  // List Content or Empty State
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long, size: 56, color: Color(0xFF9FA8DA)),
                            const SizedBox(height: 12),
                            Text(
                              items.isEmpty ? 'No orders yet' : 'No matching orders found',
                              style: GoogleFonts.inter(color: const Color(0xFF5C6BC0), fontSize: 16, fontWeight: FontWeight.bold),
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
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFD32F2F)),
              const SizedBox(height: 16),
              Text('Error loading orders', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('New Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
        content: Text('Are you sure you want to delete order #ORD-${order.id.toString().padLeft(4, '0')}?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(apiClientProvider).deleteOrder(order.id!);
                ref.invalidate(ordersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order deleted')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete order'), backgroundColor: Colors.red));
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Status Chip & Order ID & Delete Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status ?? 'Pending',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#ORD-${order.id.toString().padLeft(4, '0')}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF5C6BC0)),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Delete Order',
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F), size: 18),
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
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Customer & Priority Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFFE8EAF6),
                    child: Text(initials, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.customerName ?? 'Customer #${order.customerId}',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5C6BC0)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (order.priority != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.priority == 'High' ? const Color(0xFFFFEBEE) : const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.priority!,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: order.priority == 'High' ? const Color(0xFFD32F2F) : const Color(0xFF5C6BC0),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

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
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE8EAF6),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
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
