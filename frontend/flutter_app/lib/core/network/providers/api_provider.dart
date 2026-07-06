import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/env_config.dart';
import '../api_client.dart';

final apiClientProvider = Provider((ref) {
  return ApiClient.create(EnvConfig.backendUrl);
});

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
