import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../../../shared/widgets/menudo_card.dart';
import '../../../../shared/widgets/menudo_tap_target.dart';
import '../data/ios_shortcuts_bridge.dart';

class IosShortcutsSetupScreen extends ConsumerWidget {
  const IosShortcutsSetupScreen({super.key});

  bool get _supportsShortcuts =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bridge = ref.read(iosShortcutsBridgeProvider);

    return Scaffold(
      backgroundColor: context.menudo.background,
      appBar: AppBar(
        backgroundColor: context.menudo.surface,
        elevation: 0,
        leading: MenudoIconButton(
          onPressed: () {
            MenudoHaptics.light();
            context.pop();
          },
          icon: Icon(
            MenudoCupertinoIcons.arrowLeft,
            color: context.menudo.textMain,
          ),
        ),
        title: Text(
          'Automatizaciones',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: context.menudo.textMain,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          MenudoCard(
            padding: const EdgeInsets.all(22),
            color: context.menudo.textMain,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: context.menudo.textOnDark.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    MenudoCupertinoIcons.zap,
                    color: context.menudo.textOnDark,
                    size: (28),
                  ),
                ),
                SizedBox(height: (18)),
                Text(
                  'Gasto rápido',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: context.menudo.textOnDark,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _supportsShortcuts
                      ? 'Este acceso rápido ya está listo. Desde aquí puedes abrir la configuración del dispositivo.'
                      : 'Esta función se configura desde un iPhone con Menudo instalado.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.menudo.textOnDark.withValues(alpha: 0.84),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: (18)),
                MenudoButton(
                  label: 'Configurar acceso rápido',
                  isFullWidth: true,
                  icon: MenudoCupertinoIcons.sparkles,
                  isDisabled: !_supportsShortcuts,
                  onTap: () async {
                    MenudoHaptics.medium();
                    await bridge.presentShortcutSetup();
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: (18)),
          MenudoCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SimpleStep(
                  index: '1',
                  text: 'Abre Menudo una vez con tu sesión iniciada.',
                ),
                SizedBox(height: (12)),
                _SimpleStep(
                  index: '2',
                  text:
                      'Toca “Configurar acceso rápido” y activa “Registrar gasto rápido”.',
                ),
                SizedBox(height: (12)),
                _SimpleStep(
                  index: '3',
                  text:
                      'Luego podrás registrar monto, categoría y nota más rápido.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleStep extends StatelessWidget {
  final String index;
  final String text;

  const _SimpleStep({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: (24),
          height: (24),
          decoration: BoxDecoration(
            color: AppColors.e1,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            index,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: context.menudo.textMain,
            ),
          ),
        ),
        SizedBox(width: (12)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.menudo.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
