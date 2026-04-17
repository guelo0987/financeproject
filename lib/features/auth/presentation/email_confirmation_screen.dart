import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/menudo_loading_view.dart';
import '../auth_state.dart';

class EmailConfirmationScreen extends ConsumerWidget {
  const EmailConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final pendingEmail = authState.pendingVerificationEmail;

    final message = authState.isAuthenticated
        ? 'Tu correo ya quedó confirmado. Estamos entrando a tu cuenta.'
        : pendingEmail == null
        ? 'Estamos validando el enlace de confirmación. Si tarda demasiado, vuelve a abrir el correo más reciente.'
        : 'Estamos validando el correo de $pendingEmail. Cuando la verificación termine te llevaremos a Menudo.';

    return Scaffold(
      body: SafeArea(
        child: MenudoLoadingView(
          title: 'Confirmando tu correo',
          message: message,
          logoSize: 136,
        ),
      ),
    );
  }
}
