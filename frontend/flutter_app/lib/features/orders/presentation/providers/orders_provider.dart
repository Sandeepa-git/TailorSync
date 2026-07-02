import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../../../core/network/providers/api_provider.dart';

final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.listOrders();
  final data = resp.data as List<dynamic>;
  return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
});
