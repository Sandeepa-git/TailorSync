import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/customer.dart';
import '../../../../core/network/providers/api_provider.dart';

final customersProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.listCustomers();
  final data = resp.data as List<dynamic>;
  return data.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
});
