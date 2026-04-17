import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_presenter.dart';
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

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _appleAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadAppleAvailability();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAppleAvailability() async {
    try {
      final available = await SignInWithApple.isAvailable();
      if (mounted) {
        setState(() => _appleAvailable = available);
      }
    } catch (_) {}
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? AppColors.e8 : null,
      ),
    );
  }

  String? _validateEmailLogin() {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty || password.isEmpty) {
      return 'Escribe tu correo y tu contraseña.';
    }
    if (!emailPattern.hasMatch(email)) {
      return 'Ese correo no parece válido.';
    }
    return null;
  }

  Future<void> _handleEmailLogin() async {
    final validation = _validateEmailLogin();
    if (validation != null || _isLoading) {
      if (validation != null) _showMessage(validation);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .loginWithEmailPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;

      final needsPaywall = ref.read(authProvider).needsPaywall;
      context.go(needsPaywall ? '/paywall?fromReg=true' : '/');
    } catch (error) {
      _showMessage(presentError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      _showMessage(presentError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final pendingVerificationEmail = authState.pendingVerificationEmail;

    if (pendingVerificationEmail != null && _emailController.text.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _emailController.text.trim().isNotEmpty) return;
        _emailController.text = pendingVerificationEmail;
      });
    }

    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: MenudoLogo(size: 120, hero: true),
                ).animate().scale(delay: 120.ms, duration: 360.ms),
                const SizedBox(height: 24),
                Text(
                  'Entrar',
                  style: MenudoTextStyles.h1,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  _appleAvailable
                      ? 'Usa tu correo y contraseña. Si prefieres, también puedes entrar con Apple.'
                      : 'Usa tu correo y contraseña para entrar en tu cuenta.',
                  style: MenudoTextStyles.bodyMedium.copyWith(
                    color: MenudoColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 260.ms),
                if (pendingVerificationEmail != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MenudoColors.warningLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: MenudoColors.warning),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            color: MenudoColors.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tu cuenta $pendingVerificationEmail todavía no ha sido verificada. Revisa tu correo, confirma el enlace y luego entra con tu contraseña.',
                            style: MenudoTextStyles.bodyMedium.copyWith(
                              color: MenudoColors.textMain,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.04),
                ],
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
                      _AuthField(
                        controller: _emailController,
                        label: 'Correo',
                        hintText: 'correo@ejemplo.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        hintText: 'Tu contraseña',
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: MenudoColors.textMuted,
                          ),
                        ),
                        onSubmitted: (_) => _handleEmailLogin(),
                      ),
                      const SizedBox(height: 20),
                      MenudoPrimaryButton(
                        label: _isLoading ? 'Entrando...' : 'Entrar',
                        onTap: _handleEmailLogin,
                        isDisabled: _isLoading,
                      ),
                      if (_appleAvailable) ...[
                        const SizedBox(height: 18),
                        const _AuthDivider(label: 'o'),
                        const SizedBox(height: 18),
                        IgnorePointer(
                          ignoring: _isLoading,
                          child: Opacity(
                            opacity: _isLoading ? 0.7 : 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SignInWithAppleButton(
                                onPressed: _handleAppleLogin,
                                style: SignInWithAppleButtonStyle.black,
                                text: 'Continuar con Apple',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.08),
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
                        'Crear cuenta',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 380.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autofillHints,
    this.suffixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: MenudoTextStyles.bodySmall.copyWith(
            color: MenudoColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          style: MenudoTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: MenudoTextStyles.bodyMedium.copyWith(
              color: MenudoColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.g0,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.g2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.g2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.e6, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.g2, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: MenudoTextStyles.bodySmall.copyWith(
              color: MenudoColors.textMuted,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.g2, height: 1)),
      ],
    );
  }
}
