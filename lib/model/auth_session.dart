import 'user_profile.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.token,
    this.refreshToken,
    this.profile,
  });

  final int userId;
  final String token;
  final String? refreshToken;
  final UserProfile? profile;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userPayload = json['usuario'] ?? json['user'];
    final user = userPayload is Map
        ? Map<String, dynamic>.from(userPayload)
        : const <String, dynamic>{};
    final rawUserId =
        json['user_id'] ??
        json['usuario_id'] ??
        json['id'] ??
        json['usuarioId'] ??
        user['id'] ??
        user['user_id'] ??
        user['usuario_id'] ??
        user['usuarioId'];
    final rawToken =
        json['accessToken'] ??
        json['token'] ??
        json['access_token'] ??
        json['jwt'] ??
        json['bearer_token'];

    final userId = switch (rawUserId) {
      int value => value,
      String value => int.parse(value),
      _ => throw const FormatException('No pudimos iniciar tu sesión.'),
    };

    final token = rawToken?.toString();
    if (token == null || token.isEmpty) {
      throw const FormatException('No pudimos iniciar tu sesión.');
    }

    return AuthSession(
      userId: userId,
      token: token,
      refreshToken:
          json['refreshToken']?.toString() ?? json['refresh_token']?.toString(),
      profile: user.isEmpty ? null : UserProfile.fromJson(user),
    );
  }
}

class AuthBootstrapResult {
  const AuthBootstrapResult({required this.session, required this.isNewUser});

  final AuthSession session;
  final bool isNewUser;
}

class EmailRegistrationResult {
  const EmailRegistrationResult._({
    required this.email,
    required this.requiresEmailVerification,
    this.bootstrap,
  });

  final String email;
  final bool requiresEmailVerification;
  final AuthBootstrapResult? bootstrap;

  factory EmailRegistrationResult.authenticated(
    String email,
    AuthBootstrapResult bootstrap,
  ) {
    return EmailRegistrationResult._(
      email: email,
      requiresEmailVerification: false,
      bootstrap: bootstrap,
    );
  }

  factory EmailRegistrationResult.pendingVerification(String email) {
    return EmailRegistrationResult._(
      email: email,
      requiresEmailVerification: true,
    );
  }
}
