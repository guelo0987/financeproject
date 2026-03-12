import 'dart:convert';

class AlertExtra {
  const AlertExtra({
    this.token,
    this.budgetId,
    this.spaceId,
    this.invitedBy,
    this.budgetName,
  });

  final String? token;
  final int? budgetId;
  final int? spaceId;
  final String? invitedBy;
  final String? budgetName;

  factory AlertExtra.fromJson(Object? raw) {
    final map = switch (raw) {
      Map<String, dynamic> value => value,
      Map value => Map<String, dynamic>.from(value),
      String value when value.trim().isNotEmpty => Map<String, dynamic>.from(
        jsonDecode(value) as Map,
      ),
      _ => const <String, dynamic>{},
    };

    int? parseInt(Object? value) {
      return switch (value) {
        int data => data,
        num data => data.toInt(),
        String data => int.tryParse(data),
        _ => null,
      };
    }

    return AlertExtra(
      token: map['token']?.toString(),
      budgetId: parseInt(
        map['presupuesto_id'] ?? map['budget_id'] ?? map['budgetId'],
      ),
      spaceId: parseInt(map['espacio_id'] ?? map['space_id'] ?? map['spaceId']),
      invitedBy:
          map['invitado_por']?.toString() ??
          map['invited_by']?.toString() ??
          map['invitedBy']?.toString(),
      budgetName:
          map['budget_nombre']?.toString() ??
          map['budget_name']?.toString() ??
          map['budgetName']?.toString(),
    );
  }
}

class AppAlert {
  const AppAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.extra,
    this.spaceId,
    this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final AlertExtra extra;
  final int? spaceId;
  final DateTime? createdAt;

  bool get isBudgetInvitation => type == 'invitacion_presupuesto';

  bool get isAcceptedInvitation => type == 'invitacion_aceptada';

  bool get canAcceptInApp =>
      isBudgetInvitation &&
      !isRead &&
      (extra.token?.trim().isNotEmpty ?? false);

  AppAlert copyWith({bool? isRead}) {
    return AppAlert(
      id: id,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      extra: extra,
      spaceId: spaceId,
      createdAt: createdAt,
    );
  }

  factory AppAlert.fromJson(Map<String, dynamic> json) {
    int parseInt(Object? value) {
      return switch (value) {
        int data => data,
        num data => data.toInt(),
        String data => int.parse(data),
        _ => 0,
      };
    }

    return AppAlert(
      id: parseInt(json['id'] ?? json['alerta_id']),
      type: json['tipo']?.toString() ?? '',
      title: json['titulo']?.toString() ?? '',
      body: json['cuerpo']?.toString() ?? '',
      isRead: json['fue_leida'] == true,
      extra: AlertExtra.fromJson(json['datos_extra']),
      spaceId: switch (json['espacio_id']) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value),
        _ => null,
      },
      createdAt: DateTime.tryParse(json['creado_en']?.toString() ?? ''),
    );
  }
}
