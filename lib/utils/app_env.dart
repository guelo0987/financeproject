import 'package:flutter/foundation.dart';

class AppEnv {
  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://financeapp-backend-eight.vercel.app',
  );
  static const _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fzklyclzehpmggqvjipy.supabase.co',
  );
  static const _supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_q5Ghc7KehdhGbK9VCS2eGA_wU0imUWp',
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
  static const _allowLocalPlatformApiOverrideRaw = String.fromEnvironment(
    'ALLOW_LOCAL_PLATFORM_API_OVERRIDE',
    defaultValue: 'false',
  );
  static const _authRedirectBridgeUrl = String.fromEnvironment(
    'AUTH_REDIRECT_BRIDGE_URL',
    defaultValue: 'https://financeapp-backend-eight.vercel.app/auth/confirm-email',
  );
  static const _authWebPublicUrl = String.fromEnvironment(
    'AUTH_WEB_PUBLIC_URL',
    defaultValue: '',
  );
  static const _authMobileCallbackUrl = String.fromEnvironment(
    'AUTH_MOBILE_CALLBACK_URL',
    defaultValue: 'menudo://auth/callback',
  );

  static String get apiBaseUrl {
    final platformOverride = switch (defaultTargetPlatform) {
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

    final baseUrl = _sanitizePlatformOverride(platformOverride);
    final uri = Uri.parse(baseUrl);
    if (defaultTargetPlatform == TargetPlatform.android &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return uri.replace(host: '10.0.2.2').toString();
    }

    return baseUrl;
  }

  static String get supabaseUrl => _supabaseUrl;

  static String get supabasePublishableKey => _supabasePublishableKey;

  static Duration get timeout {
    final seconds = int.tryParse(_timeoutSecondsRaw);
    return Duration(seconds: seconds ?? 20);
  }

  static String _sanitizePlatformOverride(String baseUrl) {
    final resolvedBaseUrl = baseUrl.trim();
    if (resolvedBaseUrl.isEmpty) return _apiBaseUrl;

    final fallbackBaseUrl = _apiBaseUrl.trim();
    if (_allowsLocalPlatformApiOverride || fallbackBaseUrl.isEmpty) {
      return resolvedBaseUrl;
    }

    final resolvedUri = Uri.tryParse(resolvedBaseUrl);
    final fallbackUri = Uri.tryParse(fallbackBaseUrl);
    if (resolvedUri == null || fallbackUri == null) {
      return resolvedBaseUrl;
    }

    if (_isLocalDevelopmentHost(resolvedUri.host) &&
        !_isLocalDevelopmentHost(fallbackUri.host)) {
      return fallbackBaseUrl;
    }

    return resolvedBaseUrl;
  }

  static bool get _allowsLocalPlatformApiOverride {
    final normalized = _allowLocalPlatformApiOverrideRaw.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static String get authEmailRedirectUrl {
    final bridgeUri = Uri.parse(_authRedirectBridgeUrl);
    final nextUrl = _authEmailFinalUrl;

    return bridgeUri.replace(
      queryParameters: {
        if (nextUrl.isNotEmpty) 'next': nextUrl,
      },
    ).toString();
  }

  static String get _authEmailFinalUrl {
    if (kIsWeb) {
      final base = Uri.base;
      final isWebUrl = base.scheme == 'http' || base.scheme == 'https';
      if (isWebUrl && !_isLocalDevelopmentHost(base.host)) {
        return base
            .replace(path: '/auth/confirm', queryParameters: null, fragment: null)
            .toString();
      }

      return _authWebPublicUrl.trim();
    }

    return _authMobileCallbackUrl;
  }

  static bool _isLocalDevelopmentHost(String host) {
    final normalizedHost = host.trim().toLowerCase();
    return normalizedHost == 'localhost' ||
        normalizedHost == '127.0.0.1' ||
        normalizedHost == '0.0.0.0' ||
        normalizedHost == '10.0.2.2';
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
