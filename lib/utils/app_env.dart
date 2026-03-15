import 'package:flutter/foundation.dart';

class AppEnv {
  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const _androidBaseUrl = String.fromEnvironment(
    'API_BASE_URL_ANDROID',
    defaultValue: '',
  );
  static const _iosBaseUrl = String.fromEnvironment(
    'API_BASE_URL_IOS',
    defaultValue: '',
  );
  static const _macosBaseUrl = String.fromEnvironment(
    'API_BASE_URL_MACOS',
    defaultValue: '',
  );
  static const _windowsBaseUrl = String.fromEnvironment(
    'API_BASE_URL_WINDOWS',
    defaultValue: '',
  );
  static const _linuxBaseUrl = String.fromEnvironment(
    'API_BASE_URL_LINUX',
    defaultValue: '',
  );
  static const _timeoutSecondsRaw = String.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: '20',
  );

  static String get apiBaseUrl {
    final baseUrl = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        _androidBaseUrl.isNotEmpty ? _androidBaseUrl : _apiBaseUrl,
      TargetPlatform.iOS => _iosBaseUrl.isNotEmpty ? _iosBaseUrl : _apiBaseUrl,
      TargetPlatform.macOS =>
        _macosBaseUrl.isNotEmpty ? _macosBaseUrl : _apiBaseUrl,
      TargetPlatform.windows =>
        _windowsBaseUrl.isNotEmpty ? _windowsBaseUrl : _apiBaseUrl,
      TargetPlatform.linux =>
        _linuxBaseUrl.isNotEmpty ? _linuxBaseUrl : _apiBaseUrl,
      _ => _apiBaseUrl,
    };

    final uri = Uri.parse(baseUrl);
    if (defaultTargetPlatform == TargetPlatform.android &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return uri.replace(host: '10.0.2.2').toString();
    }

    return baseUrl;
  }

  static Duration get timeout {
    final seconds = int.tryParse(_timeoutSecondsRaw);
    return Duration(seconds: seconds ?? 20);
  }

  static Uri uri(String path, {Map<String, dynamic>? queryParameters}) {
    final base = Uri.parse(apiBaseUrl);
    final normalizedBasePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return base.replace(
      path: '$normalizedBasePath$normalizedPath',
      queryParameters: queryParameters == null
          ? null
          : {
              for (final entry in queryParameters.entries)
                if (entry.value != null) entry.key: '${entry.value}',
            },
    );
  }
}
