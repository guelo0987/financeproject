import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/auth_session.dart';
import '../model/user_profile.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? token;
  final DateTime? expiration;
  final UserProfile? profile;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.token,
    this.expiration,
    this.profile,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? token,
    DateTime? expiration,
    UserProfile? profile,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      expiration: expiration ?? this.expiration,
      profile: profile ?? this.profile,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service) : super(const AuthState()) {
    _tryRestoreSession();
  }

  final AuthService _service;

  Future<void> _tryRestoreSession() async {
    final session = await _service.restoreSession();
    if (session == null) return;
    _setAuthenticated(session);
    if (session.profile == null) {
      await _hydrateProfile();
    }
  }

  Future<void> login(String email, String password) async {
    final session = await _service.login(email: email, password: password);
    await _service.saveSession(
      userId: session.userId,
      token: session.token,
      refreshToken: session.refreshToken,
      profile: session.profile,
    );
    _setAuthenticated(session);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String currency,
  }) async {
    final session = await _service.register(
      name: name,
      email: email,
      password: password,
      currency: currency,
    );
    await _service.saveSession(
      userId: session.userId,
      token: session.token,
      refreshToken: session.refreshToken,
      profile: session.profile,
    );
    _setAuthenticated(session);
  }

  Future<void> logout() async {
    await _service.clearSession();
    state = const AuthState();
  }

  Future<void> _hydrateProfile() async {
    try {
      final profile = await _service.fetchProfile();
      await _service.saveProfile(profile);
      state = state.copyWith(
        userId: profile.userId.toString(),
        profile: profile,
      );
    } catch (_) {
      // Keep the session usable even if profile hydration fails.
    }
  }

  void _setAuthenticated(AuthSession session) {
    state = AuthState(
      isAuthenticated: true,
      userId: session.userId.toString(),
      token: session.token,
      expiration: DateTime.now().add(const Duration(hours: 24)),
      profile: session.profile,
    );
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final service = ref.read(authServiceProvider);
  return AuthController(service);
});
