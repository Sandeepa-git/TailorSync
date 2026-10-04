import 'package:dio/dio.dart';

import '../config/env_config.dart';

/// Wakes the backend before the app makes real API calls.
///
/// The API runs on Azure App Service, which unloads the container when it
/// is idle. A cold start takes ~2 minutes (see the App Service startup
/// logs), so the first real requests used to time out and the app looked
/// "disconnected". This helper polls the existing public `/health`
/// endpoint until the server answers, reporting progress so the splash
/// screen can tell the user what is happening.
///
/// It does not change any existing API call, token handling or endpoint.
class ServerWarmup {
  ServerWarmup._();

  /// `https://<host>/health`, derived from the configured backend URL.
  static Uri get healthUri {
    final base = Uri.parse(EnvConfig.backendUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/health',
    );
  }

  /// Polls `/health` until it responds with a non-5xx status.
  /// Returns `true` when the server is ready, `false` after [maxWait].
  static Future<bool> waitUntilReady({
    Duration maxWait = const Duration(minutes: 3),
    void Function(int attempt, Duration elapsed)? onProgress,
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
      validateStatus: (_) => true,
    ));
    final watch = Stopwatch()..start();
    var attempt = 0;
    try {
      while (watch.elapsed < maxWait) {
        attempt++;
        onProgress?.call(attempt, watch.elapsed);
        try {
          final resp = await dio.getUri(healthUri);
          final code = resp.statusCode ?? 0;
          if (code > 0 && code < 500) return true;
        } catch (_) {
          // Network error / timeout while the container boots — retry.
        }
        await Future.delayed(Duration(seconds: attempt < 3 ? 2 : 4));
      }
      return false;
    } finally {
      dio.close(force: true);
    }
  }
}
