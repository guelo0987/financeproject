import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/menudo_blurred_app_bar.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const MenudoBlurredBar(),
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
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
          20,
          28,
        ),
        children: [
          MenudoCard(
            padding: const EdgeInsets.all(22),
            color: context.menudo.hero,
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
                  child: Icon(MenudoCupertinoIcons.zap, color: Colors.white),
                ),
                SizedBox(height: (18)),
                Text(
                  'Gasto rápido',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _supportsShortcuts
                      ? 'Menudo publica “Registrar Gasto” como App Shortcut nativo. Siri y Shortcuts lo ven automáticamente después de instalar la app.'
                      : 'Esta función se configura desde un iPhone con Menudo instalado.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.84),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: (18)),
                MenudoButton(
                  label: 'Ver atajo nativo',
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
          const _ShortcutAutomationStoryboard(),
          SizedBox(height: (18)),
          MenudoCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SimpleStep(
                  index: '1',
                  text:
                      'Abre Menudo una vez con tu sesión iniciada para sincronizar billetera, categorías y sesión segura.',
                ),
                SizedBox(height: (12)),
                _SimpleStep(
                  index: '2',
                  text:
                      'En Atajos, elige la automatización de Apple Pay y selecciona la acción “Registrar Gasto” de Menudo.',
                ),
                SizedBox(height: (12)),
                _SimpleStep(
                  index: '3',
                  text:
                      'iOS pedirá aprobar esa automatización personal una vez. Después, Menudo procesa el gasto sin abrir Flutter.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutAutomationStoryboard extends StatelessWidget {
  const _ShortcutAutomationStoryboard();

  @override
  Widget build(BuildContext context) {
    final menudo = context.menudo;

    return MenudoCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(MenudoCupertinoIcons.sparkles, color: menudo.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Flujo invisible',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: menudo.textMain,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: (16)),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 360;
              final cards = [
                _StoryClayCard(
                  icon: MenudoCupertinoIcons.creditCard,
                  title: 'Apple Pay',
                  caption: 'Pago detectado',
                  color: const Color(0xFF111827),
                  accent: const Color(0xFF8BE0C2),
                ),
                _StoryClayCard(
                  icon: MenudoCupertinoIcons.zap,
                  title: 'Registrar Gasto',
                  caption: 'Atajo nativo',
                  color: const Color(0xFFFF8A3D),
                  accent: const Color(0xFFFFD9B5),
                ),
                _StoryClayCard(
                  icon: MenudoCupertinoIcons.checkCircle,
                  title: 'Menudo',
                  caption: 'Guardado',
                  color: const Color(0xFF0F6B4D),
                  accent: const Color(0xFFA7F3D0),
                ),
              ];

              if (isCompact) {
                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      cards[i],
                      if (i != cards.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Icon(
                            MenudoCupertinoIcons.chevronDown,
                            color: menudo.textMuted,
                          ),
                        ),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: cards[0]),
                  _StoryConnector(color: menudo.textMuted),
                  Expanded(child: cards[1]),
                  _StoryConnector(color: menudo.textMuted),
                  Expanded(child: cards[2]),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.03, end: 0);
  }
}

class _StoryClayCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;
  final Color color;
  final Color accent;

  const _StoryClayCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.color,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 128),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white),
                ),
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                    child: CircleAvatar(radius: 10, backgroundColor: accent),
                  ),
                ),
              ],
            ),
            SizedBox(height: (16)),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryConnector extends StatelessWidget {
  final Color color;

  const _StoryConnector({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(MenudoCupertinoIcons.chevronRight, color: color),
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
        CircleAvatar(
          radius: 12,
          backgroundColor: context.menudo.successLight,
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
