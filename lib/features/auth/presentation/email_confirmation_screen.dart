import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_loading_view.dart';
import '../auth_state.dart';

class EmailConfirmationScreen extends ConsumerStatefulWidget {
  const EmailConfirmationScreen({super.key, this.uri});

  final Uri? uri;

  @override
  ConsumerState<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState
    extends ConsumerState<EmailConfirmationScreen> {
  bool _isVerifying = false;
  String? _errorMessage;

  void _continueAfterConfirmation() {
    if (!mounted) return;
    context.go('/');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifyIfNeeded());
  }

  String? _readParam(String key) {
    final routeUri = widget.uri;
    final routeValue = routeUri?.queryParameters[key];
    if (routeValue != null && routeValue.isNotEmpty) return routeValue;

    final routeFragment = routeUri?.fragment;
    if (routeFragment != null && routeFragment.isNotEmpty) {
      final routeFragmentParams = Uri.splitQueryString(routeFragment);
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

  OtpType? _parseOtpType(String? rawType) {
    switch (rawType?.trim().toLowerCase()) {
      case 'email':
        return OtpType.email;
      case 'recovery':
        return OtpType.recovery;
      default:
        return null;
    }
  }

  Future<void> _verifyIfNeeded() async {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) return;

    final errorDescription = _readParam('error_description');
    final errorCode = _readParam('error_code');
    if (errorDescription != null) {
      setState(() {
        _errorMessage = presentError(
          errorCode == null
              ? errorDescription
              : '$errorCode: $errorDescription',
          fallback:
              'No pudimos confirmar tu correo. Pide un enlace nuevo desde Menudo.',
        );
      });
      return;
    }

    final tokenHash = _readParam('token_hash');
    final type = _parseOtpType(_readParam('type'));
    if (tokenHash == null || type == null) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .verifyOtpTokenHash(tokenHash: tokenHash, type: type);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = presentError(
          error,
          fallback:
              'No pudimos confirmar tu correo. Pide un enlace nuevo desde Menudo.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: context.menudo.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  MenudoCupertinoIcons.verified_rounded,
                  size: 56,
                  color: context.menudo.primary,
                ),
                SizedBox(height: (18)),
                Text(
                  'Tu cuenta ya quedó verificada',
                  style: MenudoTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: (10)),
                Text(
                  'Ya puedes seguir usando Menudo con normalidad.',
                  style: MenudoTextStyles.bodyMedium.copyWith(
                    color: context.menudo.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: (24)),
                MenudoPrimaryButton(
                  label: 'Continuar',
                  onTap: _continueAfterConfirmation,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: context.menudo.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  MenudoCupertinoIcons.mark_email_unread_outlined,
                  size: 52,
                  color: context.menudo.warning,
                ),
                SizedBox(height: (18)),
                Text(
                  'No pudimos confirmar tu correo',
                  style: MenudoTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: (10)),
                Text(
                  _errorMessage!,
                  style: MenudoTextStyles.bodyMedium.copyWith(
                    color: context.menudo.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: (24)),
                MenudoPrimaryButton(
                  label: 'Volver a entrar',
                  onTap: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final message = _isVerifying
        ? 'Estamos confirmando tu correo para abrir tu cuenta.'
        : 'Abre el correo más reciente para confirmar tu cuenta.';

    return Scaffold(
      backgroundColor: context.menudo.background,
      body: SafeArea(
        child: MenudoLoadingView(
          title: 'Confirmando tu correo',
          message: message,
          logoSize: 136,
        ),
      ),
    );
  }
}
