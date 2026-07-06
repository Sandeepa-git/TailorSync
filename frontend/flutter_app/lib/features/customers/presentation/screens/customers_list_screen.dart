import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/customers_provider.dart';
import '../../models/customer.dart';
import '../../../../core/network/providers/api_provider.dart';
import 'package:dio/dio.dart';

class CustomersListScreen extends ConsumerWidget {
  const CustomersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customersProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Customers', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text('No customers found.', style: GoogleFonts.inter(color: const Color(0xFF5C6BC0))));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final Customer c = items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF5C6BC0),
                    child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                  subtitle: Text(c.email ?? 'No email provided', style: GoogleFonts.inter(color: const Color(0xFF5C6BC0), fontSize: 13)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF5C6BC0)),
                        onPressed: () => context.go('/customers/edit', extra: c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Color(0xFFD32F2F)),
                        onPressed: () => _confirmDelete(context, ref, c),
                      ),
                    ],
                  ),
                  onTap: () {},
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => context.go('/customers/new'),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted')));
              } catch (e) {
                String err = 'Failed to delete';
                if (e is DioException && e.response != null) {
                  err = e.response?.data['detail'] ?? err;
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
