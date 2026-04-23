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
  if (lower.contains(
    'solo admins pueden administrar este presupuesto compartido',
  )) {
    return 'Solo quien administra este presupuesto puede hacer ese cambio.';
  }
  if (lower.contains('solo propietario') ||
      lower.contains('solo el creador') ||
      lower.contains('owner_only')) {
    return 'Solo quien creó este presupuesto puede eliminarlo.';
  }
  if (lower.contains('already_member')) {
    return 'Esa persona ya forma parte de este presupuesto.';
  }
  if (lower.contains('invite_pending')) {
    return 'Ya hay una invitación pendiente para ese correo.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Tu correo todavía no ha sido confirmado. Revisa tu inbox y luego vuelve a entrar.';
  }
  if (lower.contains('email not verified')) {
    return 'Tu correo todavía no ha sido confirmado. Revisa tu inbox y luego vuelve a entrar.';
  }
  if (lower.contains('otp_expired') ||
      lower.contains('email link is invalid or has expired')) {
    return 'Ese enlace ya venció. Pide uno nuevo desde Menudo.';
  }
  if (lower.contains('email_error')) {
    return 'No pudimos enviar la invitación ahora mismo. Inténtalo otra vez.';
  }
  if (lower.contains('domain not verified') ||
      lower.contains('invalid from address') ||
      (lower.contains('resend') && lower.contains('from'))) {
    return 'El correo de invitación no está configurado correctamente todavía.';
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
  if (lower.contains('categoria_con_subcategorias')) {
    return 'No puedes eliminar este grupo porque todavía tiene categorías dentro.';
  }
  if (lower.contains('categoria_en_presupuesto')) {
    return 'No puedes eliminar esta categoría porque todavía está en uso en un presupuesto.';
  }
  if (lower.contains('system_category_immutable')) {
    return 'Solo puedes cambiar categorías creadas por ti.';
  }
  if (lower.contains('category_duplicate_name')) {
    return 'Ya existe una categoría con ese nombre.';
  }
  if (lower.contains('budget_not_found') ||
      lower.contains('presupuesto no encontrado')) {
    return 'No encontramos ese presupuesto.';
  }

  return message;
}
