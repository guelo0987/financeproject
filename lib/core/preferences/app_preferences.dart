import 'dart:ui';

import 'package:intl/intl.dart';

class AppLanguageOption {
  const AppLanguageOption({
    required this.code,
    required this.labelEs,
    required this.labelEn,
  });

  final String code;
  final String labelEs;
  final String labelEn;

  String label(bool isEnglish) => isEnglish ? labelEn : labelEs;
}

class AppMarketOption {
  const AppMarketOption({
    required this.code,
    required this.currencyCode,
    required this.countryCode,
    required this.labelEs,
    required this.labelEn,
  });

  final String code;
  final String currencyCode;
  final String countryCode;
  final String labelEs;
  final String labelEn;

  String label(bool isEnglish) => isEnglish ? labelEn : labelEs;
}

const supportedAppLanguages = <AppLanguageOption>[
  AppLanguageOption(code: 'es', labelEs: 'Español', labelEn: 'Spanish'),
  AppLanguageOption(code: 'en', labelEs: 'Inglés', labelEn: 'English'),
];

const supportedAppMarkets = <AppMarketOption>[
  AppMarketOption(
    code: 'DO',
    currencyCode: 'DOP',
    countryCode: 'DO',
    labelEs: 'República Dominicana · DOP',
    labelEn: 'Dominican Republic · DOP',
  ),
  AppMarketOption(
    code: 'US',
    currencyCode: 'USD',
    countryCode: 'US',
    labelEs: 'Estados Unidos · USD',
    labelEn: 'United States · USD',
  ),
  AppMarketOption(
    code: 'MX',
    currencyCode: 'MXN',
    countryCode: 'MX',
    labelEs: 'México · MXN',
    labelEn: 'Mexico · MXN',
  ),
  AppMarketOption(
    code: 'CO',
    currencyCode: 'COP',
    countryCode: 'CO',
    labelEs: 'Colombia · COP',
    labelEn: 'Colombia · COP',
  ),
  AppMarketOption(
    code: 'ES',
    currencyCode: 'EUR',
    countryCode: 'ES',
    labelEs: 'España · EUR',
    labelEn: 'Spain · EUR',
  ),
  AppMarketOption(
    code: 'AR',
    currencyCode: 'ARS',
    countryCode: 'AR',
    labelEs: 'Argentina · ARS',
    labelEn: 'Argentina · ARS',
  ),
  AppMarketOption(
    code: 'CL',
    currencyCode: 'CLP',
    countryCode: 'CL',
    labelEs: 'Chile · CLP',
    labelEn: 'Chile · CLP',
  ),
];

AppLanguageOption languageFromCode(String? code) {
  return supportedAppLanguages.firstWhere(
    (language) => language.code == code,
    orElse: () => supportedAppLanguages.first,
  );
}

AppMarketOption marketFromCode(String? code) {
  return supportedAppMarkets.firstWhere(
    (market) => market.code == code,
    orElse: () => supportedAppMarkets.first,
  );
}

AppMarketOption marketFromCurrency(String? currency) {
  final normalized = currency?.trim().toUpperCase();
  return supportedAppMarkets.firstWhere(
    (market) => market.currencyCode == normalized,
    orElse: () => supportedAppMarkets.first,
  );
}

AppMarketOption marketFromDeviceLocale([Locale? locale]) {
  final deviceLocale = locale ?? PlatformDispatcher.instance.locale;
  final countryCode = deviceLocale.countryCode?.toUpperCase();
  if (countryCode != null && countryCode.isNotEmpty) {
    final matched = supportedAppMarkets.where(
      (market) => market.countryCode == countryCode,
    );
    if (matched.isNotEmpty) return matched.first;
  }

  return deviceLocale.languageCode.toLowerCase() == 'en'
      ? marketFromCode('US')
      : marketFromCode('DO');
}

String defaultLanguageForMarket(AppMarketOption market) {
  return market.currencyCode == 'USD' ? 'en' : 'es';
}

Locale buildAppLocale({
  required String languageCode,
  required String marketCode,
}) {
  if (languageCode == 'en') {
    return const Locale('en', 'US');
  }
  final market = marketFromCode(marketCode);
  return Locale('es', market.countryCode);
}

String localeTagFor(Locale locale) {
  final countryCode = locale.countryCode?.trim();
  if (countryCode == null || countryCode.isEmpty) {
    return locale.languageCode;
  }
  return '${locale.languageCode}_$countryCode';
}

class AppFormattingPreferences {
  static Locale _locale = const Locale('es', 'DO');
  static String _currencyCode = 'DOP';

  static Locale get locale => _locale;
  static String get currencyCode => _currencyCode;
  static String get localeTag => localeTagFor(_locale);

  static void configure({
    required Locale locale,
    required String currencyCode,
  }) {
    _locale = locale;
    _currencyCode = currencyCode.trim().toUpperCase();
    Intl.defaultLocale = localeTagFor(locale);
  }
}
