class UserProfile {
  const UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.baseCurrency,
  });

  final int userId;
  final String name;
  final String email;
  final String baseCurrency;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawUserId =
        json['usuario_id'] ??
        json['user_id'] ??
        json['id'] ??
        json['usuarioId'];

    final userId = switch (rawUserId) {
      int value => value,
      String value => int.parse(value),
      _ => throw const FormatException('Missing user id in profile response'),
    };

    return UserProfile(
      userId: userId,
      name: json['nombre']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      baseCurrency: json['moneda_base']?.toString() ?? 'DOP',
    );
  }
}
