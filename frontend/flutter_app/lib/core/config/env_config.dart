class EnvConfig {
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://tailorsync-api-bqgscxf3g2d7c7hb.uaenorth-01.azurewebsites.net/api/v1',
  );
}
