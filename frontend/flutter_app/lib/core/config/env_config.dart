import 'package:flutter/foundation.dart';

class EnvConfig {
  static String get backendUrl {
    const fromEnv = String.fromEnvironment('BACKEND_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    
    // Default to the live hosted Azure App Service
    return 'https://tailorsync-api-prod-gxgvdaawe5a6bffn.centralus-01.azurewebsites.net/api/v1';
  }
}
