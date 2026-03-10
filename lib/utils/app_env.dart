import 'package:flutter/services.dart';

class AppEnv {
  static final Map<String, String> _values = <String, String>{};
  static bool _loaded = false;

  static Future<void> load({String assetPath = '.env'}) async {
    if (_loaded) return;

    try {
      final raw = await rootBundle.loadString(assetPath);
      for (final line in raw.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final separator = trimmed.indexOf('=');
        if (separator <= 0) continue;
        final key = trimmed.substring(0, separator).trim();
        final value = trimmed.substring(separator + 1).trim();
        _values[key] = value;
      }
    } catch (_) {
      // Keep defaults if the local .env asset is not available yet.
    }

    _loaded = true;
  }

  static String get apiBaseUrl =>
      _values['API_BASE_URL'] ?? 'http://localhost:3000';

  static Duration get timeout {
    final seconds = int.tryParse(_values['API_TIMEOUT_SECONDS'] ?? '');
    return Duration(seconds: seconds ?? 20);
  }

  static String? get apiKey {
    final key = _values['API_KEY'];
    if (key == null || key.isEmpty) return null;
    return key;
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
