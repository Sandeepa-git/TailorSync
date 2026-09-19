import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/env_config.dart';
import '../api_client.dart';

import '../../../routes/app_router.dart';

final apiClientProvider = Provider((ref) {
  final client = ApiClient.create(EnvConfig.backendUrl);
  final storage = ref.read(secureStorageProvider);

  client.tokenGetter = () async {
    try {
      return await storage.read(key: 'auth_token');
    } catch (_) {
      return null;
    }
  };

  client.onUnauthorized = () async {
    // Clear both in-memory token AND secure storage
    client.clearToken();
    try {
      await storage.delete(key: 'auth_token');
    } catch (_) {}
    appRouter.go('/login');
  };
  return client;
});

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
