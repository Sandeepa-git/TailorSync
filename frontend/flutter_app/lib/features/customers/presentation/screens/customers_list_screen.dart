import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/customers_provider.dart';
import '../../models/customer.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import 'package:dio/dio.dart';

class CustomersListScreen extends ConsumerWidget {
  const CustomersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customersProvider);
    final double width = MediaQuery.of(context).size.width;
    final bool isWide = width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: Text('Customers', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
        centerTitle: true,
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Color(0xFFE8EAF6)),
                  const SizedBox(height: 12),
                  Text('No customers found.', style: GoogleFonts.inter(color: const Color(0xFF5C6BC0), fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/customers/new'),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add Customer'),
                  ),
                ],
              ),
            );
          }

          if (isWide) {
            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final Customer c = items[i];
                return _buildCustomerCard(context, ref, c);
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final Customer c = items[i];
              return _buildCustomerCard(context, ref, c);
            },
          );
        },
        loading: () => const CustomersListSkeleton(),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('New Customer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        onPressed: () => context.go('/customers/new'),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, WidgetRef ref, Customer c) {
    final initials = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(c.email ?? 'No email provided', style: GoogleFonts.inter(color: const Color(0xFF5C6BC0), fontSize: 13)),
            if (c.phone != null && c.phone!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(c.phone!, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12)),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF5C6BC0)),
              onPressed: () => context.go('/customers/edit', extra: c),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
              onPressed: () => _confirmDelete(context, ref, c),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(apiClientProvider).deleteCustomer(customer.id!);
                ref.invalidate(customersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted')));
                }
              } catch (e) {
                String err = 'Failed to delete';
                if (e is DioException && e.response != null) {
                  err = e.response?.data['detail'] ?? err;
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
