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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _handleAppleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).loginWithApple();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: const MenudoLogo(size: 120, hero: true),
              ).animate().scale(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 24),

              Text(
                'Entrar',
                style: MenudoTextStyles.h1,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 8),

              Text(
                'Tu acceso ahora se maneja con tu Apple ID.',
                style: MenudoTextStyles.bodyMedium.copyWith(
                  color: MenudoColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),

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
                      'Usa Sign in with Apple para entrar o recuperar tu cuenta.',
                      style: MenudoTextStyles.bodyMedium.copyWith(
                        color: MenudoColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    IgnorePointer(
                      ignoring: _isLoading,
                      child: Opacity(
                        opacity: _isLoading ? 0.7 : 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SignInWithAppleButton(
                            onPressed: _handleAppleLogin,
                            style: SignInWithAppleButtonStyle.black,
                            text: _isLoading
                                ? 'Conectando...'
                                : 'Continuar con Apple',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Disponible en iPhone, iPad y Mac con Apple ID.',
                      style: MenudoTextStyles.bodySmall.copyWith(
                        color: MenudoColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿Primera vez?', style: MenudoTextStyles.bodyMedium),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    style: TextButton.styleFrom(
                      foregroundColor: MenudoColors.primary,
                    ),
                    child: const Text(
                      'Configura tu cuenta',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
