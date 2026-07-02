class EnvConfig {
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.18.157.15:8000/api/v1',
  );
}
