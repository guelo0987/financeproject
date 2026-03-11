class SpaceSummary {
  const SpaceSummary({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.creadoPor,
    required this.rol,
    this.creadoEn,
    this.actualizadoEn,
    this.unidoEn,
  });

  final int id;
  final String nombre;
  final String? descripcion;
  final int creadoPor;
  final String rol;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final DateTime? unidoEn;

  factory SpaceSummary.fromJson(Map<String, dynamic> json) {
    return SpaceSummary(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      creadoPor: (json['creado_por'] as num?)?.toInt() ?? 0,
      rol: json['rol']?.toString() ?? 'miembro',
      creadoEn: _parseDateTime(json['creado_en']),
      actualizadoEn: _parseDateTime(json['actualizado_en']),
      unidoEn: _parseDateTime(json['unido_en']),
    );
  }
}

class SpaceMember {
  const SpaceMember({
    required this.usuarioId,
    required this.rol,
    this.unidoEn,
    this.nombre,
    this.email,
  });

  final int usuarioId;
  final String rol;
  final DateTime? unidoEn;
  final String? nombre;
  final String? email;

  bool get isAdmin => rol == 'admin';

  factory SpaceMember.fromJson(Map<String, dynamic> json) {
    return SpaceMember(
      usuarioId: (json['usuario_id'] as num).toInt(),
      rol: json['rol']?.toString() ?? 'miembro',
      unidoEn: _parseDateTime(json['unido_en']),
      nombre: json['nombre']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class SpaceInvitation {
  const SpaceInvitation({
    required this.id,
    required this.emailInvitado,
    required this.estado,
    this.token,
    this.expiraEn,
    this.creadoEn,
    this.invitadoPor,
  });

  final int id;
  final String emailInvitado;
  final String estado;
  final String? token;
  final DateTime? expiraEn;
  final DateTime? creadoEn;
  final int? invitadoPor;

  factory SpaceInvitation.fromJson(Map<String, dynamic> json) {
    return SpaceInvitation(
      id: (json['invitacion_id'] as num).toInt(),
      emailInvitado: json['email_invitado']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'pendiente',
      token: json['token']?.toString(),
      expiraEn: _parseDateTime(json['expira_en']),
      creadoEn: _parseDateTime(json['creado_en']),
      invitadoPor: (json['invitado_por'] as num?)?.toInt(),
    );
  }
}

class SpaceDetail {
  const SpaceDetail({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.creadoPor,
    this.creadoEn,
    this.actualizadoEn,
    required this.miembros,
    required this.invitaciones,
  });

  final int id;
  final String nombre;
  final String? descripcion;
  final int creadoPor;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final List<SpaceMember> miembros;
  final List<SpaceInvitation> invitaciones;

  factory SpaceDetail.fromJson(
    Map<String, dynamic> json, {
    List<SpaceInvitation> invitaciones = const [],
  }) {
    final membersJson = json['miembros'] as List<dynamic>? ?? const [];
    return SpaceDetail(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      creadoPor: (json['creado_por'] as num?)?.toInt() ?? 0,
      creadoEn: _parseDateTime(json['creado_en']),
      actualizadoEn: _parseDateTime(json['actualizado_en']),
      miembros: membersJson
          .map((member) => SpaceMember.fromJson(Map<String, dynamic>.from(member as Map)))
          .toList(),
      invitaciones: invitaciones,
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
