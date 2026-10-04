import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

final userProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final resp = await api.getMe();
    return resp.data as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
});
