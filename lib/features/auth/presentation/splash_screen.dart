import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/menudo_loading_view.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.menudo.background,
      body: SafeArea(
        child: MenudoLoadingView(
          title: 'Preparando tu espacio',
          message: 'Un momento mientras dejamos todo listo.',
          logoSize: 148,
        ),
      ),
    );
  }
}
