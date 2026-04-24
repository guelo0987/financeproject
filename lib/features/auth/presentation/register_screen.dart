import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_logo.dart';
import '../../../shared/widgets/menudo_tap_target.dart';
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
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _appleAvailable = false;
  bool _showEmailForm = false;

  @override
  void initState() {
    super.initState();
    _loadAppleAvailability();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
        backgroundColor: success ? context.menudo.primary : null,
      ),
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

  String? _validateRegister() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      return 'Completa tu nombre, correo y contraseña.';
    }
    if (!emailPattern.hasMatch(email)) {
      return 'Ese correo no parece válido.';
    }
    if (password.length < 6) {
      return 'Tu contraseña debe tener al menos 6 caracteres.';
    }
    if (password != confirm) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  Future<void> _handleRegisterWithEmail() async {
    final validation = _validateRegister();
    if (validation != null || _isLoading) {
      if (validation != null) _showMessage(validation);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(authProvider.notifier)
          .registerWithEmailPassword(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      if (result.requiresEmailVerification) {
        _showMessage(
          'Te enviamos un correo a ${result.email}. Confírmalo y vuelve a Menudo para entrar con tu contraseña.',
          success: true,
        );
        context.go('/login');
        return;
      }

      final needsPaywall = ref.read(authProvider).needsPaywall;
      context.go(needsPaywall ? '/paywall?fromReg=true' : '/');
    } catch (error) {
      _showMessage(presentError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegisterWithApple() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .registerWithApple(currency: marketFromDeviceLocale().currencyCode);
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
    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: MenudoIconButton(
          icon: Icon(
            MenudoCupertinoIcons.arrow_back,
            color: MenudoColors.textMain,
          ),
          onPressed: _handleBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: MenudoLogo(size: (112), hero: true)),
                SizedBox(height: (20)),
                Text(
                  'Crear cuenta',
                  style: MenudoTextStyles.h1,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms),
                SizedBox(height: 8),
                Text(
                  _appleAvailable
                      ? 'Empieza con Apple o usa tu correo.'
                      : 'Crea tu cuenta con correo y contraseña.',
                  style: MenudoTextStyles.bodyMedium.copyWith(
                    color: MenudoColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 160.ms),
                SizedBox(height: (28)),
                if (_appleAvailable) ...[
                  IgnorePointer(
                    ignoring: _isLoading,
                    child: Opacity(
                      opacity: _isLoading ? 0.7 : 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SignInWithAppleButton(
                          onPressed: _handleRegisterWithApple,
                          style: SignInWithAppleButtonStyle.black,
                          text: 'Crear cuenta con Apple',
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.04),
                  SizedBox(height: (14)),
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
                          ? 'Ocultar registro con correo'
                          : 'Crear cuenta con correo',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ).animate().fadeIn(delay: 260.ms),
                ],
                if (!_appleAvailable || _showEmailForm) ...[
                  SizedBox(height: (18)),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.menudo.textOnDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: MenudoColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_appleAvailable) ...[
                          Text(
                            'O crea tu cuenta con correo',
                            style: MenudoTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: (14)),
                        ],
                        _AuthField(
                          controller: _nameController,
                          label: 'Nombre',
                          hintText: 'Cómo quieres verte en la app',
                          textInputAction: TextInputAction.next,
                          autofillHints: [AutofillHints.name],
                        ),
                        SizedBox(height: (14)),
                        _AuthField(
                          controller: _emailController,
                          label: 'Correo',
                          hintText: 'correo@ejemplo.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: [AutofillHints.email],
                        ),
                        SizedBox(height: (14)),
                        _AuthField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          hintText: 'Mínimo 6 caracteres',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: [AutofillHints.newPassword],
                          suffixIcon: MenudoIconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? MenudoCupertinoIcons.visibility_off_outlined
                                  : MenudoCupertinoIcons.visibility_outlined,
                              color: MenudoColors.textMuted,
                            ),
                          ),
                        ),
                        SizedBox(height: (14)),
                        _AuthField(
                          controller: _confirmController,
                          label: 'Confirmar contraseña',
                          hintText: 'Repite tu contraseña',
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          autofillHints: [AutofillHints.newPassword],
                          suffixIcon: MenudoIconButton(
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                            icon: Icon(
                              _obscureConfirm
                                  ? MenudoCupertinoIcons.visibility_off_outlined
                                  : MenudoCupertinoIcons.visibility_outlined,
                              color: MenudoColors.textMuted,
                            ),
                          ),
                          onSubmitted: (_) => _handleRegisterWithEmail(),
                        ),
                        SizedBox(height: (20)),
                        MenudoPrimaryButton(
                          label: _isLoading
                              ? 'Creando cuenta...'
                              : 'Crear cuenta',
                          onTap: _handleRegisterWithEmail,
                          isDisabled: _isLoading,
                        ),
                        SizedBox(height: (12)),
                        Text(
                          'Luego podrás ajustar moneda, meta y presupuesto predeterminado desde tu perfil.',
                          style: MenudoTextStyles.bodySmall.copyWith(
                            color: MenudoColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),
                ],
                SizedBox(height: (24)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta?',
                      style: MenudoTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: MenudoColors.primary,
                      ),
                      child: Text(
                        'Entrar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),
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
        SizedBox(height: 8),
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
            fillColor: context.menudo.background,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: context.menudo.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: context.menudo.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: AppColors.e6, width: 1.5),
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
