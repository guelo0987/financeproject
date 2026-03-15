import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../model/user_profile.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_chip.dart';
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

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

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
    super.dispose();
  }

  void _hydrateFromProfile() {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;
    _nameController.text = profile.name;
    _currency = profile.baseCurrency;
    _financialGoal = profile.financialGoal;
    _goalDate = profile.goalDate;
    _amountController.text = _formatMoney(profile.goalAmount);
    if (mounted) setState(() {});
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

  String _budgetLabel(UserProfile profile) {
    final budgets = ref.read(effectiveBudgetsProvider);
    for (final budget in budgets) {
      if (budget.id == profile.defaultBudgetId) {
        return budget.nombre;
      }
    }
    return 'Se elige desde Presupuestos';
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
            financialGoal: _financialGoal?.trim().isEmpty == true
                ? null
                : _financialGoal,
            goalAmount: _parseMoney(),
            goalDate: _goalDate,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tus cambios fueron guardados.')),
      );
    } catch (error) {
      _showMessage(presentError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openPasswordSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;

    if (profile == null) {
      return const Scaffold(
        backgroundColor: MenudoColors.appBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final initials = profile.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

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
                        child: Text(
                          initials.isEmpty ? 'M' : initials,
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
                      _FieldLabel('Presupuesto activo'),
                      const SizedBox(height: 8),
                      _ReadOnlyField(value: _budgetLabel(profile)),
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
                        'Cambia tu contraseña cuando lo necesites.',
                        style: MenudoTextStyles.bodySmall.copyWith(
                          color: MenudoColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      MenudoSecondaryButton(
                        label: 'Cambiar contraseña',
                        onTap: _openPasswordSheet,
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
                  label: _isSaving ? 'Guardando...' : 'Guardar cambios',
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

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving) return;
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _showMessage('Completa los tres campos.');
      return;
    }
    if (next.length < 8) {
      _showMessage('La nueva contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (next != confirm) {
      _showMessage('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(currentPassword: current, newPassword: next);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu contraseña fue actualizada.')),
      );
    } catch (error) {
      _showMessage(presentError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.g2,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 18),
          Text('Cambiar contraseña', style: MenudoTextStyles.h3),
          const SizedBox(height: 18),
          _PlainTextField(
            controller: _currentController,
            hintText: 'Contraseña actual',
            obscureText: !_showCurrent,
            trailing: _VisibilityToggle(
              visible: _showCurrent,
              onTap: () => setState(() => _showCurrent = !_showCurrent),
            ),
          ),
          const SizedBox(height: 12),
          _PlainTextField(
            controller: _newController,
            hintText: 'Nueva contraseña',
            obscureText: !_showNew,
            trailing: _VisibilityToggle(
              visible: _showNew,
              onTap: () => setState(() => _showNew = !_showNew),
            ),
          ),
          const SizedBox(height: 12),
          _PlainTextField(
            controller: _confirmController,
            hintText: 'Repite la nueva contraseña',
            obscureText: !_showConfirm,
            trailing: _VisibilityToggle(
              visible: _showConfirm,
              onTap: () => setState(() => _showConfirm = !_showConfirm),
            ),
          ),
          const SizedBox(height: 18),
          MenudoButton(
            label: _saving ? 'Guardando...' : 'Actualizar contraseña',
            isFullWidth: true,
            isDisabled: _saving,
            onTap: _save,
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

class _PlainTextField extends StatelessWidget {
  const _PlainTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.onChanged,
    this.obscureText = false,
    this.trailing,
    this.textCapitalization = TextCapitalization.none,
    this.prefixText,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final Widget? trailing;
  final TextCapitalization textCapitalization;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: MenudoTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        suffixIcon: trailing,
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

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: MenudoColors.textSecondary,
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
