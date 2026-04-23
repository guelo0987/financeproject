import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/storage_keys.dart';
import 'app_preferences.dart';

class AppPreferencesState {
  const AppPreferencesState({
    required this.languageCode,
    required this.marketCode,
  });

  final String languageCode;
  final String marketCode;

  AppLanguageOption get language => languageFromCode(languageCode);
  AppMarketOption get market => marketFromCode(marketCode);
  String get currencyCode => market.currencyCode;
  Locale get locale =>
      buildAppLocale(languageCode: languageCode, marketCode: marketCode);

  AppPreferencesState copyWith({String? languageCode, String? marketCode}) {
    return AppPreferencesState(
      languageCode: languageCode ?? this.languageCode,
      marketCode: marketCode ?? this.marketCode,
    );
  }
}

class AppPreferencesController extends AsyncNotifier<AppPreferencesState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<AppPreferencesState> build() async {
    final authUserId = ref.watch(authProvider.select((state) => state.userId));
    final profileCurrency = ref.watch(
      authProvider.select((state) => state.profile?.baseCurrency),
    );
    final activeOwnerId = _ownerIdFor(authUserId);
    final savedOwnerId = await _storage.read(
      key: StorageKeys.appPreferencesUserId,
    );
    final savedLanguage = await _storage.read(key: StorageKeys.appLanguage);
    final savedMarket = await _storage.read(key: StorageKeys.appMarket);
    final canReuseSavedPreferences =
        savedOwnerId != null &&
        savedOwnerId.isNotEmpty &&
        savedOwnerId == activeOwnerId;

    final market =
        !canReuseSavedPreferences || savedMarket == null || savedMarket.isEmpty
        ? marketFromCurrency(profileCurrency)
        : marketFromCode(savedMarket);
    final languageCode =
        (!canReuseSavedPreferences ||
            savedLanguage == null ||
            savedLanguage.isEmpty)
        ? defaultLanguageForMarket(market)
        : languageFromCode(savedLanguage).code;

    final next = AppPreferencesState(
      languageCode: languageCode,
      marketCode: market.code,
    );
    await _storage.write(
      key: StorageKeys.appPreferencesUserId,
      value: activeOwnerId,
    );
    _applyRuntime(next);
    return next;
  }

  Future<void> setLanguage(String languageCode) async {
    final current = state.valueOrNull ?? _fallbackState();
    final normalized = languageFromCode(languageCode).code;
    final next = current.copyWith(languageCode: normalized);
    await _storage.write(key: StorageKeys.appLanguage, value: normalized);
    await _storage.write(
      key: StorageKeys.appPreferencesUserId,
      value: _ownerIdFor(ref.read(authProvider).userId),
    );
    _applyRuntime(next);
    state = AsyncData(next);
  }

  Future<void> setMarket(String marketCode) async {
    final current = state.valueOrNull ?? _fallbackState();
    final normalized = marketFromCode(marketCode).code;
    final next = current.copyWith(marketCode: normalized);
    await _storage.write(key: StorageKeys.appMarket, value: normalized);
    await _storage.write(
      key: StorageKeys.appPreferencesUserId,
      value: _ownerIdFor(ref.read(authProvider).userId),
    );
    _applyRuntime(next);
    state = AsyncData(next);
  }

  Future<void> resetForSignedOutUser() async {
    final next = _fallbackState();
    state = AsyncData(next);
    _applyRuntime(next);
  }

  AppPreferencesState _fallbackState() {
    final market = marketFromDeviceLocale(PlatformDispatcher.instance.locale);
    return AppPreferencesState(
      languageCode: defaultLanguageForMarket(market),
      marketCode: market.code,
    );
  }

  void _applyRuntime(AppPreferencesState value) {
    AppFormattingPreferences.configure(
      locale: value.locale,
      currencyCode: value.currencyCode,
    );
  }

  String _ownerIdFor(String? rawUserId) {
    final trimmed = rawUserId?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'guest';
    return trimmed;
  }
}

final appPreferencesProvider =
    AsyncNotifierProvider<AppPreferencesController, AppPreferencesState>(
      AppPreferencesController.new,
    );
