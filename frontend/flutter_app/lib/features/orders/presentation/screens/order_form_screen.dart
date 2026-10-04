import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../ui/ui.dart';
import '../providers/orders_provider.dart';
import '../../../customers/presentation/providers/customers_provider.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _description = TextEditingController();
  int? _selectedCustomerId;
  bool _loading = false;
  void _save() async {
    if (_description.text.isEmpty || _selectedCustomerId == null) return;
    setState(() => _loading = true);
    final api = ref.read(apiClientProvider);
    try {
      await api.createOrder({
        'customer_id': _selectedCustomerId,
        'garment_type': _description.text,
        'occasion': 'Everyday Wear',
      });
      ref.invalidate(ordersProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Order')),
      body: TsFormBody(
        children: [
          TsCard(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                customersAsync.when(
                  data: (customers) {
                    if (customers.isEmpty) {
                      return Text('Please add a customer first.', style: TextStyle(color: context.colors.error));
                    }
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Select Customer', prefixIcon: Icon(Icons.person_outline_rounded)),
                      value: _selectedCustomerId,
                      isExpanded: true,
                      items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setState(() => _selectedCustomerId = val),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error loading customers: $e'),
                ),
                const SizedBox(height: Space.md),
                TextField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Garment Type', hintText: 'e.g. Navy Blue Suit', prefixIcon: Icon(Icons.checkroom_rounded)),
                  maxLines: 1,
                ),
                const SizedBox(height: Space.xl),
                TsButton(label: 'Create Order', loading: _loading, onPressed: _loading ? null : _save),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
