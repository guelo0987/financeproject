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
  if (lower.contains(
    'solo admins pueden modificar este presupuesto compartido',
  )) {
    return 'Solo quien administra este presupuesto puede hacer ese cambio.';
  }

  return message;
}
