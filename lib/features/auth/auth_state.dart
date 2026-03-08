import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/auth_repository.dart';

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

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    final session = await _repo.restoreSession();
    if (session != null) {
      final (userId, token) = session;
      state = AuthState(
        isAuthenticated: true,
        userId: userId.toString(),
        token: token,
        expiration: DateTime.now().add(const Duration(hours: 24)),
      );
    }
  }

  Future<void> login(String email, String password) async {
    final (userId, token) = await _repo.login(email: email, password: password);
    await _repo.saveSession(userId: userId, token: token);
    state = AuthState(
      isAuthenticated: true,
      userId: userId.toString(),
      token: token,
      expiration: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  Future<void> logout() async {
    await _repo.clearSession();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo);
});
