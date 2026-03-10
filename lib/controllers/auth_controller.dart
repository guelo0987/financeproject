import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? token;
  final DateTime? expiration;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.token,
    this.expiration,
  });
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState()) {
    _tryRestoreSession();
  }

  final AuthRepository _repo;

  Future<void> _tryRestoreSession() async {
    final session = await _repo.restoreSession();
    if (session == null) return;
    _setAuthenticated(session.userId, session.token);
  }

  Future<void> login(String email, String password) async {
    final session = await _repo.login(email: email, password: password);
    await _repo.saveSession(
      userId: session.userId,
      token: session.token,
      refreshToken: session.refreshToken,
    );
    _setAuthenticated(session.userId, session.token);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String currency,
  }) async {
    final session = await _repo.register(
      name: name,
      email: email,
      password: password,
      currency: currency,
    );
    await _repo.saveSession(
      userId: session.userId,
      token: session.token,
      refreshToken: session.refreshToken,
    );
    _setAuthenticated(session.userId, session.token);
  }

  Future<void> logout() async {
    await _repo.clearSession();
    state = const AuthState();
  }

  void _setAuthenticated(int userId, String token) {
    state = AuthState(
      isAuthenticated: true,
      userId: userId.toString(),
      token: token,
      expiration: DateTime.now().add(const Duration(hours: 24)),
    );
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthController(repo);
});
