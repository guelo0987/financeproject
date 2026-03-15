import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../model/auth_session.dart';
import '../model/user_profile.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool needsPaywall;
  final String? userId;
  final String? token;
  final DateTime? expiration;
  final UserProfile? profile;

  const AuthState({
    this.isAuthenticated = false,
    this.needsPaywall = false,
    this.userId,
    this.token,
    this.expiration,
    this.profile,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? needsPaywall,
    String? userId,
    String? token,
    DateTime? expiration,
    UserProfile? profile,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      needsPaywall: needsPaywall ?? this.needsPaywall,
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

    try {
      final profile = await _service.fetchProfile();
      await _service.saveProfile(profile);
      _setAuthenticated(
        AuthSession(
          userId: session.userId,
          token: session.token,
          refreshToken: session.refreshToken,
          profile: profile,
        ),
      );
      await _rcLogIn(profile.userId.toString());
    } catch (_) {
      await _rcLogOut();
      await _service.clearSession();
      state = const AuthState();
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
    await Future.wait([_hydrateProfile(), _rcLogIn(session.userId.toString())]);
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
    state = state.copyWith(needsPaywall: true);
    await Future.wait([_hydrateProfile(), _rcLogIn(session.userId.toString())]);
  }

  void clearPaywallFlag() {
    state = state.copyWith(needsPaywall: false);
  }

  Future<void> logout() async {
    await _rcLogOut();
    await _service.clearSession();
    state = const AuthState();
  }

  Future<void> _rcLogIn(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (_) {
      // RC login failure is non-fatal — app continues normally
    }
  }

  Future<void> _rcLogOut() async {
    try {
      await Purchases.logOut();
    } catch (_) {}
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

  Future<void> setDefaultBudget(int? budgetId) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return;

    final savedBudgetId = await _service.setDefaultBudget(budgetId);
    final nextProfile = currentProfile.copyWith(
      defaultBudgetId: savedBudgetId,
      clearDefaultBudgetId: savedBudgetId == null,
    );
    await _service.saveProfile(nextProfile);
    state = state.copyWith(profile: nextProfile);
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String currency,
    String? financialGoal,
    double? goalAmount,
    DateTime? goalDate,
  }) async {
    final profile = await _service.updateProfile(
      name: name,
      currency: currency,
      financialGoal: financialGoal,
      goalAmount: goalAmount,
      goalDate: goalDate,
    );
    await _service.saveProfile(profile);
    state = state.copyWith(userId: profile.userId.toString(), profile: profile);
    return profile;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _service.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
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
