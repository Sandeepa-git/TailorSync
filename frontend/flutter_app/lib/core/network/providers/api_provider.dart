import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';

final apiClientProvider = Provider((ref) {
  return ApiClient.create('http://10.18.157.15:8000/api/v1');
});
