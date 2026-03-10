class AuthSession {
  const AuthSession({
    required this.userId,
    required this.token,
    this.refreshToken,
  });

  final int userId;
  final String token;
  final String? refreshToken;

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
      _ => throw FormatException('Missing user id in auth response'),
    };

    final token = rawToken?.toString();
    if (token == null || token.isEmpty) {
      throw const FormatException('Missing token in auth response');
    }

    return AuthSession(
      userId: userId,
      token: token,
      refreshToken:
          json['refreshToken']?.toString() ?? json['refresh_token']?.toString(),
    );
  }
}
