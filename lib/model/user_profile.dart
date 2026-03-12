class UserProfile {
  const UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.baseCurrency,
    this.defaultBudgetId,
  });

  final int userId;
  final String name;
  final String email;
  final String baseCurrency;
  final int? defaultBudgetId;

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
      defaultBudgetId: switch (json['presupuesto_default_id'] ??
          json['default_budget_id']) {
        int value => value,
        String value => int.tryParse(value),
        num value => value.toInt(),
        _ => null,
      },
    );
  }

  UserProfile copyWith({
    int? userId,
    String? name,
    String? email,
    String? baseCurrency,
    int? defaultBudgetId,
    bool clearDefaultBudgetId = false,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      defaultBudgetId: clearDefaultBudgetId
          ? null
          : (defaultBudgetId ?? this.defaultBudgetId),
    );
  }
}
