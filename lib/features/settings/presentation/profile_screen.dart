import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_copy.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/preferences/app_preferences_controller.dart';
import '../../../core/theme/app_colors.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/display_utils.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../core/utils/formatters.dart';
import '../../../model/user_profile.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_chip.dart';
import '../../../shared/widgets/menudo_loading_view.dart';
import '../../auth/auth_state.dart';
import '../../subscription/subscription_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _goalOptions = <String>[
    'Ahorrar',
    'Reducir deudas',
    'Gastar mejor',
    'Invertir',
    'Otro',
  ];
  static const _avatarSuggestions = <String>[
    '🙂',
    '😎',
    '🧠',
    '🚀',
    '🌿',
    '💸',
    '📈',
    '🪴',
    '✨',
    '🔥',
    '🍊',
    '🫶',
    '😄',
    '🤍',
    '🎯',
    '🦋',
    '🌞',
    '🍀',
    '💼',
    '📚',
    '🪙',
    '🏦',
    '🧡',
    '🌴',
    '🥭',
    '☀️',
    '🫱🏻‍🫲🏽',
    '💰',
  ];

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _avatarEmojiController = TextEditingController();

  String _currency = AppFormattingPreferences.currencyCode;
  String? _financialGoal;
  DateTime? _goalDate;
  bool _isSaving = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _avatarEmojiController.dispose();
    super.dispose();
  }

  void _hydrateFromProfile() {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;
    _nameController.text = profile.name;
    _currency = profile.baseCurrency;
    _financialGoal = profile.financialGoal;
    _goalDate = profile.goalDate;
    _avatarEmojiController.text = profile.avatarEmoji ?? '';
    _amountController.text = _formatMoney(profile.goalAmount);
    if (mounted) setState(() {});
  }

  String? _normalizeEmoji(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.characters.first;
  }

  String _formatMoney(double? value) {
    if (value == null || value <= 0) return '';
    final raw = value.round().toString();
    return raw.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  double? _parseMoney() {
    final raw = _amountController.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  void _onAmountChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = digits.isEmpty
        ? ''
        : digits.replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]},',
          );
    if (_amountController.text == formatted) return;
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return tr(context, es: 'Elegir fecha', en: 'Choose date');
    }
    return formatDateByPattern(value);
  }

  String _formatJoined(UserProfile profile) {
    if (profile.createdAt == null) {
      return tr(context, es: 'Tu cuenta', en: 'Your account');
    }
    final dateLabel = formatDateByPattern(
      profile.createdAt!,
      pattern: 'MMM yyyy',
    );
    return tr(context, es: 'Desde $dateLabel', en: 'Since $dateLabel');
  }

  Future<void> _pickGoalDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _goalDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      builder: (dialogContext, child) {
        final baseTheme = Theme.of(dialogContext);
        final palette = dialogContext.menudo;
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: palette.primary,
              secondary: palette.primary,
              onPrimary: palette.textOnDark,
              surface: palette.surface,
              onSurface: palette.textMain,
            ),
            dialogTheme: DialogThemeData(backgroundColor: palette.surface),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      setState(() => _goalDate = selected);
    }
  }

  Future<void> _pickAvatarEmoji() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarEmojiSheet(
        initialEmoji: _normalizeEmoji(_avatarEmojiController.text),
        suggestions: _avatarSuggestions,
      ),
    );

    if (result == null || !mounted) return;
    setState(() => _avatarEmojiController.text = result);
  }

  Future<void> _openChangePasswordSheet() async {
    if (ref.read(authProvider).isAppleAccount) {
      _showMessage('Tu cuenta usa Apple.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _openDeleteAccountSheet({
    required String email,
    required bool hasActiveSubscription,
  }) async {
    if (_isDeletingAccount) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteAccountSheet(
        email: email,
        hasActiveSubscription: hasActiveSubscription,
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (!mounted) return;
      context.go('/login');
    } catch (error) {
      _showMessage(presentError(error));
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  Future<void> _saveProfile() async {
    final profile = ref.read(authProvider).profile;
    if (profile == null || _isSaving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Escribe tu nombre.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(authProvider.notifier)
          .updateProfile(
            name: name,
            currency: _currency,
            avatarEmoji: _normalizeEmoji(_avatarEmojiController.text),
            financialGoal: _financialGoal?.trim().isEmpty == true
                ? null
                : _financialGoal,
            goalAmount: _parseMoney(),
            goalDate: _goalDate,
          );
      await ref
          .read(appPreferencesProvider.notifier)
          .setMarket(marketFromCurrency(_currency).code);
      if (!mounted) return;
      MenudoHaptics.success();
    } catch (error) {
      _showMessage(presentError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final subscription = ref.watch(subscriptionProvider);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    if (profile == null) {
      return Scaffold(
        backgroundColor: context.menudo.background,
        body: SafeArea(
          child: MenudoLoadingView(
            title: 'Cargando tu perfil',
            message: 'Estamos trayendo tus datos personales.',
          ),
        ),
      );
    }

    final displayName = shortDisplayName(profile.name);
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final avatarEmoji =
        _normalizeEmoji(_avatarEmojiController.text) ?? profile.avatarEmoji;
    final avatarDisplay = avatarEmoji?.isNotEmpty == true
        ? avatarEmoji!
        : (initials.isEmpty ? 'M' : initials);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.menudo.background,
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    _CircleActionButton(
                      icon: MenudoCupertinoIcons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop(),
                    ),
                    SizedBox(width: (14)),
                    Text('Mi perfil', style: MenudoTextStyles.h1),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: context.menudo.hero,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: context.menudo.surface.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: avatarEmoji?.isNotEmpty == true
                            ? Text(
                                avatarDisplay,
                                style: TextStyle(fontSize: 34),
                              )
                            : Text(
                                avatarDisplay,
                                style: MenudoTextStyles.h2.copyWith(
                                  color: context.menudo.textOnDark,
                                ),
                              ),
                      ),
                      SizedBox(width: (16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: MenudoTextStyles.h3.copyWith(
                                color: context.menudo.textOnDark,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              profile.email,
                              style: MenudoTextStyles.bodyMedium.copyWith(
                                color: context.menudo.textOnDarkSub,
                              ),
                            ),
                            SizedBox(height: (10)),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                MenudoChip.custom(
                                  label: _formatJoined(profile),
                                  color: context.menudo.textOnDark,
                                  bgColor: context.menudo.surface.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _SectionTitle('Datos'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: MenudoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Avatar'),
                      SizedBox(height: 8),
                      _ReadOnlyField(
                        value: avatarEmoji?.isNotEmpty == true
                            ? 'Avatar $avatarEmoji'
                            : 'Elegir emoji o usar iniciales',
                        onTap: _pickAvatarEmoji,
                        trailing: Container(
                          width: (36),
                          height: (36),
                          decoration: BoxDecoration(
                            color: context.menudo.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: avatarEmoji?.isNotEmpty == true
                              ? Text(
                                  avatarEmoji!,
                                  style: TextStyle(fontSize: 20),
                                )
                              : Text(
                                  avatarDisplay,
                                  style: MenudoTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: (16)),
                      _FieldLabel('Nombre'),
                      SizedBox(height: 8),
                      _PlainTextField(
                        controller: _nameController,
                        hintText: 'Tu nombre',
                        textCapitalization: TextCapitalization.words,
                      ),
                      SizedBox(height: (16)),
                      _FieldLabel('Correo'),
                      SizedBox(height: 8),
                      _ReadOnlyField(value: profile.email),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _SectionTitle('Meta'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: MenudoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Elige en qué quieres enfocarte.',
                        style: MenudoTextStyles.bodySmall.copyWith(
                          color: context.menudo.textMuted,
                        ),
                      ),
                      SizedBox(height: (12)),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - 8) / 2;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _goalOptions
                                .map(
                                  (option) => SizedBox(
                                    width: itemWidth,
                                    child: _ChoiceTag(
                                      label: option,
                                      selected: _financialGoal == option,
                                      onTap: () => setState(() {
                                        _financialGoal =
                                            _financialGoal == option
                                            ? null
                                            : option;
                                      }),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                      SizedBox(height: (16)),
                      _FieldLabel('Monto objetivo'),
                      SizedBox(height: 8),
                      _PlainTextField(
                        controller: _amountController,
                        hintText: '',
                        keyboardType: TextInputType.number,
                        onChanged: _onAmountChanged,
                        prefixText: '${currencyPrefix(_currency)} ',
                      ),
                      SizedBox(height: (16)),
                      _FieldLabel('Fecha objetivo'),
                      SizedBox(height: 8),
                      _ReadOnlyField(
                        value: _formatDate(_goalDate),
                        onTap: _pickGoalDate,
                        trailing: _goalDate == null
                            ? null
                            : MenudoIconButton(
                                onPressed: () =>
                                    setState(() => _goalDate = null),
                                icon: Icon(
                                  MenudoCupertinoIcons.close_rounded,
                                  size: (18),
                                  color: context.menudo.textMuted,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!authState.isAppleAccount) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _SectionTitle('Seguridad'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: MenudoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Si usas correo y contraseña, aquí puedes actualizarla sin salir de la app.',
                          style: MenudoTextStyles.bodySmall.copyWith(
                            color: context.menudo.textMuted,
                          ),
                        ),
                        SizedBox(height: (16)),
                        MenudoSecondaryButton(
                          label: 'Cambiar contraseña',
                          onTap: _openChangePasswordSheet,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _SectionTitle('Cuenta'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: MenudoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Si decides cerrar tu cuenta, borraremos tu acceso y tus datos personales de Menudo. Este paso no se puede deshacer.',
                        style: MenudoTextStyles.bodySmall.copyWith(
                          color: context.menudo.textMuted,
                          height: 1.35,
                        ),
                      ),

                      SizedBox(height: (16)),
                      MenudoSecondaryButton(
                        label: _isDeletingAccount
                            ? 'Eliminando cuenta...'
                            : 'Eliminar cuenta',
                        onTap: () => _openDeleteAccountSheet(
                          email: profile.email,
                          hasActiveSubscription: subscription.isActive,
                        ),
                        isDisabled: _isDeletingAccount,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: MenudoButton(
                  label: _isSaving ? 'Guardando perfil...' : 'Guardar perfil',
                  isFullWidth: true,
                  isDisabled: _isSaving,
                  onTap: _saveProfile,
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: keyboardInset + 24)),
          ],
        ),
      ),
    );
  }
}

class _AvatarEmojiSheet extends StatefulWidget {
  const _AvatarEmojiSheet({
    required this.initialEmoji,
    required this.suggestions,
  });

  final String? initialEmoji;
  final List<String> suggestions;

  @override
  State<_AvatarEmojiSheet> createState() => _AvatarEmojiSheetState();
}

class _AvatarEmojiSheetState extends State<_AvatarEmojiSheet> {
  late final TextEditingController _controller;
  String? _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.initialEmoji;
    _controller = TextEditingController(text: widget.initialEmoji ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _normalizeEmoji(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeBottom = media.padding.bottom;
    final preview = _normalizeEmoji(_controller.text) ?? _selectedEmoji;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: context.menudo.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        constraints: BoxConstraints(maxHeight: media.size.height * 0.84),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + safeBottom),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.menudo.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              SizedBox(height: (18)),
              Text('Tu avatar', style: MenudoTextStyles.h3),
              SizedBox(height: 6),
              Text(
                'Elige uno rápido o escribe otro. Si tu teclado no muestra emojis, usa estas opciones.',
                style: MenudoTextStyles.bodySmall.copyWith(
                  color: context.menudo.textMuted,
                ),
              ),
              SizedBox(height: (18)),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: context.menudo.successLight,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    preview ?? 'M',
                    style: TextStyle(
                      fontSize: preview == null ? 26 : 40,
                      fontWeight: preview == null ? FontWeight.w900 : null,
                      color: preview == null ? context.menudo.primary : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: (18)),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.suggestions.map((emoji) {
                  final isSelected = emoji == preview;
                  return MenudoGestureDetector(
                    onTap: () {
                      MenudoHaptics.selection();
                      setState(() {
                        _selectedEmoji = emoji;
                        _controller.text = emoji;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.menudo.successLight
                            : context.menudo.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? context.menudo.primary
                              : context.menudo.border,
                          width: isSelected ? 1.6 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: (18)),
              _FieldLabel('Emoji personalizado'),
              SizedBox(height: 8),
              _PlainTextField(
                controller: _controller,
                hintText: '🙂',
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                autofocus: true,
                onChanged: (value) {
                  setState(() => _selectedEmoji = _normalizeEmoji(value));
                },
              ),
              SizedBox(height: (18)),
              Row(
                children: [
                  Expanded(
                    child: MenudoSecondaryButton(
                      label: 'Quitar',
                      onTap: () => Navigator.of(context).pop(''),
                    ),
                  ),
                  SizedBox(width: (12)),
                  Expanded(
                    child: MenudoButton(
                      label: 'Guardar',
                      isFullWidth: true,
                      onTap: () => Navigator.of(context).pop(
                        _normalizeEmoji(_controller.text) ?? _selectedEmoji,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet({
    required this.email,
    required this.hasActiveSubscription,
  });

  final String email;
  final bool hasActiveSubscription;

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final confirmed =
        _confirmationController.text.trim().toUpperCase() == 'ELIMINAR';

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: context.menudo.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + safeBottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.menudo.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              SizedBox(height: (18)),
              Text('Eliminar cuenta', style: MenudoTextStyles.h3),
              SizedBox(height: 8),
              Text(
                'Este paso borra tu acceso a Menudo y no se puede deshacer.',
                style: MenudoTextStyles.bodySmall.copyWith(
                  color: context.menudo.textMuted,
                  height: 1.35,
                ),
              ),
              SizedBox(height: (18)),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.menudo.primaryLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.o5.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Se eliminará',
                      style: MenudoTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cuenta: ${widget.email}\nPerfil y preferencias guardadas\nDatos personales asociados a tu acceso',
                      style: MenudoTextStyles.bodySmall.copyWith(
                        color: context.menudo.textMuted,
                        height: 1.45,
                      ),
                    ),
                    if (widget.hasActiveSubscription) ...[
                      SizedBox(height: (12)),
                      Text(
                        'Tu suscripción de Apple no se cancela sola. Si quieres evitar cargos futuros, cancélala primero desde la gestión de suscripciones.',
                        style: MenudoTextStyles.bodySmall.copyWith(
                          color: AppColors.a5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: (18)),
              _FieldLabel('Escribe ELIMINAR para confirmar'),
              SizedBox(height: 8),
              _PlainTextField(
                controller: _confirmationController,
                hintText: 'ELIMINAR',
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: (18)),
              Row(
                children: [
                  Expanded(
                    child: MenudoSecondaryButton(
                      label: 'Cancelar',
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  SizedBox(width: (12)),
                  Expanded(
                    child: MenudoButton(
                      label: 'Borrar cuenta',
                      isFullWidth: true,
                      isDisabled: !confirmed,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: MenudoTextStyles.labelCaps.copyWith(
          color: context.menudo.textMuted,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: MenudoTextStyles.labelCaps);
  }
}

class _ChoiceTag extends StatelessWidget {
  const _ChoiceTag({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: () {
        MenudoHaptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? context.menudo.primaryLight
              : context.menudo.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.o5 : context.menudo.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: MenudoTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.o5 : context.menudo.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (selected)
              Text(
                '✓',
                style: MenudoTextStyles.bodySmall.copyWith(
                  color: AppColors.o5,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value, this.onTap, this.trailing});

  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing;
    return MenudoGestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: context.menudo.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.menudo.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: MenudoTextStyles.bodyLarge.copyWith(
                  color: context.menudo.textMain,
                ),
              ),
            ),
            ...?(trailingWidget == null ? null : [trailingWidget]),
            if (onTap != null && trailing == null)
              Icon(
                MenudoCupertinoIcons.chevron_right_rounded,
                color: context.menudo.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlainTextField extends StatelessWidget {
  const _PlainTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.prefixText,
    this.textInputAction,
    this.autofocus = false,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final String? prefixText;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: MenudoTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        suffixIcon: suffixIcon,
        hintStyle: MenudoTextStyles.bodyLarge.copyWith(
          color: context.menudo.textMuted,
        ),
        filled: true,
        fillColor: context.menudo.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.menudo.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.menudo.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.menudo.borderActive, width: 2),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.menudo.surface,
          shape: BoxShape.circle,
          border: Border.all(color: context.menudo.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: (18), color: context.menudo.textMain),
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _currentController = TextEditingController();
  final _nextController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _nextController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final currentPassword = _currentController.text;
    final newPassword = _nextController.text;
    final confirmPassword = _confirmController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Completa los tres campos.');
      return;
    }
    if (newPassword.length < 6) {
      _showMessage('Usa una contraseña nueva de al menos 6 caracteres.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage('La nueva contraseña y la confirmación no coinciden.');
      return;
    }
    if (currentPassword == newPassword) {
      _showMessage('La nueva contraseña debe ser distinta a la actual.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      MenudoHaptics.success();
    } catch (error) {
      _showMessage(presentError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
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
                color: context.menudo.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          SizedBox(height: (18)),
          Text('Cambiar contraseña', style: MenudoTextStyles.h3),
          SizedBox(height: 6),
          Text(
            'Usa tu contraseña actual y define una nueva.',
            style: MenudoTextStyles.bodySmall.copyWith(
              color: context.menudo.textMuted,
            ),
          ),
          SizedBox(height: (18)),
          _PlainTextField(
            controller: _currentController,
            hintText: 'Contraseña actual',
            textInputAction: TextInputAction.next,
            obscureText: _obscureCurrent,
            suffixIcon: MenudoIconButton(
              onPressed: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
              icon: Icon(
                _obscureCurrent
                    ? MenudoCupertinoIcons.visibility_off_outlined
                    : MenudoCupertinoIcons.visibility_outlined,
                color: context.menudo.textMuted,
              ),
            ),
          ),
          SizedBox(height: (12)),
          _PlainTextField(
            controller: _nextController,
            hintText: 'Nueva contraseña',
            textInputAction: TextInputAction.next,
            obscureText: _obscureNext,
            suffixIcon: MenudoIconButton(
              onPressed: () => setState(() => _obscureNext = !_obscureNext),
              icon: Icon(
                _obscureNext
                    ? MenudoCupertinoIcons.visibility_off_outlined
                    : MenudoCupertinoIcons.visibility_outlined,
                color: context.menudo.textMuted,
              ),
            ),
          ),
          SizedBox(height: (12)),
          _PlainTextField(
            controller: _confirmController,
            hintText: 'Confirmar nueva contraseña',
            textInputAction: TextInputAction.done,
            obscureText: _obscureConfirm,
            onSubmitted: (_) => _submit(),
            suffixIcon: MenudoIconButton(
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              icon: Icon(
                _obscureConfirm
                    ? MenudoCupertinoIcons.visibility_off_outlined
                    : MenudoCupertinoIcons.visibility_outlined,
                color: context.menudo.textMuted,
              ),
            ),
          ),
          SizedBox(height: (18)),
          MenudoButton(
            label: _isSaving ? 'Guardando...' : 'Guardar contraseña',
            isFullWidth: true,
            isDisabled: _isSaving,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}
