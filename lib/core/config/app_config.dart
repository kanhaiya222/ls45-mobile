import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Centralised runtime configuration.
///
/// API base resolution (dev): the Android emulator reaches the host machine via 10.0.2.2, while web,
/// desktop and the iOS simulator use localhost. Override at build time with
/// `--dart-define=API_BASE_URL=https://api.example.com/api/v1` for staging/prod.
class AppConfig {
  AppConfig._();

  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }
}
