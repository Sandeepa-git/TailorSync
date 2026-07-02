import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/env_config.dart';
import '../api_client.dart';

final apiClientProvider = Provider((ref) {
  return ApiClient.create(EnvConfig.backendUrl);
});
