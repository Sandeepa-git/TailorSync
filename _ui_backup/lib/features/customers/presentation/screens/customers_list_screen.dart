import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/customers_provider.dart';
import '../../models/customer.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
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
    final double width = MediaQuery.of(context).size.width;
    final bool isWide = width >= 768;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        title: Text('Customers', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 19, letterSpacing: -0.3)),
        centerTitle: true,
      ),
      body: async.when(
        data: (items) {
          final filtered = items.where((c) {
            if (_searchQuery.isEmpty) return true;
            final name = c.name.toLowerCase();
            final phone = (c.phone ?? '').toLowerCase();
            final email = (c.email ?? '').toLowerCase();
            return name.contains(_searchQuery) || phone.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search customers by name, phone or email...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E9E9E)),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.secondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
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
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
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
                              child: const Icon(Icons.people_outline, size: 32, color: AppTheme.secondary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              items.isEmpty ? 'No customers found' : 'No matching customers',
                              style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/customers/new'),
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text('Add Customer'),
                            ),
                          ],
                        ),
                      )
                    : isWide
                        ? GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 84),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) => _buildCustomerCard(context, ref, filtered[i]),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 84),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) => _buildCustomerCard(context, ref, filtered[i]),
                          ),
              ),
            ],
          );
        },
        loading: () => const CustomersListSkeleton(),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('New Customer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          HapticFeedback.selectionClick();
          context.go('/customers/new');
        },
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, WidgetRef ref, Customer c) {
    final initials = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        onTap: () => context.go('/customers/edit', extra: c),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(initials, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(c.email ?? 'No email provided', style: GoogleFonts.inter(color: AppTheme.textCaption, fontSize: 12)),
                    if (c.phone != null && c.phone!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 4),
                          Text(c.phone!, style: GoogleFonts.inter(color: const Color(0xFF757575), fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.secondary, size: 16),
                      onPressed: () => context.go('/customers/edit', extra: c),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 16),
                      onPressed: () => _confirmDelete(context, ref, c),
                      padding: EdgeInsets.zero,
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Customer', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        content: Text('Are you sure you want to delete ${customer.name}?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
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
