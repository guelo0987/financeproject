import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/preferences/app_preferences.dart';
import 'core/preferences/app_preferences_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_state.dart';
import 'features/shortcuts/presentation/ios_shortcuts_coordinator.dart';
import 'routes/app_router.dart';
import 'services/subscription_service.dart';
import 'utils/app_env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android)) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabasePublishableKey,
  );
  await initializeDateFormatting();
  await SubscriptionService.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: MenudoApp()));
}

class MenudoApp extends ConsumerWidget {
  const MenudoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouter);
    final preferences = ref.watch(appPreferencesProvider).valueOrNull;
    final profileCurrency = ref.watch(
      authProvider.select((state) => state.profile?.baseCurrency),
    );
    final market =
        preferences?.market ??
        (profileCurrency == null || profileCurrency.trim().isEmpty
            ? marketFromDeviceLocale()
            : marketFromCurrency(profileCurrency));
    final locale =
        preferences?.locale ??
        buildAppLocale(
          languageCode: defaultLanguageForMarket(market),
          marketCode: market.code,
        );
    final currencyCode = preferences?.currencyCode ?? market.currencyCode;
    AppFormattingPreferences.configure(
      locale: locale,
      currencyCode: currencyCode,
    );

    return MaterialApp.router(
      title: 'Menudo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: const [
        Locale('es', 'DO'),
        Locale('es', 'MX'),
        Locale('es', 'CO'),
        Locale('es', 'ES'),
        Locale('es', 'AR'),
        Locale('es', 'CL'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: IosShortcutsCoordinator(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
