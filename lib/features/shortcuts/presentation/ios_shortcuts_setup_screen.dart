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
import '../../../../shared/widgets/menudo_toast.dart';
import '../data/ios_shortcuts_bridge.dart';

class IosShortcutsSetupScreen extends ConsumerWidget {
  final bool firstRun;

  const IosShortcutsSetupScreen({super.key, this.firstRun = false});

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
          firstRun ? 'Configura tu atajo' : 'Automatizaciones',
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
                    color: context.menudo.surface.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    MenudoCupertinoIcons.zap,
                    color: context.menudo.textOnDark,
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
                      ? firstRun
                            ? 'Menudo ya publica “Registrar Gasto” como App Shortcut nativo. Enlázalo una vez a Apple Pay y déjalo listo para Siri.'
                            : 'Menudo publica “Registrar Gasto” como App Shortcut nativo. Siri y Shortcuts lo ven automáticamente después de instalar la app.'
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
                  label: 'Abrir Atajos',
                  isFullWidth: true,
                  icon: MenudoCupertinoIcons.sparkles,
                  isDisabled: !_supportsShortcuts,
                  onTap: () async {
                    MenudoHaptics.medium();
                    await bridge.requestShortcutNotificationAuthorization();
                    final opened = await bridge.openShortcutsApp();
                    if (!opened) {
                      await bridge.presentShortcutSetup();
                      if (context.mounted) {
                        MenudoToast.error(
                          context,
                          title: 'No se pudo abrir Atajos',
                          message:
                              'Te dejamos la guía aquí para terminar la configuración.',
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: (18)),
          const _LiveActivityTipCard(),
          SizedBox(height: (18)),
          const _ShortcutCreationGuideCard(),
          SizedBox(height: (18)),
          const _ApplePayAutomationGuideCard(),
          SizedBox(height: (18)),
          const _ShortcutAutomationStoryboard(),
          SizedBox(height: (18)),
          const _DoubleTapSetupCard(),
        ],
      ),
    );
  }
}

class _LiveActivityTipCard extends StatelessWidget {
  const _LiveActivityTipCard();

  @override
  Widget build(BuildContext context) {
    return MenudoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.b5.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(MenudoCupertinoIcons.bell, color: AppColors.b5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cuando uses el shortcut Registrar Gasto, la confirmación aparece fuera de Menudo: mírala en Dynamic Island, en la pantalla bloqueada o desde una notificación discreta.',
              style: TextStyle(
                fontSize: 13,
                height: 1.32,
                fontWeight: FontWeight.w700,
                color: context.menudo.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.03, end: 0);
  }
}

class _ShortcutCreationGuideCard extends StatelessWidget {
  const _ShortcutCreationGuideCard();

  @override
  Widget build(BuildContext context) {
    return _GuidedSetupCard(
      title: 'Crear el atajo visible',
      subtitle: 'Hazlo una vez en la app Atajos.',
      icon: MenudoCupertinoIcons.zap,
      color: AppColors.o5,
      steps: const [
        _GuideStepData(
          title: 'Abre Atajos',
          text: 'Toca el botón de arriba para ir directo a la app Shortcuts.',
          icon: MenudoCupertinoIcons.sparkles,
        ),
        _GuideStepData(
          title: 'Toca +',
          text: 'Crea un shortcut nuevo desde el botón de más.',
          icon: MenudoCupertinoIcons.plus,
        ),
        _GuideStepData(
          title: 'Busca Menudo',
          text: 'En acciones, escribe Menudo y elige Registrar Gasto.',
          icon: MenudoCupertinoIcons.search,
        ),
        _GuideStepData(
          title: 'Listo y vuelve',
          text: 'Guarda el shortcut y vuelve a Menudo para enlazar Apple Pay.',
          icon: MenudoCupertinoIcons.checkCircle,
        ),
      ],
    );
  }
}

class _ApplePayAutomationGuideCard extends StatelessWidget {
  const _ApplePayAutomationGuideCard();

