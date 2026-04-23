import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../core/preferences/app_preferences.dart';
import '../model/auth_session.dart';
import '../model/user_profile.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';

const _pendingVerificationUnchanged = Object();

class AuthState {
  final bool isAuthenticated;
  final bool isBootstrapping;
  final bool needsPaywall;
  final bool isAppleAccount;
  final String? userId;
  final String? token;
  final DateTime? expiration;
  final UserProfile? profile;
  final String? pendingVerificationEmail;
  final String? pendingPasswordResetEmail;
  final bool requiresPasswordReset;

  const AuthState({
    this.isAuthenticated = false,
    this.isBootstrapping = false,
    this.needsPaywall = false,
    this.isAppleAccount = false,
    this.userId,
    this.token,
    this.expiration,
    this.profile,
    this.pendingVerificationEmail,
    this.pendingPasswordResetEmail,
    this.requiresPasswordReset = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isBootstrapping,
    bool? needsPaywall,
    bool? isAppleAccount,
    String? userId,
    String? token,
    DateTime? expiration,
    UserProfile? profile,
    Object? pendingVerificationEmail = _pendingVerificationUnchanged,
    Object? pendingPasswordResetEmail = _pendingVerificationUnchanged,
    bool? requiresPasswordReset,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      needsPaywall: needsPaywall ?? this.needsPaywall,
      isAppleAccount: isAppleAccount ?? this.isAppleAccount,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      expiration: expiration ?? this.expiration,
      profile: profile ?? this.profile,
      pendingVerificationEmail:
          identical(pendingVerificationEmail, _pendingVerificationUnchanged)
          ? this.pendingVerificationEmail
          : pendingVerificationEmail as String?,
      pendingPasswordResetEmail:
          identical(pendingPasswordResetEmail, _pendingVerificationUnchanged)
          ? this.pendingPasswordResetEmail
          : pendingPasswordResetEmail as String?,
      requiresPasswordReset:
          requiresPasswordReset ?? this.requiresPasswordReset,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service, this._subscriptionService)
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
  final SubscriptionService _subscriptionService;
  StreamSubscription<supabase.AuthState>? _authStateSub;
  bool _ignoringSupabaseAuthChanges = false;
  bool _syncingSupabaseSession = false;

  String _preferredCurrency() {
    return marketFromDeviceLocale().currencyCode;
  }

  Future<void> _tryRestoreSession() async {
    final pendingVerificationEmail = await _service
        .restorePendingVerificationEmail();
    final pendingPasswordResetEmail = await _service
        .restorePendingPasswordResetEmail();
    final restoredSession = await _service.restoreSession();
    if (restoredSession == null) {
      state = AuthState(
        isBootstrapping: false,
        pendingVerificationEmail: pendingVerificationEmail,
        pendingPasswordResetEmail: pendingPasswordResetEmail,
      );
      return;
    }

    if (_matchesPendingRecovery(
      _service.currentSupabaseEmail() ?? restoredSession.profile?.email,
      pendingPasswordResetEmail,
    )) {
      state = AuthState(
        isBootstrapping: false,
        pendingVerificationEmail: pendingVerificationEmail,
        pendingPasswordResetEmail: pendingPasswordResetEmail,
        requiresPasswordReset: true,
      );
      return;
    }

    try {
      final bootstrap = await _service.bootstrapCurrentSupabaseSession(
        currency: _preferredCurrency(),
      );
      await _completeAuthenticatedSignIn(bootstrap);
    } catch (_) {
      await _rcLogOut();
      await _service.clearCachedSession();
      state = AuthState(
        isBootstrapping: false,
        pendingVerificationEmail: pendingVerificationEmail,
        pendingPasswordResetEmail: pendingPasswordResetEmail,
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
      currency: _preferredCurrency(),
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
    await _service.clearPendingPasswordResetEmail();
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
      await _service.clearPendingPasswordResetEmail();
      await _service.clearSession();
      state = const AuthState(isBootstrapping: false);
    } finally {
      _ignoringSupabaseAuthChanges = false;
    }
  }

  Future<void> _rcLogIn(String userId) async {
    try {
      await _subscriptionService.logIn(userId);
    } catch (_) {
      // RC login failure is non-fatal — app continues normally
    }
  }

  Future<void> _rcLogOut() async {
    try {
      await _subscriptionService.logOut();
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
      isAppleAccount: _service.isCurrentUserAppleAccount(),
      userId: session.userId.toString(),
      token: session.token,
      expiration: DateTime.now().add(const Duration(hours: 24)),
      profile: session.profile,
      pendingVerificationEmail: null,
      pendingPasswordResetEmail: null,
      requiresPasswordReset: false,
    );
  }

  Future<void> _syncPendingVerificationState() async {
    final pendingVerificationEmail = await _service
        .restorePendingVerificationEmail();
    final pendingPasswordResetEmail = await _service
        .restorePendingPasswordResetEmail();
    state = state.copyWith(
      pendingVerificationEmail: pendingVerificationEmail,
      pendingPasswordResetEmail: pendingPasswordResetEmail,
      isBootstrapping: false,
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await _service.requestPasswordReset(email);
    state = state.copyWith(
      pendingPasswordResetEmail: email.trim().toLowerCase(),
    );
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

  Future<void> completePasswordRecovery(String newPassword) async {
    await _service.updatePasswordFromRecovery(newPassword);
    final bootstrap = await _service.bootstrapCurrentSupabaseSession(
      currency: _preferredCurrency(),
    );
    await _completeAuthenticatedSignIn(bootstrap);
  }

  Future<void> verifyOtpTokenHash({
    required String tokenHash,
    required supabase.OtpType type,
  }) {
    return _service.verifyOtpTokenHash(tokenHash: tokenHash, type: type);
  }

  Future<void> deleteAccount() async {
    _ignoringSupabaseAuthChanges = true;
    try {
      await _rcLogOut();
      await _service.deleteAccount();
      state = const AuthState(isBootstrapping: false);
    } finally {
      _ignoringSupabaseAuthChanges = false;
    }
  }

  Future<void> _onSupabaseAuthStateChange(supabase.AuthState authState) async {
    if (_ignoringSupabaseAuthChanges || _syncingSupabaseSession) return;

    final event = authState.event;
    if (event == supabase.AuthChangeEvent.initialSession) {
      return;
    }

    if (event == supabase.AuthChangeEvent.passwordRecovery) {
      final recoveryEmail = authState.session?.user.email?.trim().toLowerCase();
      if (recoveryEmail != null && recoveryEmail.isNotEmpty) {
        await _service.savePendingPasswordResetEmail(recoveryEmail);
      }
      state = state.copyWith(
        isBootstrapping: false,
        pendingPasswordResetEmail: recoveryEmail,
        requiresPasswordReset: true,
      );
      return;
    }

    final session = authState.session;
    if (session == null) {
      final pendingVerificationEmail = await _service
          .restorePendingVerificationEmail();
      final pendingPasswordResetEmail = await _service
          .restorePendingPasswordResetEmail();
      await _service.clearCachedSession();
      state = AuthState(
        isBootstrapping: false,
        pendingVerificationEmail: pendingVerificationEmail,
        pendingPasswordResetEmail: pendingPasswordResetEmail,
      );
      return;
    }

    final pendingPasswordResetEmail = await _service
        .restorePendingPasswordResetEmail();
    final sessionEmail = session.user.email?.trim().toLowerCase();
    if (_matchesPendingRecovery(sessionEmail, pendingPasswordResetEmail) ||
        state.requiresPasswordReset) {
      state = state.copyWith(
        isBootstrapping: false,
        pendingPasswordResetEmail: sessionEmail ?? pendingPasswordResetEmail,
        requiresPasswordReset: true,
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
        currency: _preferredCurrency(),
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

  bool _matchesPendingRecovery(String? sessionEmail, String? pendingEmail) {
    final normalizedSessionEmail = sessionEmail?.trim().toLowerCase();
    final normalizedPendingEmail = pendingEmail?.trim().toLowerCase();
    return normalizedSessionEmail != null &&
        normalizedSessionEmail.isNotEmpty &&
        normalizedPendingEmail != null &&
        normalizedPendingEmail.isNotEmpty &&
        normalizedSessionEmail == normalizedPendingEmail;
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final service = ref.read(authServiceProvider);
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return AuthController(service, subscriptionService);
});
