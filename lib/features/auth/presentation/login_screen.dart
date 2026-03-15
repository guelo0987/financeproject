import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../shared/widgets/menudo_text_field.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_logo.dart';
import '../auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Completa email y contraseña.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      context.go('/');
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
                'Usa tu correo para continuar.',
                style: MenudoTextStyles.bodyMedium.copyWith(
                  color: MenudoColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MenudoTextField(
                    label: 'Correo electrónico',
                    hint: 'tu@correo.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),
                  MenudoTextField(
                    label: 'Contraseña',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    trailing: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: MenudoColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  MenudoPrimaryButton(
                    label: _isLoading ? 'Cargando...' : 'Iniciar Sesión',
                    onTap: _isLoading ? null : () => _handleLogin(),
                    isDisabled: _isLoading,
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta?',
                    style: MenudoTextStyles.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    style: TextButton.styleFrom(
                      foregroundColor: MenudoColors.primary,
                    ),
                    child: const Text(
                      'Regístrate',
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
