import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_loading_view.dart';
import '../auth_state.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  Timer? _recoveryFallbackTimer;
  bool _isSaving = false;
  bool _isResending = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _showRecoveryHelp = false;
  bool _isVerifyingLink = false;
  String? _linkErrorMessage;

  @override
  void initState() {
    super.initState();
    _startRecoveryFallbackTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifyRecoveryLink());
  }

  @override
  void dispose() {
    _recoveryFallbackTimer?.cancel();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _startRecoveryFallbackTimer() {
    _recoveryFallbackTimer?.cancel();
    _recoveryFallbackTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showRecoveryHelp = true);
    });
  }

  String? _readParam(String key) {
    final routeUri = GoRouterState.of(context).uri;
    final routeValue = routeUri.queryParameters[key];
    if (routeValue != null && routeValue.isNotEmpty) return routeValue;

    if (routeUri.fragment.isNotEmpty) {
      final routeFragmentParams = Uri.splitQueryString(routeUri.fragment);
      final routeFragmentValue = routeFragmentParams[key];
      if (routeFragmentValue != null && routeFragmentValue.isNotEmpty) {
        return routeFragmentValue;
      }
    }

    final baseUri = Uri.base;
    final baseValue = baseUri.queryParameters[key];
    if (baseValue != null && baseValue.isNotEmpty) return baseValue;

    if (baseUri.fragment.isNotEmpty) {
      final baseFragmentParams = Uri.splitQueryString(baseUri.fragment);
      final fragmentValue = baseFragmentParams[key];
      if (fragmentValue != null && fragmentValue.isNotEmpty) {
        return fragmentValue;
      }
    }

    return null;
  }

  Future<void> _verifyRecoveryLink() async {
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.requiresPasswordReset) return;

    final errorDescription = _readParam('error_description');
    final errorCode = _readParam('error_code');
    if (errorDescription != null) {
      setState(() {
        _linkErrorMessage = presentError(
          errorCode == null
              ? errorDescription
              : '$errorCode: $errorDescription',
          fallback:
              'No pudimos abrir tu cambio de contraseña. Pide un enlace nuevo.',
        );
      });
      return;
    }

    final tokenHash = _readParam('token_hash');
    final rawType = _readParam('type')?.trim().toLowerCase();
    if (tokenHash == null || rawType != 'recovery') {
      return;
    }

    setState(() {
      _isVerifyingLink = true;
      _linkErrorMessage = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .verifyOtpTokenHash(tokenHash: tokenHash, type: OtpType.recovery);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _linkErrorMessage = presentError(
          error,
          fallback:
              'No pudimos abrir tu cambio de contraseña. Pide un enlace nuevo.',
        );
      });
    } finally {
      if (mounted) setState(() => _isVerifyingLink = false);
    }
  }

  Future<void> _resendRecoveryLink(String email) async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      await ref.read(authProvider.notifier).requestPasswordReset(email);
      _showMessage('Te enviamos otro correo para continuar el cambio.');
    } catch (error) {
      _showMessage(presentError(error));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      _showMessage('Escribe y confirma tu nueva contraseña.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Usa una contraseña de al menos 6 caracteres.');
      return;
    }
    if (password != confirm) {
      _showMessage('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).completePasswordRecovery(password);
    } catch (error) {
      _showMessage(presentError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final resetEmail = authState.pendingPasswordResetEmail;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    if (authState.requiresPasswordReset) {
      _recoveryFallbackTimer?.cancel();
      if (_showRecoveryHelp) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _showRecoveryHelp = false);
        });
      }
    }

    if (!authState.requiresPasswordReset) {
      final inactiveMessage = _linkErrorMessage;
      return Scaffold(
        backgroundColor: MenudoColors.appBg,
        body: SafeArea(
          child: inactiveMessage != null
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.lock_reset_rounded,
                        size: 52,
                        color: MenudoColors.warning,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'No pudimos abrir tu cambio de contraseña',
                        style: MenudoTextStyles.h2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        inactiveMessage,
                        style: MenudoTextStyles.bodyMedium.copyWith(
                          color: MenudoColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      MenudoSecondaryButton(
                        label: 'Volver a iniciar sesión',
                        onTap: () => context.go('/login'),
                      ),
                    ],
                  ),
                )
              : _showRecoveryHelp
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'No pudimos abrir tu cambio de contraseña',
                        style: MenudoTextStyles.h2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        resetEmail == null
                            ? 'Abre el correo más reciente. Si ya venció, pide otro sin empezar de cero.'
                            : 'Estamos esperando validar el correo para $resetEmail. Si no pasa nada, pide otro desde aquí.',
                        style: MenudoTextStyles.bodyMedium.copyWith(
                          color: MenudoColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
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
                              'Qué hacer ahora',
                              style: MenudoTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '1. Usa el correo más reciente.\n2. Si ya venció, pide otro.\n3. Cuando sea válido, Menudo te traerá aquí.',
                              style: MenudoTextStyles.bodySmall.copyWith(
                                color: MenudoColors.textMuted,
                                height: 1.45,
                              ),
                            ),
                            if (resetEmail != null) ...[
                              const SizedBox(height: 18),
                              MenudoPrimaryButton(
                                label: _isResending
                                    ? 'Enviando correo...'
                                    : 'Pedir otro correo',
                                onTap: () => _resendRecoveryLink(resetEmail),
                                isDisabled: _isResending,
                              ),
                            ],
                            const SizedBox(height: 12),
                            MenudoSecondaryButton(
                              label: 'Volver a iniciar sesión',
                              onTap: () => context.go('/login'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : MenudoLoadingView(
                  title: 'Preparando tu cambio de contraseña',
                  message: _isVerifyingLink
                      ? 'Estamos validando tu enlace para dejarte cambiar la contraseña.'
                      : 'Abre el correo más reciente para continuar.',
                ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 28 + keyboardInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crear nueva contraseña',
                style: MenudoTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                resetEmail == null
                    ? 'Elige una contraseña nueva para recuperar tu cuenta.'
                    : 'Elige una contraseña nueva para $resetEmail.',
                style: MenudoTextStyles.bodyMedium.copyWith(
                  color: MenudoColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
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
                    _ResetField(
                      controller: _passwordController,
                      label: 'Nueva contraseña',
                      hintText: 'Mínimo 6 caracteres',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
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
                    ),
                    const SizedBox(height: 14),
                    _ResetField(
                      controller: _confirmController,
                      label: 'Confirmar contraseña',
                      hintText: 'Vuelve a escribirla',
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: MenudoColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    MenudoPrimaryButton(
                      label: _isSaving
                          ? 'Guardando contraseña...'
                          : 'Guardar contraseña',
                      onTap: _submit,
                      isDisabled: _isSaving,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetField extends StatelessWidget {
  const _ResetField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

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
          obscureText: obscureText,
          textInputAction: textInputAction,
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
