import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/orders_provider.dart';
import '../../models/order.dart';
import '../../../../core/network/providers/api_provider.dart';
import 'package:dio/dio.dart';

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ordersProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Orders', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long, size: 64, color: Color(0xFFE8EAF6)),
                  const SizedBox(height: 12),
                  Text('No orders yet', style: GoogleFonts.inter(color: const Color(0xFF5C6BC0), fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/orders/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Order'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final Order o = items[i];
              final color = _statusColor(o.status);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => context.go('/orders/details', extra: o),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(o.status ?? 'Pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                          ),
                          const Spacer(),
                          Text('#${o.id}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5C6BC0))),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _confirmDeleteOrder(context, ref, o),
                            child: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F), size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Garment & Customer
                      Text(o.garmentType, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: Color(0xFF5C6BC0)),
                          const SizedBox(width: 4),
                          Text(o.customerName ?? 'Customer #${o.customerId}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5C6BC0))),
                          if (o.priority != null) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: o.priority == 'High' ? const Color(0xFFFF6B6B).withOpacity(0.1) : const Color(0xFFE8EAF6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(o.priority!, style: TextStyle(fontSize: 10, color: o.priority == 'High' ? const Color(0xFFFF6B6B) : const Color(0xFF5C6BC0))),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('New Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        onPressed: () => context.go('/orders/new'),
      ),
    );
  }

  void _confirmDeleteOrder(BuildContext context, WidgetRef ref, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete order #${order.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(apiClientProvider).deleteOrder(order.id!);
                ref.invalidate(ordersProvider);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order deleted')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete order'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
