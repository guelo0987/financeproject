import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'menudo_auth_token';
  static const _userIdKey = 'menudo_user_id';

  /// Attempt to restore a saved session from secure storage.
  /// Returns [userId, token] or null if no session found.
  Future<(int, String)?> restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    final userIdStr = await _storage.read(key: _userIdKey);
    if (token == null || userIdStr == null) return null;
    final userId = int.tryParse(userIdStr);
    if (userId == null) return null;
    return (userId, token);
  }

  /// Persist a session after successful login.
  Future<void> saveSession({required int userId, required String token}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId.toString());
  }

  /// Clear the saved session on logout.
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }

  /// Login — calls backend API. TODO: replace placeholder URL with real backend endpoint.
  /// Returns [userId, token] on success, throws on failure.
  Future<(int, String)> login({required String email, required String password}) async {
    // TODO: Replace with real HTTP call to backend
    // final response = await http.post(
    //   Uri.parse('https://your-backend.com/auth/login'),
    //   body: jsonEncode({'email': email, 'password': password}),
    //   headers: {'Content-Type': 'application/json'},
    // );
    // final data = jsonDecode(response.body);
    // return (data['user_id'] as int, data['token'] as String);

    // Temporary stub for dev — simulate a successful login
    await Future.delayed(const Duration(milliseconds: 800));
    return (1, 'stub_token_dev');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
