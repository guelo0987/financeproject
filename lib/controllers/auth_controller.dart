import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../model/auth_session.dart';
import '../model/user_profile.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isBootstrapping;
  final bool needsPaywall;
  final String? userId;
  final String? token;
  final DateTime? expiration;
  final UserProfile? profile;

  const AuthState({
    this.isAuthenticated = false,
    this.isBootstrapping = false,
    this.needsPaywall = false,
    this.userId,
    this.token,
    this.expiration,
    this.profile,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isBootstrapping,
    bool? needsPaywall,
    String? userId,
    String? token,
    DateTime? expiration,
    UserProfile? profile,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      needsPaywall: needsPaywall ?? this.needsPaywall,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      expiration: expiration ?? this.expiration,
      profile: profile ?? this.profile,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service)
    : super(const AuthState(isBootstrapping: true)) {
    _tryRestoreSession();
  }

  final AuthService _service;

  Future<void> _tryRestoreSession() async {
    final session = await _service.restoreSession();
    if (session == null) {
      state = const AuthState(isBootstrapping: false);
      return;
    }

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
      state = const AuthState(isBootstrapping: false);
    }
  }

  Future<void> loginWithApple() async {
    final result = await _service.signInWithApple();
    await _completeAppleSignIn(result);
  }

  Future<void> registerWithApple({required String currency}) async {
    final result = await _service.signInWithApple(currency: currency);
    await _completeAppleSignIn(result);
  }

  Future<void> _completeAppleSignIn(AuthBootstrapResult result) async {
    final session = result.session;
    await _service.saveSession(
      userId: session.userId,
      token: session.token,
      refreshToken: session.refreshToken,
      profile: session.profile,
    );
    _setAuthenticated(session);
    state = state.copyWith(needsPaywall: result.isNewUser);
    await Future.wait([_hydrateProfile(), _rcLogIn(session.userId.toString())]);
  }

  void clearPaywallFlag() {
    state = state.copyWith(needsPaywall: false);
  }

  Future<void> logout() async {
    await _rcLogOut();
    await _service.clearSession();
    state = const AuthState(isBootstrapping: false);
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

  void _setAuthenticated(AuthSession session) {
    state = AuthState(
      isAuthenticated: true,
      isBootstrapping: false,
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
