import 'package:flutter/foundation.dart';

class AppEnv {
  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.menudoapp.com',
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
    defaultValue: 'https://api.menudoapp.com/auth/confirm-email',
  );
  static const _authPasswordResetBridgeUrl = String.fromEnvironment(
    'AUTH_PASSWORD_RESET_BRIDGE_URL',
    defaultValue: 'https://api.menudoapp.com/auth/reset-password',
  );
  static const _authWebPublicUrl = String.fromEnvironment(
    'AUTH_WEB_PUBLIC_URL',
    defaultValue: '',
  );
  static const _publicWebBaseUrl = String.fromEnvironment(
    'PUBLIC_WEB_BASE_URL',
    defaultValue: 'https://menudoapp.com',
  );
  static const _supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'notificaciones@menudoapp.com',
  );
  static const _revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: '',
  );
  static const _allowTestStoreRevenueCatRaw = String.fromEnvironment(
    'ALLOW_TEST_STORE_REVENUECAT',
    defaultValue: 'false',
  );
  static const _authMobileCallbackUrl = String.fromEnvironment(
    'AUTH_MOBILE_CALLBACK_URL',
    defaultValue: 'menudo://auth/callback',
  );
  static const _authMobileResetPasswordUrl = String.fromEnvironment(
    'AUTH_MOBILE_RESET_PASSWORD_URL',
    defaultValue: 'menudo://auth/reset-password',
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
    final nextUrl = _resolveAuthFinalUrl(
      webPath: '/auth/confirm',
      mobileUrl: _authMobileCallbackUrl,
    );

    return bridgeUri
        .replace(queryParameters: {if (nextUrl.isNotEmpty) 'next': nextUrl})
        .toString();
  }

  static String get authPasswordResetRedirectUrl {
    final bridgeUri = Uri.parse(_authPasswordResetBridgeUrl);
    final nextUrl = authPasswordResetNextUrl;

    return bridgeUri
        .replace(queryParameters: {if (nextUrl.isNotEmpty) 'next': nextUrl})
        .toString();
  }

  static String get authPasswordResetNextUrl {
    return _resolveAuthFinalUrl(
      webPath: '/auth/reset-password',
      mobileUrl: _authMobileResetPasswordUrl,
    );
  }

  static String get publicWebBaseUrl {
    final preferredBase = _publicWebBaseUrl.trim();
    if (preferredBase.isNotEmpty) return preferredBase;

    final authWebBase = _authWebPublicUrl.trim();
    if (authWebBase.isNotEmpty) return authWebBase;

    return _apiBaseUrl.trim();
  }

  static String get supportEmail => _supportEmail.trim();

  static String get revenueCatApiKey => _revenueCatApiKey.trim();

  static bool get allowTestStoreRevenueCat {
    final normalized = _allowTestStoreRevenueCatRaw.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static String get supportUrl => _buildPublicUrl('/support');

  static String get privacyPolicyUrl => _buildPublicUrl('/privacy-policy');

  static String get termsUrl => _buildPublicUrl('/terms');

  static String get privacyChoicesUrl => _buildPublicUrl('/privacy-choices');

  static String get manageSubscriptionsUrl =>
      'https://apps.apple.com/account/subscriptions';

  static String get refundRequestsUrl =>
      'https://support.apple.com/en-us/HT204084';

  static String _resolveAuthFinalUrl({
    required String webPath,
    required String mobileUrl,
  }) {
    if (kIsWeb) {
      final base = Uri.base;
      final isWebUrl = base.scheme == 'http' || base.scheme == 'https';
      if (isWebUrl && !_isLocalDevelopmentHost(base.host)) {
        return base
            .replace(path: webPath, queryParameters: null, fragment: null)
            .toString();
      }

      return _authWebPublicUrl.trim();
    }

    return mobileUrl;
  }

  static String _buildPublicUrl(String path) {
    final base = Uri.parse(publicWebBaseUrl);
    return base
        .replace(path: path, queryParameters: null, fragment: null)
        .toString();
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
