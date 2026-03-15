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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isDop = true;

  @override
  void dispose() {
    _nameController.dispose();
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

  void _handleBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    context.go('/login');
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Completa nombre, email y contraseña.');
      return;
    }
    if (_passwordController.text.length < 8) {
      _showError('La contraseña debe tener al menos 8 caracteres.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            currency: _isDop ? 'DOP' : 'USD',
          );
      if (!mounted) return;
      // Show paywall immediately after registration so payment info is collected
      // before the free trial begins.
      context.go('/paywall?fromReg=true');
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
                'Empieza con tu cuenta personal.',
                style: MenudoTextStyles.bodyMedium.copyWith(
                  color: MenudoColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MenudoTextField(
                    label: 'Nombre completo',
                    hint: 'Carlos Rodríguez',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  const SizedBox(height: 16),
                  MenudoTextField(
                    label: 'Correo electrónico',
                    hint: 'carlos@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),
                  MenudoTextField(
                    label: 'Contraseña',
                    hint: 'Mínimo 8 caracteres',
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

                  const SizedBox(height: 32),
                  MenudoPrimaryButton(
                    label: _isLoading ? 'Procesando...' : 'Crear mi cuenta',
                    onTap: _isLoading ? null : () => _handleRegister(),
                    isDisabled: _isLoading,
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyOption extends StatelessWidget {
  final String currency;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyOption({
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

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
              const Icon(
                Icons.check_circle,
                color: MenudoColors.cardBg,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
