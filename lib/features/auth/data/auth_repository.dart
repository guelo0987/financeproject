import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/auth_session.dart';
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
    if (token == null || userIdStr == null) return null;
    final userId = int.tryParse(userIdStr);
    if (userId == null) return null;
    return AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
    );
  }

  Future<void> saveSession({
    required int userId,
    required String token,
    String? refreshToken,
  }) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
    await _storage.write(key: StorageKeys.userId, value: userId.toString());
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: StorageKeys.authToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.userId);
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
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiServiceProvider));
});
