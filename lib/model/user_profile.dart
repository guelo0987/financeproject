class UserProfile {
  const UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.baseCurrency,
    this.financialGoal,
    this.goalAmount,
    this.goalDate,
    this.createdAt,
    this.defaultBudgetId,
  });

  final int userId;
  final String name;
  final String email;
  final String baseCurrency;
  final String? financialGoal;
  final double? goalAmount;
  final DateTime? goalDate;
  final DateTime? createdAt;
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
      financialGoal: json['meta_financiera']?.toString(),
      goalAmount: switch (json['meta_monto']) {
        num value => value.toDouble(),
        String value => double.tryParse(value),
        _ => null,
      },
      goalDate: switch (json['meta_fecha']) {
        DateTime value => value,
        String value => DateTime.tryParse(value),
        _ => null,
      },
      createdAt: switch (json['creado_en']) {
        DateTime value => value,
        String value => DateTime.tryParse(value),
        _ => null,
      },
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
    String? financialGoal,
    double? goalAmount,
    DateTime? goalDate,
    DateTime? createdAt,
    int? defaultBudgetId,
    bool clearDefaultBudgetId = false,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      financialGoal: financialGoal ?? this.financialGoal,
      goalAmount: goalAmount ?? this.goalAmount,
      goalDate: goalDate ?? this.goalDate,
      createdAt: createdAt ?? this.createdAt,
      defaultBudgetId: clearDefaultBudgetId
          ? null
          : (defaultBudgetId ?? this.defaultBudgetId),
    );
  }
}
