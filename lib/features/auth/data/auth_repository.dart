import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../model/auth_session.dart';
import '../../../model/user_profile.dart';
import '../../../services/api_service.dart';
import '../../../types/api_exception.dart';
import '../../../utils/utils.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiService _api;
  static const _storage = FlutterSecureStorage();
  SupabaseClient? get _supabaseOrNull {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient get _supabase {
    final client = _supabaseOrNull;
    if (client == null) {
      throw const ApiException('Supabase todavía no está inicializado.');
    }
    return client;
  }

  Future<AuthSession?> restoreSession() async {
    final session = _supabaseOrNull?.auth.currentSession;
    if (session == null) return null;

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

    final userId = int.tryParse(userIdStr ?? '') ?? 0;

    return AuthSession(
      userId: userId,
      token: session.accessToken,
      refreshToken: session.refreshToken,
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
    } else {
      await _storage.delete(key: StorageKeys.refreshToken);
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
    try {
      await _supabaseOrNull?.auth.signOut();
    } catch (_) {
      // Local cleanup below is enough to avoid leaving the app in a bad state.
    }

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

  Future<AuthBootstrapResult> signInWithApple({String? currency}) async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw const ApiException(
          'Sign in with Apple solo está disponible en dispositivos Apple.',
        );
      }

      final rawNonce = _supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          'Apple no devolvió un token válido. Inténtalo otra vez.',
        );
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (credential.givenName != null || credential.familyName != null) {
        final nameParts = <String>[
          if (credential.givenName != null &&
              credential.givenName!.trim().isNotEmpty)
            credential.givenName!.trim(),
          if (credential.familyName != null &&
              credential.familyName!.trim().isNotEmpty)
            credential.familyName!.trim(),
        ];

        if (nameParts.isNotEmpty) {
          await _supabase.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': nameParts.join(' '),
                'given_name': credential.givenName,
                'family_name': credential.familyName,
              },
            ),
          );
        }
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw const ApiException(
          'No pudimos recuperar tu sesión de Supabase. Inténtalo otra vez.',
        );
      }

      final response = await _api.post<Map<String, dynamic>>(
        ApiPaths.authSession,
        body: {
          if (currency != null && currency.isNotEmpty) 'moneda_base': currency,
        },
        parser: asJsonMap,
      );

      final data = response.requireData();
      final profilePayload = data['usuario'] ?? data['user'] ?? data;
      final profileJson = profilePayload is Map
          ? Map<String, dynamic>.from(profilePayload)
          : const <String, dynamic>{};
      final profile = UserProfile.fromJson(profileJson);

      final appSession = AuthSession(
        userId: profile.userId,
        token: session.accessToken,
        refreshToken: session.refreshToken,
        profile: profile,
      );

      return AuthBootstrapResult(
        session: appSession,
        isNewUser: data['isNewUser'] == true || data['is_new_user'] == true,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const ApiException('Cancelaste el inicio con Apple.');
      }
      throw ApiException(
        'No pudimos completar el inicio con Apple: ${error.message}',
      );
    } on AuthException catch (error) {
      throw ApiException(error.message);
    }
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
