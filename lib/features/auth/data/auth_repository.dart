import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/auth_session.dart';
import '../../../model/user_profile.dart';
import '../../../services/api_service.dart';
import '../../../utils/utils.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiService _api;
  static const _storage = FlutterSecureStorage();

  Future<AuthSession?> restoreSession() async {
    final token = await _storage.read(key: StorageKeys.authToken);
    final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
    final userIdStr = await _storage.read(key: StorageKeys.userId);
    final userName = await _storage.read(key: StorageKeys.userName);
    final userEmail = await _storage.read(key: StorageKeys.userEmail);
    final userCurrency = await _storage.read(key: StorageKeys.userCurrency);
    if (token == null || userIdStr == null) return null;
    final userId = int.tryParse(userIdStr);
    if (userId == null) return null;
    return AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      profile: userName == null && userEmail == null && userCurrency == null
          ? null
          : UserProfile(
              userId: userId,
              name: userName ?? '',
              email: userEmail ?? '',
              baseCurrency: userCurrency ?? 'DOP',
            ),
    );
  }

  Future<void> saveSession({
    required int userId,
    required String token,
    String? refreshToken,
    UserProfile? profile,
  }) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
    await _storage.write(key: StorageKeys.userId, value: userId.toString());
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
    }
    await saveProfile(profile);
  }

  Future<void> saveProfile(UserProfile? profile) async {
    if (profile == null) {
      await _storage.delete(key: StorageKeys.userName);
      await _storage.delete(key: StorageKeys.userEmail);
      await _storage.delete(key: StorageKeys.userCurrency);
      return;
    }

    await _storage.write(key: StorageKeys.userName, value: profile.name);
    await _storage.write(key: StorageKeys.userEmail, value: profile.email);
    await _storage.write(
      key: StorageKeys.userCurrency,
      value: profile.baseCurrency,
    );
  }

  Future<void> clearSession() async {
    await _storage.delete(key: StorageKeys.authToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.userId);
    await _storage.delete(key: StorageKeys.userName);
    await _storage.delete(key: StorageKeys.userEmail);
    await _storage.delete(key: StorageKeys.userCurrency);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.authLogin,
      authenticated: false,
      body: {'email': email, 'password': password},
      parser: asJsonMap,
    );
    return AuthSession.fromJson(response.requireData());
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String currency,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.authRegister,
      authenticated: false,
      body: {
        'nombre': name,
        'email': email,
        'password': password,
        'moneda_base': currency,
      },
      parser: asJsonMap,
    );
    return AuthSession.fromJson(response.requireData());
  }

  Future<UserProfile> fetchProfile() async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiPaths.authMe,
      parser: asJsonMap,
    );
    return UserProfile.fromJson(response.requireData());
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiServiceProvider));
});
