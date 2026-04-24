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
  bool _showEmailForm = false;

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
        setState(() {
          _appleAvailable = available;
          if (!available) {
            _showEmailForm = true;
          }
        });
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

  Future<void> _handleForgotPassword() async {
    final email = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ForgotPasswordSheet(initialEmail: _emailController.text.trim()),
    );

    if (email != null && mounted) {
      _emailController.text = email;
      _showMessage(
        'Te enviamos un enlace para cambiar tu contraseña si esa cuenta existe.',
        success: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final pendingVerificationEmail = authState.pendingVerificationEmail;

    if (pendingVerificationEmail != null &&
        _emailController.text.trim().isEmpty) {
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
                  'Entrar en Menudo',
                  style: MenudoTextStyles.h1,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  _appleAvailable
                      ? 'Continúa con Apple o entra con tu correo.'
                      : 'Entra con tu correo y tu contraseña.',
                  style: MenudoTextStyles.bodyMedium.copyWith(
                    color: MenudoColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 260.ms),
                const SizedBox(height: 28),
                if (_appleAvailable) ...[
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
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.04),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () =>
                              setState(() => _showEmailForm = !_showEmailForm),
                    style: TextButton.styleFrom(
                      foregroundColor: MenudoColors.primary,
                    ),
                    child: Text(
                      _showEmailForm
                          ? 'Ocultar correo y contraseña'
                          : 'Usar correo y contraseña',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ).animate().fadeIn(delay: 340.ms),
                ],
                if (!_appleAvailable || _showEmailForm) ...[
                  const SizedBox(height: 18),
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
                        if (_appleAvailable) ...[
                          Text(
                            'O entra con correo',
                            style: MenudoTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : _handleForgotPassword,
                            style: TextButton.styleFrom(
                              foregroundColor: MenudoColors.primary,
                              padding: const EdgeInsets.only(top: 4),
                            ),
                            child: const Text(
                              'Olvidé mi contraseña',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        MenudoPrimaryButton(
                          label: _isLoading ? 'Entrando...' : 'Entrar',
                          onTap: _handleEmailLogin,
                          isDisabled: _isLoading,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.08),
                ],
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
    this.autofocus = false,
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
  final bool autofocus;

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
          autofocus: autofocus,
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

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet({required this.initialEmail});

  final String initialEmail;

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  late final TextEditingController _emailController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSending) return;
    final email = _emailController.text.trim().toLowerCase();
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un correo válido.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref.read(authProvider.notifier).requestPasswordReset(email);
      if (!mounted) return;
      Navigator.of(context).pop(email);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(presentError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeBottom = media.padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        constraints: BoxConstraints(maxHeight: media.size.height * 0.52),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + safeBottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.g2,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Recuperar contraseña', style: MenudoTextStyles.h3),
              const SizedBox(height: 6),
              Text(
                'Escribe tu correo y te mandamos el acceso para cambiar tu contraseña.',
                style: MenudoTextStyles.bodySmall.copyWith(
                  color: MenudoColors.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              _AuthField(
                controller: _emailController,
                label: 'Correo',
                hintText: 'correo@ejemplo.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofocus: true,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 18),
              MenudoPrimaryButton(
                label: _isSending ? 'Enviando...' : 'Continuar',
                onTap: _submit,
                isDisabled: _isSending,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
