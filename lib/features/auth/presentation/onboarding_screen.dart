import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/menudo_cupertino_icons.dart';
import '../../../core/utils/menudo_haptics.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_tap_target.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingSlideData(
      title: 'Paz mental con tu dinero',
      subtitle:
          'Menudo convierte tus cuentas y movimientos en una vista clara, sin ruido ni hojas de cálculo.',
      action: 'Sentirte en control',
      visual: _OnboardingVisualType.calm,
    ),
    _OnboardingSlideData(
      title: 'Apple Pay entra solo',
      subtitle:
          'Pagas, eliges la categoría desde Siri o una notificación, y el gasto queda registrado sin abrir Flutter.',
      action: 'Ver el flujo automático',
      visual: _OnboardingVisualType.applePay,
    ),
    _OnboardingSlideData(
      title: 'Decisiones sin ansiedad',
      subtitle:
          'Menudo te muestra lo que puedes gastar hoy y lo que conviene reservar antes de que sea tarde.',
      action: 'Planificar con calma',
      visual: _OnboardingVisualType.insight,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    MenudoHaptics.selection();
    if (_currentPage < _slides.length - 1) {
      await _pageController.animateToPage(
        _currentPage + 1,
        duration: 460.ms,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!mounted) return;
    context.go('/register');
  }

  void _goLogin() {
    MenudoHaptics.selection();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final current = _slides[_currentPage];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.p12,
                AppSpacing.screen,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'Menudo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colors.textMain,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  MenudoGestureDetector(
                    onTap: _goLogin,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.p8,
                        vertical: AppSpacing.p10,
                      ),
                      child: Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  MenudoHaptics.selection();
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _NarrativeSlide(data: slide);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.p8,
                AppSpacing.screen,
                MediaQuery.paddingOf(context).bottom + AppSpacing.p18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: 220.ms,
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.p4,
                        ),
                        width: _currentPage == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colors.primary
                              : colors.border,
                          borderRadius: BorderRadius.circular(
                            MenudoRadius.pill,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p20),
                  MenudoPrimaryButton(
                    label: _currentPage < _slides.length - 1
                        ? current.action
                        : 'Crear cuenta',
                    onTap: _goNext,
                    icon: _currentPage < _slides.length - 1
                        ? MenudoCupertinoIcons.chevronRight
                        : MenudoCupertinoIcons.arrow_up_right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NarrativeSlide extends StatelessWidget {
  const _NarrativeSlide({required this.data});

  final _OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.p10,
        AppSpacing.screen,
        AppSpacing.p12,
      ),
      child: Column(
        children: [
          Expanded(child: _OnboardingVisual(type: data.visual)),
          const SizedBox(height: AppSpacing.p20),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: colors.textMain,
              letterSpacing: 0,
            ),
          ).animate(key: ValueKey(data.title)).fadeIn().slideY(begin: 0.05),
          const SizedBox(height: AppSpacing.p14),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 0,
            ),
          ).animate(key: ValueKey(data.subtitle)).fadeIn(delay: 80.ms),
        ],
      ),
    );
  }
}

class _OnboardingVisual extends StatelessWidget {
  const _OnboardingVisual({required this.type});

  final _OnboardingVisualType type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      _OnboardingVisualType.calm => const _CalmMoneyScene(),
      _OnboardingVisualType.applePay => const _ApplePayScene(),
      _OnboardingVisualType.insight => const _InsightScene(),
    };
  }
}

