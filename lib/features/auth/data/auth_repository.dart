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

  String? currentSupabaseEmail() {
    return _supabaseOrNull?.auth.currentSession?.user.email
        ?.trim()
        .toLowerCase();
  }

  bool isCurrentUserAppleAccount() {
    final user = _supabaseOrNull?.auth.currentUser;
    if (user == null) return false;

    final primaryProvider = user.appMetadata['provider']
        ?.toString()
        .trim()
        .toLowerCase();
    if (primaryProvider == 'apple') return true;

    final identityProviders = user.identities
        ?.map((identity) => identity.provider.trim().toLowerCase())
        .whereType<String>()
        .where((provider) => provider.isNotEmpty)
        .toSet();

    return identityProviders != null &&
        identityProviders.length == 1 &&
        identityProviders.contains('apple');
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
    final userAvatarEmoji = await _storage.read(
      key: StorageKeys.userAvatarEmoji,
    );
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
              avatarEmoji: userAvatarEmoji,
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

  Future<String?> restorePendingVerificationEmail() {
    return _storage.read(key: StorageKeys.pendingVerificationEmail);
  }

  Future<String?> restorePendingPasswordResetEmail() {
    return _storage.read(key: StorageKeys.pendingPasswordResetEmail);
  }

  Future<void> savePendingVerificationEmail(String email) async {
    await _storage.write(
      key: StorageKeys.pendingVerificationEmail,
      value: email.trim().toLowerCase(),
    );
  }

  Future<void> clearPendingVerificationEmail() async {
    await _storage.delete(key: StorageKeys.pendingVerificationEmail);
  }

  Future<void> savePendingPasswordResetEmail(String email) async {
    await _storage.write(
      key: StorageKeys.pendingPasswordResetEmail,
      value: email.trim().toLowerCase(),
    );
  }

  Future<void> clearPendingPasswordResetEmail() async {
    await _storage.delete(key: StorageKeys.pendingPasswordResetEmail);
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
      await _storage.delete(key: StorageKeys.userAvatarEmoji);
      return;
    }

    await _storage.write(key: StorageKeys.userName, value: profile.name);
    await _storage.write(key: StorageKeys.userEmail, value: profile.email);
    await _storage.write(
      key: StorageKeys.userCurrency,
      value: profile.baseCurrency,
    );
    if (profile.avatarEmoji != null && profile.avatarEmoji!.trim().isNotEmpty) {
      await _storage.write(
        key: StorageKeys.userAvatarEmoji,
        value: profile.avatarEmoji,
      );
    } else {
      await _storage.delete(key: StorageKeys.userAvatarEmoji);
    }
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

    await clearCachedSession();
  }

  Future<void> clearCachedSession() async {
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
    await _storage.delete(key: StorageKeys.userAvatarEmoji);
  }

  String? _normalizeAvatarEmoji(Object? rawValue) {
    final value = rawValue?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String _normalizeDisplayName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isObfuscatedRepeatedSignup(User? user) {
    final identities = user?.identities;
    return identities != null && identities.isEmpty;
  }

  UserProfile _mergeSupabaseMetadata(UserProfile profile) {
    final currentUser = _supabaseOrNull?.auth.currentUser;
    final metadata = currentUser?.userMetadata ?? const <String, dynamic>{};
    final avatarEmoji = _normalizeAvatarEmoji(metadata['avatar_emoji']);
    if (avatarEmoji == profile.avatarEmoji) return profile;
    return profile.copyWith(avatarEmoji: avatarEmoji);
  }

  Future<AuthBootstrapResult> _completeSupabaseBootstrap({
    String? currency,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw const ApiException(
        'No pudimos recuperar tu sesión. Inténtalo otra vez.',
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
    final profile = _mergeSupabaseMetadata(UserProfile.fromJson(profileJson));

    final appSession = AuthSession(
      userId: profile.userId,
      token: session.accessToken,
      refreshToken: session.refreshToken,
      profile: profile,
    );

    await clearPendingVerificationEmail();

    return AuthBootstrapResult(
      session: appSession,
      isNewUser: data['isNewUser'] == true || data['is_new_user'] == true,
    );
  }

  Future<AuthBootstrapResult> bootstrapCurrentSupabaseSession({
    String? currency,
  }) {
    return _completeSupabaseBootstrap(currency: currency);
  }

  Future<AuthBootstrapResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = response.user ?? _supabase.auth.currentUser;
      final session = response.session ?? _supabase.auth.currentSession;

      if (user?.emailConfirmedAt == null || session == null) {
        await savePendingVerificationEmail(normalizedEmail);
        await _supabase.auth.signOut();
        throw const ApiException(
          'Tu correo todavía no ha sido confirmado. Revisa tu inbox y luego vuelve a entrar.',
        );
      }
      return _completeSupabaseBootstrap();
    } on AuthException catch (error) {
      final lower = error.message.trim().toLowerCase();
      final pendingEmail = await restorePendingVerificationEmail();
      final looksLikeUnverifiedEmail =
          lower.contains('email not confirmed') ||
          lower.contains('email not verified') ||
          ((lower.contains('invalid login credentials') ||
                  lower.contains('invalid_credentials')) &&
              pendingEmail == normalizedEmail);

      if (looksLikeUnverifiedEmail) {
        await savePendingVerificationEmail(normalizedEmail);
        throw const ApiException(
          'Tu correo todavía no ha sido confirmado. Revisa tu inbox y luego vuelve a entrar.',
        );
      }
      throw ApiException(error.message);
    }
  }

  Future<EmailRegistrationResult> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    String? currency,
  }) async {
    final normalizedName = _normalizeDisplayName(name);
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final result = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {'full_name': normalizedName},
        emailRedirectTo: AppEnv.authEmailRedirectUrl,
      );

      final user = result.user ?? _supabase.auth.currentUser;
      if (_isObfuscatedRepeatedSignup(user)) {
        await _supabase.auth.signOut();
        throw const ApiException(
          'Ese correo ya tiene una cuenta. Entra con tu contraseña o recupera el acceso.',
        );
      }

      if (user?.emailConfirmedAt == null) {
        await savePendingVerificationEmail(normalizedEmail);
        await _supabase.auth.signOut();
        return EmailRegistrationResult.pendingVerification(normalizedEmail);
      }

      final session = result.session ?? _supabase.auth.currentSession;
      if (session == null) {
        return EmailRegistrationResult.pendingVerification(normalizedEmail);
      }

      final bootstrap = await _completeSupabaseBootstrap(currency: currency);
      return EmailRegistrationResult.authenticated(normalizedEmail, bootstrap);
    } on AuthException catch (error) {
      throw ApiException(error.message);
    }
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

      return _completeSupabaseBootstrap(currency: currency);
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

  Future<void> verifyOtpTokenHash({
    required String tokenHash,
    required OtpType type,
  }) async {
    try {
      await _supabase.auth.verifyOTP(tokenHash: tokenHash, type: type);
    } on AuthException catch (error) {
      throw ApiException(error.message);
    }
  }

  Future<UserProfile> fetchProfile() async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiPaths.authMe,
      parser: asJsonMap,
    );
    return _mergeSupabaseMetadata(UserProfile.fromJson(response.requireData()));
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String currency,
    String? avatarEmoji,
    String? financialGoal,
    double? goalAmount,
    DateTime? goalDate,
  }) async {
    final normalizedName = _normalizeDisplayName(name);
    final response = await _api.patch<Map<String, dynamic>>(
      ApiPaths.authMe,
      body: {
        'nombre': normalizedName,
        'moneda_base': currency,
        'meta_financiera': financialGoal,
        'meta_monto': goalAmount,
        'meta_fecha': goalDate?.toIso8601String(),
      },
      parser: asJsonMap,
    );

    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': normalizedName,
            'avatar_emoji': avatarEmoji?.trim().isEmpty == true
                ? ''
                : avatarEmoji?.trim(),
          },
        ),
      );
    } on AuthException catch (error) {
      throw ApiException(error.message);
    }

    return _mergeSupabaseMetadata(UserProfile.fromJson(response.requireData()));
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

  Future<void> requestPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    await _api.post<Map<String, dynamic>>(
      ApiPaths.authPasswordRecovery,
      body: {'email': normalizedEmail, 'next': AppEnv.authPasswordResetNextUrl},
      authenticated: false,
      parser: asJsonMap,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _api.put<Map<String, dynamic>>(
      ApiPaths.authPassword,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      parser: asJsonMap,
    );
  }

  Future<void> updatePasswordFromRecovery(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      await clearPendingPasswordResetEmail();
    } on AuthException catch (error) {
      throw ApiException(error.message);
    }
  }

  Future<void> deleteAccount() async {
    await _api.delete<void>(ApiPaths.authDeleteAccount);

    try {
      await _supabaseOrNull?.auth.signOut();
    } catch (_) {
      // Local cleanup below is enough if the auth session is already invalidated.
    }

    await clearPendingVerificationEmail();
    await clearPendingPasswordResetEmail();
    await clearCachedSession();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiServiceProvider));
});
