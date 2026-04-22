import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../../../shared/widgets/menudo_card.dart';
import '../data/ios_shortcuts_bridge.dart';

class IosShortcutsSetupScreen extends ConsumerWidget {
  const IosShortcutsSetupScreen({super.key});

  bool get _supportsShortcuts =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bridge = ref.read(iosShortcutsBridgeProvider);

    return Scaffold(
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.e8),
        ),
        title: const Text(
          'Atajos de iPhone',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.e8,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          MenudoCard(
            padding: const EdgeInsets.all(22),
            color: AppColors.e8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.zap,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Gasto rápido',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _supportsShortcuts
                      ? 'El atajo ya viene listo. Desde aquí solo abres Shortcuts para verlo o asignarlo.'
                      : 'Esta integración se configura desde un iPhone con la app Menudo instalada.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.84),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                MenudoButton(
                  label: 'Abrir Shortcuts',
                  isFullWidth: true,
                  icon: LucideIcons.sparkles,
                  isDisabled: !_supportsShortcuts,
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await bridge.presentShortcutSetup();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          MenudoCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SimpleStep(
                  index: '1',
                  text: 'Abre Menudo una vez con tu sesión iniciada.',
                ),
                SizedBox(height: 12),
                _SimpleStep(
                  index: '2',
                  text: 'Toca “Abrir Shortcuts” y busca “Registrar gasto rápido”.',
                ),
                SizedBox(height: 12),
                _SimpleStep(
                  index: '3',
                  text: 'Ese atajo registra monto, categoría y nota.',
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
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.e1,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            index,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.e8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.g5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
