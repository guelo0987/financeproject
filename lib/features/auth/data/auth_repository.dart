import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/auth_session.dart';
import '../../../model/user_profile.dart';
import '../../../services/api_service.dart';
import '../../../utils/utils.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiService _api;
  static const _storage = FlutterSecureStorage();

  Future<AuthSession?> restoreSession() async {
    final token = await _storage.read(key: StorageKeys.authToken);
    final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
    final userIdStr = await _storage.read(key: StorageKeys.userId);
    final userName = await _storage.read(key: StorageKeys.userName);
    final userEmail = await _storage.read(key: StorageKeys.userEmail);
    final userCurrency = await _storage.read(key: StorageKeys.userCurrency);
    final userFinancialGoal = await _storage.read(
      key: StorageKeys.userFinancialGoal,
    );
    final userGoalAmount = await _storage.read(key: StorageKeys.userGoalAmount);
    final userGoalDate = await _storage.read(key: StorageKeys.userGoalDate);
    final userCreatedAt = await _storage.read(key: StorageKeys.userCreatedAt);
    final userDefaultBudgetId = await _storage.read(
      key: StorageKeys.userDefaultBudgetId,
    );
    if (token == null || userIdStr == null) return null;
    final userId = int.tryParse(userIdStr);
    if (userId == null) return null;
    return AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      profile:
          userName == null &&
              userEmail == null &&
              userCurrency == null &&
              userFinancialGoal == null &&
              userGoalAmount == null &&
              userGoalDate == null
          ? null
          : UserProfile(
              userId: userId,
              name: userName ?? '',
              email: userEmail ?? '',
              baseCurrency: userCurrency ?? 'DOP',
              financialGoal: userFinancialGoal,
              goalAmount: double.tryParse(userGoalAmount ?? ''),
              goalDate: userGoalDate == null
                  ? null
                  : DateTime.tryParse(userGoalDate),
              createdAt: userCreatedAt == null
                  ? null
                  : DateTime.tryParse(userCreatedAt),
              defaultBudgetId: int.tryParse(userDefaultBudgetId ?? ''),
            ),
    );
  }

  Future<void> saveSession({
    required int userId,
    required String token,
    String? refreshToken,
    UserProfile? profile,
  }) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
    await _storage.write(key: StorageKeys.userId, value: userId.toString());
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
    }
    await saveProfile(profile);
  }

  Future<void> saveProfile(UserProfile? profile) async {
    if (profile == null) {
      await _storage.delete(key: StorageKeys.userName);
      await _storage.delete(key: StorageKeys.userEmail);
      await _storage.delete(key: StorageKeys.userCurrency);
      await _storage.delete(key: StorageKeys.userDefaultBudgetId);
      await _storage.delete(key: StorageKeys.userFinancialGoal);
      await _storage.delete(key: StorageKeys.userGoalAmount);
      await _storage.delete(key: StorageKeys.userGoalDate);
      await _storage.delete(key: StorageKeys.userCreatedAt);
      return;
    }

    await _storage.write(key: StorageKeys.userName, value: profile.name);
    await _storage.write(key: StorageKeys.userEmail, value: profile.email);
    await _storage.write(
      key: StorageKeys.userCurrency,
      value: profile.baseCurrency,
    );
    if (profile.financialGoal != null && profile.financialGoal!.isNotEmpty) {
      await _storage.write(
        key: StorageKeys.userFinancialGoal,
        value: profile.financialGoal,
      );
    } else {
      await _storage.delete(key: StorageKeys.userFinancialGoal);
    }
    if (profile.goalAmount != null) {
      await _storage.write(
        key: StorageKeys.userGoalAmount,
        value: profile.goalAmount!.toString(),
      );
    } else {
      await _storage.delete(key: StorageKeys.userGoalAmount);
    }
    if (profile.goalDate != null) {
      await _storage.write(
        key: StorageKeys.userGoalDate,
        value: profile.goalDate!.toIso8601String(),
      );
    } else {
      await _storage.delete(key: StorageKeys.userGoalDate);
    }
    if (profile.createdAt != null) {
      await _storage.write(
        key: StorageKeys.userCreatedAt,
        value: profile.createdAt!.toIso8601String(),
      );
    } else {
      await _storage.delete(key: StorageKeys.userCreatedAt);
    }
    if (profile.defaultBudgetId != null) {
      await _storage.write(
        key: StorageKeys.userDefaultBudgetId,
        value: profile.defaultBudgetId.toString(),
      );
    } else {
      await _storage.delete(key: StorageKeys.userDefaultBudgetId);
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: StorageKeys.authToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.userId);
    await _storage.delete(key: StorageKeys.userName);
    await _storage.delete(key: StorageKeys.userEmail);
    await _storage.delete(key: StorageKeys.userCurrency);
    await _storage.delete(key: StorageKeys.userDefaultBudgetId);
    await _storage.delete(key: StorageKeys.userFinancialGoal);
    await _storage.delete(key: StorageKeys.userGoalAmount);
    await _storage.delete(key: StorageKeys.userGoalDate);
    await _storage.delete(key: StorageKeys.userCreatedAt);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.authLogin,
      authenticated: false,
      body: {'email': email, 'password': password},
      parser: asJsonMap,
    );
    return AuthSession.fromJson(response.requireData());
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String currency,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.authRegister,
      authenticated: false,
      body: {
        'nombre': name,
        'email': email,
        'password': password,
        'moneda_base': currency,
      },
      parser: asJsonMap,
    );
    return AuthSession.fromJson(response.requireData());
  }

  Future<UserProfile> fetchProfile() async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiPaths.authMe,
      parser: asJsonMap,
    );
    return UserProfile.fromJson(response.requireData());
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String currency,
    String? financialGoal,
    double? goalAmount,
    DateTime? goalDate,
  }) async {
    final response = await _api.patch<Map<String, dynamic>>(
      ApiPaths.authMe,
      body: {
        'nombre': name,
        'moneda_base': currency,
        'meta_financiera': financialGoal,
        'meta_monto': goalAmount,
        'meta_fecha': goalDate?.toIso8601String(),
      },
      parser: asJsonMap,
    );
    return UserProfile.fromJson(response.requireData());
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put<void>(
      ApiPaths.authPassword,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<int?> setDefaultBudget(int? budgetId) async {
    final response = await _api.patch<Map<String, dynamic>>(
      ApiPaths.authDefaultBudget,
      body: {'presupuesto_id': budgetId},
      parser: asJsonMap,
    );
    final data = response.requireData();
    final rawBudgetId =
        data['presupuesto_default_id'] ?? data['default_budget_id'];
    return switch (rawBudgetId) {
      int value => value,
      String value => int.tryParse(value),
      num value => value.toInt(),
      _ => null,
    };
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiServiceProvider));
});
