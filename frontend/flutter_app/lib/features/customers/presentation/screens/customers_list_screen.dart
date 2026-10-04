import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/customers_provider.dart';
import '../../models/customer.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../ui/ui.dart';
import 'package:dio/dio.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(customersProvider);
    final pad = context.pagePadding;

    List<Widget> body(List<Customer> items) {
      final filtered = items.where((c) {
        if (_searchQuery.isEmpty) return true;
        final name = c.name.toLowerCase();
        final phone = (c.phone ?? '').toLowerCase();
        final email = (c.email ?? '').toLowerCase();
        return name.contains(_searchQuery) || phone.contains(_searchQuery) || email.contains(_searchQuery);
      }).toList();

      if (filtered.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: items.isEmpty ? Icons.people_outline_rounded : Icons.person_search_rounded,
              title: items.isEmpty ? 'No customers found' : 'No matching customers',
              message: items.isEmpty ? 'Add your first client to start taking orders.' : 'Try a different name, phone or email.',
              actionLabel: 'Add Customer',
              actionIcon: Icons.person_add_alt_1_rounded,
              onAction: () => context.go('/customers/new'),
            ),
          ),
        ];
      }

      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, Space.xs, pad, Space.sm),
            child: Text(
              '${filtered.length} ${filtered.length == 1 ? 'customer' : 'customers'}',
              style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          sliver: SliverGrid.builder(
            gridDelegate: adaptiveGrid(maxTileWidth: 520, mainAxisExtent: 92, spacing: context.gridGap),
            itemCount: filtered.length,
            itemBuilder: (context, i) => EntranceFade.indexed(
              i,
              key: ValueKey(filtered[i].id),
              child: _buildCustomerCard(context, ref, filtered[i]),
            ),
          ),
        ),
      ];
    }

    return TsScrollPage(
        watermark: TailorAccessory.tape,
      title: 'Customers',
      automaticallyImplyLeading: false,
      padSlivers: false,
      onRefresh: () async => ref.invalidate(customersProvider),
      headerBottom: TsSearchField(
        controller: _searchController,
        hint: 'Search by name, phone or email...',
        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
        onClear: () {
          _searchController.clear();
          setState(() => _searchQuery = '');
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-new-customer',
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('New Customer'),
        onPressed: () {
          HapticFeedback.selectionClick();
          context.go('/customers/new');
        },
      ),
      slivers: async.when(
        data: body,
        loading: () => [const SliverToBoxAdapter(child: CustomersListSkeleton())],
        error: (e, st) => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              title: 'Couldn\'t load customers',
              message: 'Error: $e',
              onRetry: () => ref.invalidate(customersProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, WidgetRef ref, Customer c) {
    final cs = context.colors;
    return TsCard(
      onTap: () => _showCustomerDetails(context, ref, c),
      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.xxs, Space.sm),
      child: Row(
        children: [
          Hero(tag: 'customer-${c.id}', child: InitialsAvatar(name: c.name, size: 48)),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(c.email ?? 'No email provided', style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (c.phone != null && c.phone!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(c.phone!, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'View details',
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            onPressed: () => _showCustomerDetails(context, ref, c),
          ),
          IconButton(
            tooltip: 'Edit ${c.name}',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => context.go('/customers/edit', extra: c),
          ),
          IconButton(
            tooltip: 'Delete ${c.name}',
            icon: Icon(Icons.delete_outline_rounded, size: 20, color: cs.error),
            onPressed: () => _confirmDelete(context, ref, c),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, WidgetRef ref, Customer customer) {
    showTsSheet(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final text = Theme.of(ctx).textTheme;
        return Consumer(
          builder: (context, ref, child) {
            final ordersAsync = ref.watch(ordersProvider);
            return Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InitialsAvatar(name: customer.name, size: 64),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer.name, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            if (customer.email != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.email_outlined, size: 16, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Text(customer.email!, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ],
                            if (customer.phone != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: 16, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Text(customer.phone!, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Order Statistics', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ordersAsync.when(
                    data: (orders) {
                      final customerOrders = orders.where((o) => o.customerId == customer.id).toList();
                      final total = customerOrders.length;
                      final active = customerOrders.where((o) => o.status != 'Delivered' && o.status != 'Ready').length;
                      final completed = customerOrders.where((o) => o.status == 'Delivered' || o.status == 'Ready').length;
                      
                      return Row(
                        children: [
                          Expanded(child: _StatBox(title: 'Total', value: total.toString(), color: cs.primary)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatBox(title: 'Active', value: active.toString(), color: Colors.orange)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatBox(title: 'Completed', value: completed.toString(), color: Colors.green)),
                        ],
                      );
                    },
                    loading: () => const Center(child: ScissorLoader()),
                    error: (e, st) => Text('Error loading orders: $e', style: text.bodySmall?.copyWith(color: cs.error)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Customer customer) {
    showTsDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.person_remove_outlined, color: Theme.of(ctx).colorScheme.error, size: 32),
        title: const Text('Delete Customer', textAlign: TextAlign.center),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error, foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(apiClientProvider).deleteCustomer(customer.id!);
                ref.invalidate(customersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted')));
                }
              } catch (e) {
                String err = 'Failed to delete customer';
                if (e is DioException) {
                  if (e.response?.data != null) {
                    final data = e.response!.data;
                    if (data is Map && data.containsKey('detail')) {
                      err = data['detail'].toString();
                    } else if (data is String && data.isNotEmpty) {
                      err = data;
                    }
                  } else if (e.message != null && e.message!.isNotEmpty) {
                    err = e.message!;
                  }
                } else {
                  err = e.toString();
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

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatBox({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
