

class EnvConfig {
  static String get backendUrl {
    const fromEnv = String.fromEnvironment('BACKEND_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    
    // Default to local development server
    return 'http://127.0.0.1:8000/api/v1';
    // return 'https://tailorsync-api-prod-gxgvdaawe5a6bffn.centralus-01.azurewebsites.net/api/v1';
  }
}
