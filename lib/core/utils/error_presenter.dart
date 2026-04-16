import '../../types/api_exception.dart';

String presentError(
  Object error, {
  String fallback =
      'No pudimos completar esto ahora mismo. Inténtalo otra vez.',
}) {
  var message = switch (error) {
    ApiException(message: final m) => m,
    _ => error.toString(),
  }.trim();

  message = message
      .replaceFirst(
        RegExp(
          r'^(Bad state:|StateError:|Exception:|FormatException:)\s*',
          caseSensitive: false,
        ),
        '',
      )
      .trim();

  if (message.isEmpty) {
    return fallback;
  }

  final lower = message.toLowerCase();
  if (lower == 'request failed') {
    return fallback;
  }
  if (lower.contains('missing user id') || lower.contains('missing token')) {
    return 'No pudimos iniciar tu sesión. Inténtalo otra vez.';
  }
  if (lower.contains('socketexception') || lower.contains('clientexception')) {
    return 'No pudimos conectarnos en este momento. Revisa tu conexión e inténtalo otra vez.';
  }
  if (lower.contains('rate_limit') || lower.contains('too many requests')) {
    return 'Vas muy rápido. Espera un momento e inténtalo otra vez.';
  }
  if (lower.contains(
    'solo admins pueden modificar este presupuesto compartido',
  )) {
    return 'Solo quien administra este presupuesto puede hacer ese cambio.';
  }
  if (lower.contains('already_member')) {
    return 'Esa persona ya forma parte de este presupuesto.';
  }
  if (lower.contains('invite_pending')) {
    return 'Ya hay una invitación pendiente para ese correo.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Primero confirma tu correo y luego intenta entrar otra vez.';
  }
  if (lower.contains('email_error')) {
    return 'No pudimos enviar la invitación ahora mismo. Inténtalo otra vez.';
  }
  if (lower.contains('limite_miembros')) {
    return 'Este presupuesto ya llegó al límite de personas.';
  }
  if (lower.contains('moneda_mismatch')) {
    return 'La moneda de este movimiento no coincide con la de la cuenta.';
  }
  if (lower.contains('cuenta_con_transacciones')) {
    return 'No puedes eliminar esta cuenta porque ya tiene movimientos.';
  }
  if (lower.contains('categoria_con_transacciones')) {
    return 'No puedes eliminar esta categoría porque ya tiene movimientos.';
  }
  if (lower.contains('categoria_en_presupuesto')) {
    return 'No puedes eliminar esta categoría porque todavía está en uso en un presupuesto.';
  }

  return message;
}
