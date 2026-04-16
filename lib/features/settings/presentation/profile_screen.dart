import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../model/user_profile.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_chip.dart';
import '../../../shared/widgets/menudo_loading_view.dart';
import '../../budgets/budget_providers.dart';
import '../../auth/auth_state.dart';

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
  ];

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _avatarEmojiController = TextEditingController();

  String _currency = 'DOP';
  String? _financialGoal;
  DateTime? _goalDate;
  bool _isSaving = false;

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
    if (value == null) return 'Elegir fecha';
    return DateFormat('d MMM yyyy', 'es').format(value);
  }

  String _formatJoined(UserProfile profile) {
    if (profile.createdAt == null) return 'Tu cuenta';
    return 'Desde ${DateFormat('MMM yyyy', 'es').format(profile.createdAt!)}';
  }

  String _budgetLabel(
    UserProfile profile,
    List<MenudoBudget> budgets, {
    required bool isLoading,
  }) {
    if (isLoading && budgets.isEmpty) {
      return 'Cargando opciones...';
    }
    for (final budget in budgets) {
      if (budget.id == profile.defaultBudgetId) {
        return budget.nombre;
      }
    }
    return budgets.isEmpty
        ? 'No tienes presupuestos todavía'
        : 'Elegir uno opcional';
  }

  Future<void> _pickDefaultBudget(UserProfile profile) async {
    final budgets = ref.read(effectiveBudgetsProvider);
    final budgetsState = ref.read(budgetNotifierProvider);
    if (budgetsState.isLoading && budgets.isEmpty) {
      _showMessage('Todavía estamos cargando tus opciones.');
      return;
    }
    if (budgets.isEmpty) {
      _showMessage(
        'Si luego creas un presupuesto, podrás dejar uno fijo aquí.',
      );
      return;
    }

    final result = await showModalBottomSheet<_DefaultBudgetSelection>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DefaultBudgetSheet(
        budgets: budgets,
        selectedBudgetId: profile.defaultBudgetId,
      ),
    );

    if (result == null) return;

    try {
      await ref.read(authProvider.notifier).setDefaultBudget(result.budgetId);
      if (result.budgetId != null) {
        ref
            .read(budgetControllerProvider.notifier)
            .selectBudgetLocally(result.budgetId!);
      }
      if (!mounted) return;
      _showMessage(
        result.budgetId == null
            ? 'La app ya no abrirá con un presupuesto fijo.'
            : 'Tu preferencia de presupuesto inicial ya quedó actualizada.',
      );
    } catch (error) {
      _showMessage(presentError(error));
    }
  }

  Future<void> _pickGoalDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _goalDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.e8,
              secondary: AppColors.o5,
              surface: Colors.white,
            ),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listo. Guardamos los cambios de tu perfil.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final profile = ref.watch(authProvider).profile;
    final budgetsState = ref.watch(budgetNotifierProvider);
    final budgets = ref.watch(effectiveBudgetsProvider);

    if (profile == null) {
      return const Scaffold(
        backgroundColor: MenudoColors.appBg,
        body: SafeArea(
          child: MenudoLoadingView(
            title: 'Cargando tu perfil',
            message: 'Estamos trayendo tus datos personales.',
          ),
        ),
      );
    }

    final initials = profile.name
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
      backgroundColor: MenudoColors.appBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    _CircleActionButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: 14),
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
                    color: AppColors.e8,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: avatarEmoji?.isNotEmpty == true
                            ? Text(
                                avatarDisplay,
                                style: const TextStyle(fontSize: 34),
                              )
                            : Text(
                                avatarDisplay,
                                style: MenudoTextStyles.h2.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: MenudoTextStyles.h3.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              profile.email,
                              style: MenudoTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                MenudoChip.custom(
                                  label: profile.baseCurrency,
                                  color: Colors.white,
                                  bgColor: Colors.white.withValues(alpha: 0.12),
                                ),
                                MenudoChip.custom(
                                  label: _formatJoined(profile),
                                  color: Colors.white,
                                  bgColor: Colors.white.withValues(alpha: 0.12),
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
                      const SizedBox(height: 8),
                      _ReadOnlyField(
                        value: avatarEmoji?.isNotEmpty == true
                            ? 'Avatar $avatarEmoji'
                            : 'Elegir emoji o usar iniciales',
                        onTap: _pickAvatarEmoji,
                        trailing: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.g1,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: avatarEmoji?.isNotEmpty == true
                              ? Text(
                                  avatarEmoji!,
                                  style: const TextStyle(fontSize: 20),
                                )
                              : Text(
                                  avatarDisplay,
                                  style: MenudoTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Nombre'),
                      const SizedBox(height: 8),
                      _PlainTextField(
                        controller: _nameController,
                        hintText: 'Tu nombre',
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Correo'),
                      const SizedBox(height: 8),
                      _ReadOnlyField(value: profile.email),
                      const SizedBox(height: 16),
                      _FieldLabel('Moneda base'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ChoicePill(
                              label: 'DOP',
                              selected: _currency == 'DOP',
                              onTap: () => setState(() => _currency = 'DOP'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ChoicePill(
                              label: 'USD',
                              selected: _currency == 'USD',
                              onTap: () => setState(() => _currency = 'USD'),
                            ),
                          ),
                        ],
                      ),
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
                          color: MenudoColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _goalOptions
                            .map(
                              (option) => _ChoiceTag(
                                label: option,
                                selected: _financialGoal == option,
                                onTap: () => setState(() {
                                  _financialGoal = _financialGoal == option
                                      ? null
                                      : option;
                                }),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Monto objetivo'),
                      const SizedBox(height: 8),
                      _PlainTextField(
                        controller: _amountController,
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        onChanged: _onAmountChanged,
                        prefixText: _currency == 'USD' ? 'US\$ ' : 'RD\$ ',
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Fecha objetivo'),
                      const SizedBox(height: 8),
                      _ReadOnlyField(
                        value: _formatDate(_goalDate),
                        onTap: _pickGoalDate,
                        trailing: _goalDate == null
                            ? null
                            : IconButton(
                                onPressed: () =>
                                    setState(() => _goalDate = null),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: MenudoColors.textMuted,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Presupuesto inicial opcional'),
                      const SizedBox(height: 6),
                      Text(
                        'Solo si quieres abrir primero uno de tus presupuestos.',
                        style: MenudoTextStyles.bodySmall.copyWith(
                          color: MenudoColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ReadOnlyField(
                        value: _budgetLabel(
                          profile,
                          budgets,
                          isLoading:
                              budgetsState.isLoading &&
                              budgetsState.valueOrNull == null,
                        ),
                        onTap: () => _pickDefaultBudget(profile),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                        'Puedes entrar con Apple o con correo y contraseña. Mantén tu correo confirmado y usa una contraseña segura si eliges ese método.',
                        style: MenudoTextStyles.bodySmall.copyWith(
                          color: MenudoColors.textMuted,
                        ),
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
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final preview = _normalizeEmoji(_controller.text) ?? _selectedEmoji;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
                color: AppColors.g2,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Tu avatar', style: MenudoTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'Elige uno rápido o escribe cualquier emoji.',
            style: MenudoTextStyles.bodySmall.copyWith(
              color: MenudoColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.e1,
                borderRadius: BorderRadius.circular(26),
              ),
              alignment: Alignment.center,
              child: Text(
                preview ?? 'M',
                style: TextStyle(
                  fontSize: preview == null ? 26 : 40,
                  fontWeight: preview == null ? FontWeight.w900 : null,
                  color: preview == null ? AppColors.e8 : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.suggestions.map((emoji) {
              final isSelected = emoji == preview;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
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
                    color: isSelected ? AppColors.e1 : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppColors.e8 : MenudoColors.border,
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _FieldLabel('Emoji personalizado'),
          const SizedBox(height: 8),
          _PlainTextField(
            controller: _controller,
            hintText: '🙂',
            onChanged: (value) {
              setState(() => _selectedEmoji = _normalizeEmoji(value));
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: MenudoSecondaryButton(
                  label: 'Quitar',
                  onTap: () => Navigator.of(context).pop(''),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MenudoButton(
                  label: 'Guardar',
                  isFullWidth: true,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_normalizeEmoji(_controller.text) ?? _selectedEmoji),
                ),
              ),
            ],
          ),
        ],
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
          color: MenudoColors.textMuted,
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

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.e8 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.e8 : AppColors.g2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: MenudoTextStyles.bodyMedium.copyWith(
            color: selected ? Colors.white : MenudoColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.o1 : AppColors.g1,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.o5 : AppColors.g2),
        ),
        child: Text(
          label,
          style: MenudoTextStyles.bodySmall.copyWith(
            color: selected ? AppColors.o5 : MenudoColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MenudoColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: MenudoTextStyles.bodyLarge.copyWith(
                  color: MenudoColors.textMain,
                ),
              ),
            ),
            ...?(trailingWidget == null ? null : [trailingWidget]),
            if (onTap != null && trailing == null)
              const Icon(
                Icons.chevron_right_rounded,
                color: MenudoColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _DefaultBudgetSelection {
  const _DefaultBudgetSelection(this.budgetId);

  final int? budgetId;
}

class _DefaultBudgetSheet extends StatelessWidget {
  const _DefaultBudgetSheet({
    required this.budgets,
    required this.selectedBudgetId,
  });

  final List<MenudoBudget> budgets;
  final int? selectedBudgetId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        24 + MediaQuery.of(context).padding.bottom,
      ),
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
          Text('Presupuesto inicial opcional', style: MenudoTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'Solo se usará si quieres abrir primero uno de tus presupuestos.',
            style: MenudoTextStyles.bodySmall.copyWith(
              color: MenudoColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          ...budgets.map((budget) {
            final isSelected = budget.id == selectedBudgetId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BudgetSelectionTile(
                label: budget.nombre,
                subtitle: budget.periodo,
                selected: isSelected,
                onTap: () => Navigator.of(
                  context,
                ).pop(_DefaultBudgetSelection(budget.id)),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _BudgetSelectionTile(
              label: 'No usar uno fijo',
              subtitle: 'Entrarás a la app sin priorizar ningún presupuesto',
              selected: selectedBudgetId == null,
              isNeutral: true,
              onTap: () => Navigator.of(
                context,
              ).pop(const _DefaultBudgetSelection(null)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSelectionTile extends StatelessWidget {
  const _BudgetSelectionTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.isNeutral = false,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final bool isNeutral;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isNeutral ? AppColors.g5 : AppColors.e8;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: isNeutral ? 0.08 : 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : MenudoColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? accent : AppColors.g3),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: MenudoTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: MenudoColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: MenudoTextStyles.bodySmall.copyWith(
                      color: MenudoColors.textMuted,
                    ),
                  ),
                ],
              ),
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
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      style: MenudoTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        hintStyle: MenudoTextStyles.bodyLarge.copyWith(
          color: MenudoColors.textMuted,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MenudoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MenudoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: MenudoColors.borderActive,
            width: 2,
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: MenudoColors.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: MenudoColors.textMain),
      ),
    );
  }
}
