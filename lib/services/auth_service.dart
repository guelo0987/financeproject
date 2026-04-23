import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/data/auth_repository.dart';
import '../model/auth_session.dart';
import '../model/user_profile.dart';

class AuthService {
  const AuthService(this._repository);

  final AuthRepository _repository;

  Future<AuthSession?> restoreSession() {
    return _repository.restoreSession();
  }

  String? currentSupabaseEmail() {
    return _repository.currentSupabaseEmail();
  }

  bool isCurrentUserAppleAccount() {
    return _repository.isCurrentUserAppleAccount();
  }

  Future<void> saveSession({
    required int userId,
    required String token,
    String? refreshToken,
    UserProfile? profile,
  }) {
    return _repository.saveSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      profile: profile,
    );
  }

  Future<void> saveProfile(UserProfile? profile) {
    return _repository.saveProfile(profile);
  }

  Future<void> clearSession() {
    return _repository.clearSession();
  }

  Future<void> clearCachedSession() {
    return _repository.clearCachedSession();
  }

  Future<String?> restorePendingVerificationEmail() {
    return _repository.restorePendingVerificationEmail();
  }

  Future<String?> restorePendingPasswordResetEmail() {
    return _repository.restorePendingPasswordResetEmail();
  }

  Future<void> savePendingVerificationEmail(String email) {
    return _repository.savePendingVerificationEmail(email);
  }

  Future<void> clearPendingVerificationEmail() {
    return _repository.clearPendingVerificationEmail();
  }

  Future<void> savePendingPasswordResetEmail(String email) {
    return _repository.savePendingPasswordResetEmail(email);
  }

  Future<void> clearPendingPasswordResetEmail() {
    return _repository.clearPendingPasswordResetEmail();
  }

  Future<AuthBootstrapResult> signInWithApple({String? currency}) {
    return _repository.signInWithApple(currency: currency);
  }

  Future<void> verifyOtpTokenHash({
    required String tokenHash,
    required OtpType type,
  }) {
    return _repository.verifyOtpTokenHash(tokenHash: tokenHash, type: type);
  }

  Future<AuthBootstrapResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }

  Future<EmailRegistrationResult> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    String? currency,
  }) {
    return _repository.registerWithEmailPassword(
      name: name,
      email: email,
      password: password,
      currency: currency,
    );
  }

  Future<UserProfile> fetchProfile() {
    return _repository.fetchProfile();
  }

  Future<AuthBootstrapResult> bootstrapCurrentSupabaseSession({
    String? currency,
  }) {
    return _repository.bootstrapCurrentSupabaseSession(currency: currency);
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String currency,
    String? avatarEmoji,
    String? financialGoal,
    double? goalAmount,
    DateTime? goalDate,
  }) {
    return _repository.updateProfile(
      name: name,
      currency: currency,
      avatarEmoji: avatarEmoji,
      financialGoal: financialGoal,
      goalAmount: goalAmount,
      goalDate: goalDate,
    );
  }

  Future<int?> setDefaultBudget(int? budgetId) {
    return _repository.setDefaultBudget(budgetId);
  }

  Future<void> requestPasswordReset(String email) {
    return _repository.requestPasswordReset(email);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> updatePasswordFromRecovery(String newPassword) {
    return _repository.updatePasswordFromRecovery(newPassword);
  }

  Future<void> deleteAccount() {
    return _repository.deleteAccount();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(authRepositoryProvider));
});
