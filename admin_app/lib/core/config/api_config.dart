import 'package:flutter/foundation.dart';

import 'dev_api_host.dart';

/// API configuration — override at build time for production / physical devices.
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
/// flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
/// ```
class ApiConfig {
  ApiConfig._();

  static const int defaultPort = 3000;
  static const String apiPrefix = '/api/v1';

  /// In-memory mock API (offline only). Keep false for production builds.
  static const bool useMockApi =
      bool.fromEnvironment('USE_MOCK_API', defaultValue: false);

  static const String _baseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const String _hostOverride =
      String.fromEnvironment('API_HOST', defaultValue: '');

  static const String _portOverride =
      String.fromEnvironment('API_PORT', defaultValue: '');

  static String get baseUrl {
    if (useMockApi) {
      return _withTrailingSlash('https://api.healthcare.example.com$apiPrefix');
    }
    if (_baseUrlOverride.isNotEmpty) {
      return _normalizeApiBaseUrl(_baseUrlOverride);
    }

    final host = _hostOverride.isNotEmpty ? _hostOverride : _resolveHost();
    final port = _portOverride.isNotEmpty ? _portOverride : '$defaultPort';
    return _withTrailingSlash('http://$host:$port$apiPrefix');
  }

  static String _normalizeApiBaseUrl(String url) {
    var u = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (!u.endsWith(apiPrefix)) {
      u = '$u$apiPrefix';
    }
    return _withTrailingSlash(u);
  }

  static String _withTrailingSlash(String url) {
    return url.endsWith('/') ? url : '$url/';
  }

  /// Optional legacy admin API key (automation). Prefer admin JWT login in the app.
  static String get adminApiKey =>
      const String.fromEnvironment('ADMIN_API_KEY', defaultValue: '');

  static String _resolveHost() {
    if (kIsWeb) {
      return 'localhost';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (_hostOverride.isNotEmpty) {
          return _hostOverride;
        }
        if (usePhysicalDeviceApiHost && physicalDeviceApiHost.isNotEmpty) {
          return physicalDeviceApiHost;
        }
        return '10.0.2.2';
      case TargetPlatform.iOS:
        return 'localhost';
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return 'localhost';
      default:
        return 'localhost';
    }
  }
}