class _CalmMoneyScene extends StatelessWidget {
  const _CalmMoneyScene();

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Center(
      child: SizedBox(
        width: 310,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 34,
              child:
                  _SoftTile(
                        width: 236,
                        height: 142,
                        color: colors.hero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _RoundIcon(
                                  icon: MenudoCupertinoIcons.shieldCheck,
                                  color: colors.success,
                                ),
                                const Spacer(),
                                Text(
                                  'DOP',
                                  style: TextStyle(
                                    color: colors.textOnDarkSub,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'RD\$86,252',
                              style: TextStyle(
                                color: colors.textOnDark,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.p6),
                            Text(
                              'Patrimonio claro',
                              style: TextStyle(
                                color: colors.textOnDarkSub,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(delay: 900.ms, duration: 1800.ms),
            ),
            Positioned(
              bottom: 38,
              left: 34,
              child: _MiniPill(
                icon: MenudoCupertinoIcons.checkCircle,
                label: 'Cuentas al día',
                color: colors.success,
              ).animate().fadeIn(delay: 260.ms).slideX(begin: -0.12),
            ),
            Positioned(
              bottom: 84,
              right: 24,
              child: _MiniPill(
                icon: MenudoCupertinoIcons.sparkles,
                label: 'Sin ruido',
                color: colors.primary,
              ).animate().fadeIn(delay: 360.ms).slideX(begin: 0.12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplePayScene extends StatelessWidget {
  const _ApplePayScene();

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Center(
      child: SizedBox(
        width: 320,
        height: 312,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 16,
              child: _PhoneFrame(
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(MenudoRadius.pill),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.p18),
                    _ApplePayCard(),
                    const SizedBox(height: AppSpacing.p18),
                    _ShortcutNotification(),
                  ],
                ),
              ),
            ),
            Positioned(bottom: 14, right: 14, child: _FloatingShortcutBadge()),
          ],
        ),
      ),
    );
  }
}

class _InsightScene extends StatelessWidget {
  const _InsightScene();

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final bars = [0.45, 0.74, 0.58, 0.34, 0.86];

    return Center(
      child: SizedBox(
        width: 310,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _SoftTile(
              width: 246,
              height: 178,
              color: colors.surface,
              borderColor: colors.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disponible hoy',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p8),
                  Text(
                    'RD\$12,480',
                    style: TextStyle(
                      color: colors.textMain,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 58,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final value in bars) ...[
                          Expanded(
                            child: FractionallySizedBox(
                              heightFactor: value,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: value > 0.8
                                      ? colors.primary
                                      : colors.success,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.p8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.96, 0.96)),
            Positioned(
              top: 46,
              right: 22,
              child: _MiniPill(
                icon: MenudoCupertinoIcons.trendingUp,
                label: 'A tiempo',
                color: colors.success,
              ),
            ),
            Positioned(
              bottom: 38,
              left: 26,
              child: _MiniPill(
                icon: MenudoCupertinoIcons.piggyBank,
                label: 'Reserva lista',
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
      width: 236,
      height: 276,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.p16,
        AppSpacing.p14,
        AppSpacing.p16,
        AppSpacing.p16,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.textMain.withValues(alpha: 0.12),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    ).animate().fadeIn().slideY(begin: 0.04);
  }
}

class _ApplePayCard extends StatelessWidget {
  const _ApplePayCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.p16),
          decoration: BoxDecoration(
            color: colors.hero,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.apple, color: colors.textOnDark, size: 20),
                  const SizedBox(width: AppSpacing.p6),
                  Text(
                    'Pay',
                    style: TextStyle(
                      color: colors.textOnDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    MenudoCupertinoIcons.creditCard,
                    color: colors.textOnDarkSub,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.p18),
              Text(
                'Café Santo',
                style: TextStyle(
                  color: colors.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.p4),
              Text(
                'RD\$250',
                style: TextStyle(
                  color: colors.textOnDarkSub,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.985, 0.985),
          end: const Offset(1.015, 1.015),
          duration: 1300.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _ShortcutNotification extends StatelessWidget {
  const _ShortcutNotification();

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.p12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _RoundIcon(
            icon: MenudoCupertinoIcons.sparkles,
            color: colors.primary,
          ),
          const SizedBox(width: AppSpacing.p10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menudo detectó el pago',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMain,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.p2),
                Text(
                  'Comida',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.18);
  }
}

class _FloatingShortcutBadge extends StatelessWidget {
  const _FloatingShortcutBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.p14,
        vertical: AppSpacing.p10,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(MenudoRadius.pill),
        boxShadow: [
          BoxShadow(
            color: colors.primaryGlow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(MenudoCupertinoIcons.check, color: colors.textOnDark, size: 16),
          const SizedBox(width: AppSpacing.p6),
          Text(
            'Guardado',
            style: TextStyle(
              color: colors.textOnDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    ).animate(delay: 780.ms).fadeIn().scale(begin: const Offset(0.82, 0.82));
  }
}

class _SoftTile extends StatelessWidget {
  const _SoftTile({
    required this.width,
    required this.height,
    required this.color,
    required this.child,
    this.borderColor,
  });

  final double width;
  final double height;
  final Color color;
  final Color? borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(AppSpacing.p18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        border: borderColor == null ? null : Border.all(color: borderColor!),
        boxShadow: [
          BoxShadow(
            color: colors.textMain.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.p12,
        vertical: AppSpacing.p10,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(MenudoRadius.pill),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.p6),
          Text(
            label,
            style: TextStyle(
              color: colors.textMain,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.visual,
  });

  final String title;
  final String subtitle;
  final String action;
  final _OnboardingVisualType visual;
}

enum _OnboardingVisualType { calm, applePay, insight }
