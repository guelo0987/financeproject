import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/menudo_haptics.dart';
import '../../../shared/widgets/menudo_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _pageSpringController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageSpringController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (!_pageController.hasClients) return;
        final position = _pageController.position;
        _pageController.jumpTo(
          _pageSpringController.value.clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
      });
  }

  @override
  void dispose() {
    _pageSpringController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    MenudoHaptics.selection();
    if (_currentPage < 2) {
      if (!_pageController.hasClients) return;
      final position = _pageController.position;
      final targetPixels = ((_currentPage + 1) * position.viewportDimension)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      _pageSpringController.value = position.pixels;
      _pageSpringController.animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1, stiffness: 520, damping: 38),
          position.pixels,
          targetPixels,
          0,
        ),
      );
    } else {
      context.go('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.menudo.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.fromLTRB(24, 20, 24, 0)),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) {
                  MenudoHaptics.selection();
                  setState(() => _currentPage = idx);
                },
                children: [
                  _buildPage(
                    title: 'Tu dinero,\nen un solo lugar.',
                    subtitle:
                        'Cuentas, tarjetas y movimientos en un solo lugar.',
                    icon: MenudoCupertinoIcons.account_balance_wallet_rounded,
                  ),
                  _buildPage(
                    title: 'Entiende en qué\nse te va el dinero.',
                    subtitle: 'Mira tus ingresos, gastos y movimientos.',
                    icon: MenudoCupertinoIcons.pie_chart_rounded,
                  ),
                  _buildPage(
                    title: 'Usa presupuestos\nsolo si te ayudan.',
                    subtitle:
                        'Son opcionales. Puedes llevar tus gastos sin armar uno.',
                    icon: MenudoCupertinoIcons.people_alt_rounded,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? context.menudo.primary
                              : context.menudo.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: (24)),
                  MenudoPrimaryButton(
                    label: _currentPage < 2 ? 'Siguiente' : 'Crear cuenta',
                    onTap: _nextPage,
                  ),
                  SizedBox(height: (12)),
                  if (_currentPage == 2)
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.menudo.textSecondary,
                      ),
                      child: Text('Ya tengo cuenta'),
                    )
                  else
                    SizedBox(height: 48), // Spacer to prevent jumps
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 96,
            color: context.menudo.primary.withValues(alpha: 0.15),
          ),
          SizedBox(height: (32)),
          Text(title, style: MenudoTextStyles.h1.copyWith(color: context.menudo.textMain), textAlign: TextAlign.center),
          SizedBox(height: (16)),
          Text(
            subtitle,
            style: MenudoTextStyles.bodyLarge.copyWith(
              color: context.menudo.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
