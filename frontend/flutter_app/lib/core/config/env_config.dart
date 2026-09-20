

class EnvConfig {
  static String get backendUrl {
    const fromEnv = String.fromEnvironment('BACKEND_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    
    // Default to local server for active development
    return 'http://127.0.0.1:8000/api/v1';
  }
}
