import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/menudo_text_field.dart';
import '../../../shared/widgets/menudo_button.dart';
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

  void _handleLogin() {
    if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      
      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        ref.read(authProvider.notifier).login('usr_mock_123', 'mock.jwt.token');
        setState(() => _isLoading = false);
        context.go('/');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: MenudoColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            top: 10,
                            bottom: 10,
                            right: -10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: MenudoColors.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().scale(delay: 200.ms, duration: 400.ms),
                
                const SizedBox(height: 32),
                
                Text(
                  'Bienvenido a Menudo',
                  style: MenudoTextStyles.h1,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
                
                const SizedBox(height: 8),
                
                Text(
                  'Inicia sesión para gestionar tu patrimonio',
                  style: MenudoTextStyles.bodyMedium.copyWith(color: MenudoColors.textMuted),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),
                
                const SizedBox(height: 40),
                
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
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: MenudoColors.primary,
                        ),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    MenudoPrimaryButton(
                      label: _isLoading ? 'Cargando...' : 'Iniciar Sesión',
                      onTap: _isLoading ? null : _handleLogin,
                      isDisabled: _isLoading,
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 30),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿No tienes cuenta?', style: MenudoTextStyles.bodyMedium),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      style: TextButton.styleFrom(
                        foregroundColor: MenudoColors.primary,
                      ),
                      child: const Text('Regístrate', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
