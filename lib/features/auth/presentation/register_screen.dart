import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/menudo_text_field.dart';
import '../../../shared/widgets/menudo_button.dart';
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

  void _handleRegister() {
    setState(() => _isLoading = true);
    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ref.read(authProvider.notifier).login('usr_mock_new', 'mock.jwt.token');
      context.go('/');
      setState(() => _isLoading = false);
    });
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
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                'Crear cuenta',
                style: MenudoTextStyles.h1,
              ).animate().fadeIn(delay: 100.ms),
              
              const SizedBox(height: 8),
              
              Text(
                '5 días gratis, luego \$5 USD/mes',
                style: MenudoTextStyles.bodyMedium.copyWith(color: MenudoColors.success),
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
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                  
                  Text('Moneda principal', style: MenudoTextStyles.bodyMedium.copyWith(color: MenudoColors.textMuted)),
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
                    onTap: _isLoading ? null : _handleRegister,
                    isDisabled: _isLoading,
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider(color: MenudoColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('o continúa con', style: MenudoTextStyles.bodySmall.copyWith(color: MenudoColors.textMuted)),
                  ),
                  const Expanded(child: Divider(color: MenudoColors.divider)),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: MenudoColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.apple, size: 24),
                label: const Text('Continuar con Apple', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
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
          color: isSelected ? MenudoColors.cardBg.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? MenudoColors.cardBg : MenudoColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monetization_on_outlined, size: 20, color: isSelected ? MenudoColors.cardBg : MenudoColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              currency,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? MenudoColors.cardBg : MenudoColors.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: MenudoColors.cardBg, size: 16),
            ]
          ],
        ),
      ),
    );
  }
}
