import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../model/auth_session.dart';
import '../model/user_profile.dart';

class AuthService {
  const AuthService(this._repository);

  final AuthRepository _repository;

  Future<AuthSession?> restoreSession() {
    return _repository.restoreSession();
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

  Future<AuthSession> login({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String currency,
  }) {
    return _repository.register(
      name: name,
      email: email,
      password: password,
      currency: currency,
    );
  }

  Future<UserProfile> fetchProfile() {
    return _repository.fetchProfile();
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String currency,
    String? financialGoal,
    double? goalAmount,
    DateTime? goalDate,
  }) {
    return _repository.updateProfile(
      name: name,
      currency: currency,
      financialGoal: financialGoal,
      goalAmount: goalAmount,
      goalDate: goalDate,
    );
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

  Future<int?> setDefaultBudget(int? budgetId) {
    return _repository.setDefaultBudget(budgetId);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(authRepositoryProvider));
});
