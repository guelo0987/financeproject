import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../shared/widgets/menudo_logo.dart';
import '../auth_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  bool _isLoading = false;
  bool _isDop = true;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _handleBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    context.go('/login');
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .registerWithApple(currency: _isDop ? 'DOP' : 'USD');
      if (!mounted) return;

      final needsPaywall = ref.read(authProvider).needsPaywall;
      context.go(needsPaywall ? '/paywall?fromReg=true' : '/');
    } catch (error) {
      _showError(presentError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MenudoColors.textMain),
          onPressed: _handleBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Center(child: MenudoLogo(size: 112, hero: true)),
              const SizedBox(height: 20),
              Text(
                'Crear cuenta',
                style: MenudoTextStyles.h1,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 8),

              Text(
                'Tu cuenta se crea con Apple y arrancas con la moneda que elijas.',
                style: MenudoTextStyles.bodyMedium.copyWith(
                  color: MenudoColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: MenudoColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Moneda principal',
                      style: MenudoTextStyles.bodyMedium.copyWith(
                        color: MenudoColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _CurrencyOption(
                            currency: 'RD\$',
                            isSelected: _isDop,
                            onTap: () => setState(() => _isDop = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CurrencyOption(
                            currency: 'US\$',
                            isSelected: !_isDop,
                            onTap: () => setState(() => _isDop = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    IgnorePointer(
                      ignoring: _isLoading,
                      child: Opacity(
                        opacity: _isLoading ? 0.7 : 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SignInWithAppleButton(
                            onPressed: _handleRegister,
                            style: SignInWithAppleButtonStyle.black,
                            text: _isLoading
                                ? 'Creando cuenta...'
                                : 'Crear cuenta con Apple',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Apple comparte tu email y tu nombre solo la primera vez.',
                      style: MenudoTextStyles.bodySmall.copyWith(
                        color: MenudoColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿Ya la habías creado?',
                    style: MenudoTextStyles.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: MenudoColors.primary,
                    ),
                    child: const Text(
                      'Entrar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyOption extends StatelessWidget {
  const _CurrencyOption({
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  final String currency;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? MenudoColors.cardBg.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? MenudoColors.cardBg : MenudoColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monetization_on_outlined,
              size: 20,
              color: isSelected
                  ? MenudoColors.cardBg
                  : MenudoColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              currency,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? MenudoColors.cardBg
                    : MenudoColors.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: MenudoColors.cardBg),
            ],
          ],
        ),
      ),
    );
  }
}
