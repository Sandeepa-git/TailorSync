import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/env_config.dart';
import '../api_client.dart';

import '../../../routes/app_router.dart';

final apiClientProvider = Provider((ref) {
  final client = ApiClient.create(EnvConfig.backendUrl);
  client.onUnauthorized = () async {
    client.clearToken();
    await ref.read(secureStorageProvider).delete(key: 'auth_token');
    appRouter.go('/login');
  };
  return client;
});

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
