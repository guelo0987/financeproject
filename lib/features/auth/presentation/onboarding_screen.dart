import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/menudo_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildPage(
                    title: 'Todo tu dinero,\nen un solo lugar.',
                    subtitle: 'Cuentas, crypto, inversiones y más.',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  _buildPage(
                    title: 'Entiende en qué\ngastas tu dinero.',
                    subtitle: 'Análisis inteligente con IA incluida.',
                    icon: Icons.pie_chart_rounded,
                  ),
                  _buildPage(
                    title: 'Planifica con\ntu familia o pareja.',
                    subtitle: 'Espacios compartidos en tiempo real.',
                    icon: Icons.people_alt_rounded,
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
                              ? MenudoColors.primary
                              : MenudoColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  MenudoPrimaryButton(
                    label: _currentPage < 2 ? 'Siguiente' : 'Comenzar gratis',
                    onTap: _nextPage,
                  ),
                  const SizedBox(height: 12),
                  if (_currentPage == 2)
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: MenudoColors.textSecondary,
                      ),
                      child: const Text('Ya tengo cuenta — Iniciar sesión'),
                    )
                  else
                    const SizedBox(height: 48), // Spacer to prevent jumps
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
            size: 120,
            color: MenudoColors.cardBg.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 40),
          Text(title, style: MenudoTextStyles.h1, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: MenudoTextStyles.bodyLarge.copyWith(
              color: MenudoColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