  @override
  Widget build(BuildContext context) {
    return _GuidedSetupCard(
      title: 'Enlazar Apple Pay',
      subtitle: 'La automatización queda aprobada por iOS.',
      icon: MenudoCupertinoIcons.creditCard,
      color: AppColors.e6,
      steps: const [
        _GuideStepData(
          title: 'Automatización',
          text: 'En Atajos, entra a Automation y crea una personal.',
          icon: MenudoCupertinoIcons.layoutGrid,
        ),
        _GuideStepData(
          title: 'Busca Wallet',
          text: 'Elige Wallet o Transaction como disparador del pago.',
          icon: MenudoCupertinoIcons.wallet,
        ),
        _GuideStepData(
          title: 'Tu tarjeta',
          text: 'Selecciona la tarjeta y marca Run Immediately.',
          icon: MenudoCupertinoIcons.creditCard,
        ),
        _GuideStepData(
          title: 'Registrar Gasto',
          text: 'Como acción final, elige el shortcut de Menudo.',
          icon: MenudoCupertinoIcons.zap,
        ),
      ],
    );
  }
}

class _GuidedSetupCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_GuideStepData> steps;

  const _GuidedSetupCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return MenudoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: context.menudo.textMain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.menudo.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++) ...[
            _VisualGuideStep(index: i + 1, data: steps[i], color: color),
            if (i != steps.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.03, end: 0);
  }
}

class _GuideStepData {
  final String title;
  final String text;
  final IconData icon;

  const _GuideStepData({
    required this.title,
    required this.text,
    required this.icon,
  });
}

class _VisualGuideStep extends StatelessWidget {
  final int index;
  final _GuideStepData data;
  final Color color;

  const _VisualGuideStep({
    required this.index,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.menudo.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.menudo.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Icon(data.icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${data.title}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: context.menudo.textMain,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.text,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.28,
                    fontWeight: FontWeight.w600,
                    color: context.menudo.textSecondary,
                  ),
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
                  color: menudo.textMain,
                  accent: menudo.success,
                  textColor: menudo.background,
                ),
                _StoryClayCard(
                  icon: MenudoCupertinoIcons.zap,
                  title: 'Registrar Gasto',
                  caption: 'Atajo nativo',
                  color: menudo.primary,
                  accent: menudo.primaryLight,
                  textColor: Colors.white,
                ),
                _StoryClayCard(
                  icon: MenudoCupertinoIcons.checkCircle,
                  title: 'Menudo',
                  caption: 'Guardado',
                  color: menudo.success,
                  accent: menudo.successLight,
                  textColor: Colors.white,
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

class _DoubleTapSetupCard extends StatelessWidget {
  const _DoubleTapSetupCard();

  @override
  Widget build(BuildContext context) {
    final menudo = context.menudo;

    return MenudoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: menudo.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  MenudoCupertinoIcons.sparkles,
                  color: menudo.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Double Tap',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: menudo.textMain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Atajo físico desde el toque posterior del iPhone.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: menudo.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: menudo.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: menudo.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SimpleStep(
                  index: '1',
                  text:
                      'Abre Ajustes del iPhone, entra en Accesibilidad, Tocar y luego Toque posterior.',
                ),
                SizedBox(height: 12),
                _SimpleStep(
                  index: '2',
                  text:
                      'En “Tocar dos veces”, elige Shortcuts y selecciona Registrar Gasto de Menudo.',
                ),
                SizedBox(height: 12),
                _SimpleStep(
                  index: '3',
                  text:
                      'Desde ahí, dos toques atrás preparan el registro sin buscar la app.',
                ),
              ],
            ),
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
  final Color textColor;

  const _StoryClayCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.color,
    required this.accent,
    required this.textColor,
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
                    color: textColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: textColor),
                ),
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: textColor.withValues(alpha: 0.7),
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
              style: TextStyle(
                color: textColor,
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
                color: textColor.withValues(alpha: 0.78),
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
