import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../model/auth_session.dart';
import '../model/user_profile.dart';
import '../services/auth_service.dart';

const _pendingVerificationUnchanged = Object();

class AuthState {
  final bool isAuthenticated;
  final bool isBootstrapping;
  final bool needsPaywall;
  final String? userId;
  final String? token;
  final DateTime? expiration;
  final UserProfile? profile;
  final String? pendingVerificationEmail;

  const AuthState({
    this.isAuthenticated = false,
    this.isBootstrapping = false,
    this.needsPaywall = false,
    this.userId,
    this.token,
    this.expiration,
    this.profile,
    this.pendingVerificationEmail,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isBootstrapping,
    bool? needsPaywall,
    String? userId,
    String? token,
    DateTime? expiration,
    UserProfile? profile,
    Object? pendingVerificationEmail = _pendingVerificationUnchanged,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      needsPaywall: needsPaywall ?? this.needsPaywall,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      expiration: expiration ?? this.expiration,
      profile: profile ?? this.profile,
      pendingVerificationEmail:
          identical(pendingVerificationEmail, _pendingVerificationUnchanged)
          ? this.pendingVerificationEmail
          : pendingVerificationEmail as String?,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service)
    : super(const AuthState(isBootstrapping: true)) {
    try {
      _authStateSub = supabase.Supabase.instance.client.auth.onAuthStateChange
          .listen(_onSupabaseAuthStateChange);
    } catch (_) {
      _authStateSub = null;
    }
    _tryRestoreSession();
  }

  final AuthService _service;
  StreamSubscription<supabase.AuthState>? _authStateSub;
  bool _ignoringSupabaseAuthChanges = false;
  bool _syncingSupabaseSession = false;

  Future<void> _tryRestoreSession() async {
    final pendingVerificationEmail =
        await _service.restorePendingVerificationEmail();
    if (await _service.restoreSession() == null) {
      state = AuthState(
        isBootstrapping: false,
        pendingVerificationEmail: pendingVerificationEmail,
      );
      return;
    }

    try {
      final bootstrap = await _service.bootstrapCurrentSupabaseSession(
        currency: 'DOP',
      );
      await _completeAuthenticatedSignIn(bootstrap);
    } catch (_) {
      await _rcLogOut();
      await _service.clearCachedSession();
      state = AuthState(
        isBootstrapping: false,
        pendingVerificationEmail: pendingVerificationEmail,
      );
    }
  }

  Future<void> loginWithApple() async {
    _ignoringSupabaseAuthChanges = true;
    try {
      final result = await _service.signInWithApple();
      await _completeAuthenticatedSignIn(result);
    } finally {
      _ignoringSupabaseAuthChanges = false;
    }
  }

  Future<void> registerWithApple({required String currency}) async {
    _ignoringSupabaseAuthChanges = true;
    try {
      final result = await _service.signInWithApple(currency: currency);
      await _completeAuthenticatedSignIn(result);
    } finally {
      _ignoringSupabaseAuthChanges = false;
    }
  }

  Future<void> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _ignoringSupabaseAuthChanges = true;
    try {
      final result = await _service.signInWithEmailPassword(
        email: email,
        password: password,
      );
      await _completeAuthenticatedSignIn(result);
    } catch (_) {
      await _syncPendingVerificationState();
      rethrow;
    } finally {
      _ignoringSupabaseAuthChanges = false;
    }
  }

  Future<EmailRegistrationResult> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _service.registerWithEmailPassword(
      name: name,
      email: email,
      password: password,
      currency: 'DOP',
    );

    if (result.bootstrap != null) {
      await _completeAuthenticatedSignIn(result.bootstrap!);
    } else if (result.requiresEmailVerification) {
      state = state.copyWith(
        pendingVerificationEmail: result.email,
        isBootstrapping: false,
      );
    }

    return result;
  }

  Future<void> _completeAuthenticatedSignIn(AuthBootstrapResult result) async {
    final session = result.session;
    await _service.saveSession(
      userId: session.userId,
      token: session.token,
      refreshToken: session.refreshToken,
      profile: session.profile,
    );
    await _service.clearPendingVerificationEmail();
    _setAuthenticated(session);
    state = state.copyWith(needsPaywall: result.isNewUser);
    await Future.wait([_hydrateProfile(), _rcLogIn(session.userId.toString())]);
  }

  void clearPaywallFlag() {
    state = state.copyWith(needsPaywall: false);
  }

  Future<void> logout() async {
    _ignoringSupabaseAuthChanges = true;
    try {
      await _rcLogOut();
      await _service.clearPendingVerificationEmail();
      await _service.clearSession();
      state = const AuthState(isBootstrapping: false);
    } finally {
      _ignoringSupabaseAuthChanges = false;
    }
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
    String? avatarEmoji,
    String? financialGoal,
    double? goalAmount,
    DateTime? goalDate,
  }) async {
    final profile = await _service.updateProfile(
      name: name,
      currency: currency,
      avatarEmoji: avatarEmoji,
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
      pendingVerificationEmail: null,
    );
  }

  Future<void> _syncPendingVerificationState() async {
    final pendingVerificationEmail =
        await _service.restorePendingVerificationEmail();
    state = state.copyWith(
      pendingVerificationEmail: pendingVerificationEmail,
      isBootstrapping: false,
    );
  }

  Future<void> _onSupabaseAuthStateChange(supabase.AuthState authState) async {
    if (_ignoringSupabaseAuthChanges || _syncingSupabaseSession) return;

    final event = authState.event;
    if (event == supabase.AuthChangeEvent.initialSession) {
      return;
    }

    final session = authState.session;
    if (session == null) {
      final pendingVerificationEmail =
          await _service.restorePendingVerificationEmail();
      await _service.clearCachedSession();
      state = AuthState(
        isBootstrapping: false,
        pendingVerificationEmail: pendingVerificationEmail,
      );
      return;
    }

    if (state.token == session.accessToken && state.isAuthenticated) {
      return;
    }

    _syncingSupabaseSession = true;
    try {
      state = state.copyWith(isBootstrapping: true);
      final bootstrap = await _service.bootstrapCurrentSupabaseSession(
        currency: 'DOP',
      );
      await _completeAuthenticatedSignIn(bootstrap);
    } catch (_) {
      await _rcLogOut();
      await _service.clearCachedSession();
      await _syncPendingVerificationState();
    } finally {
      _syncingSupabaseSession = false;
    }
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final service = ref.read(authServiceProvider);
  return AuthController(service);
});
