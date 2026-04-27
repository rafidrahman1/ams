import 'package:flutter/foundation.dart';

/// Centralized configuration for build-time environment values.
///
/// Provide values via:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Keep the existing dev default to avoid breaking current runs.
    defaultValue: 'https://api-ams.bitflex.xyz',
  );

  static Uri get apiBaseUri {
    final raw = apiBaseUrl.trim();
    final normalized = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    return Uri.parse(normalized);
  }

  static bool get isRelease => kReleaseMode;
}
