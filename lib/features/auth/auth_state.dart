import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  AuthNotifier() : super(const AuthState());

  void login(String userId, String token) {
    state = AuthState(
      isAuthenticated: true,
      userId: userId,
      token: token,
      expiration: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
