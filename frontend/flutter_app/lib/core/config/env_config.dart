

class EnvConfig {
  static String get backendUrl {
    const fromEnv = String.fromEnvironment('BACKEND_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    
    // Default to production Azure Web App URL
    return 'https://tailorsync-api-prod-gxgvdaawe5a6bffn.centralus-01.azurewebsites.net/api/v1';
  }
}
