import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';

import '../../../../core/data/models.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_presenter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../../../shared/widgets/menudo_card.dart';
import '../../budgets/budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../transactions/presentation/transaction_presentation_utils.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';

class QuickExpenseShortcutSheet extends ConsumerStatefulWidget {
  final String source;

  const QuickExpenseShortcutSheet({super.key, required this.source});

  @override
  ConsumerState<QuickExpenseShortcutSheet> createState() =>
      _QuickExpenseShortcutSheetState();
}

class _QuickExpenseShortcutSheetState
    extends ConsumerState<QuickExpenseShortcutSheet>
    with SingleTickerProviderStateMixin {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  bool _isSaving = false;
  String? _selectedCategorySlug;
  String? _formMessage;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(_shakeController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    MenudoHaptics.error();
    _shakeController
      ..reset()
      ..animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1, stiffness: 620, damping: 24),
          0,
          1,
          0,
        ),
      );
    setState(() => _formMessage = message);
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final rawAmount = _amountCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(rawAmount);
    final wallets = ref.read(effectiveWalletsProvider);
    final defaultWallet = ref.read(defaultWalletProvider);
    final categories = ref.read(effectiveCategoriesProvider);
    final category = categories
        .where((item) => item.slug == _selectedCategorySlug)
        .firstOrNull;

    if (amount == null || amount <= 0) {
      _showError('Escribe un monto válido.');
      return;
    }

    if (category == null) {
      _showError('Elige una categoría para continuar.');
      return;
    }

    final wallet = defaultWallet ?? (wallets.isNotEmpty ? wallets.first : null);
    if (wallet == null) {
      _showError('Necesitas una cuenta disponible para registrar este gasto.');
      return;
    }

    final amountValidationMessage = validateTransactionAmountAgainstWallets(
      transactionType: 'gasto',
      amount: amount,
      sourceWallet: wallet,
    );
    if (amountValidationMessage != null) {
      _showError(amountValidationMessage);
      return;
    }

    final notifier = ref.read(transactionNotifierProvider.notifier);
    final transaction = MenudoTransaction(
      id: 0,
      dateString: DateTime.now().toIso8601String().split('T').first,
      desc: category.nombre,
      catKey: category.slug,
      budgetId: null,
      categoryId: category.id,
      monto: -amount,
      tipo: 'gasto',
      icono: category.icono,
      fromAccountId: wallet.id,
      nota: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      moneda: wallet.moneda,
    );

    setState(() {
      _formMessage = null;
      _isSaving = true;
    });

    try {
      await notifier.addTransaction(transaction);
      await ref.read(walletNotifierProvider.notifier).refresh();
      await ref.read(budgetNotifierProvider.notifier).refresh();
      if (!mounted) return;
      MenudoHaptics.success();
      Navigator.of(context).pop(true);
    } catch (error) {
      _showError(presentError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<MenudoCategory> _topExpenseCategories(
    List<MenudoCategory> categories,
    List<MenudoTransaction> transactions,
  ) {
    final counts = <String, int>{};
    for (final transaction in transactions) {
      if (transaction.tipo != 'gasto' || transaction.catKey.isEmpty) continue;
      counts.update(
        transaction.catKey,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final expenseCategories = categories
        .where((category) => category.tipo == 'gasto')
        .toList();

    expenseCategories.sort((a, b) {
      final byFrequency = (counts[b.slug] ?? 0).compareTo(counts[a.slug] ?? 0);
      if (byFrequency != 0) return byFrequency;
      if (a.esParent != b.esParent) return a.esParent ? 1 : -1;
      return a.nombre.compareTo(b.nombre);
    });

    return expenseCategories.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = context.menudo;
    final wallets = ref.watch(effectiveWalletsProvider);
    final defaultWallet = ref.watch(defaultWalletProvider);
    final categories = ref.watch(effectiveCategoriesProvider);
    final transactions = ref.watch(effectiveTransactionsProvider);
    final topCategories = _topExpenseCategories(categories, transactions);
    if (_selectedCategorySlug == null && topCategories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedCategorySlug != null) return;
        setState(() => _selectedCategorySlug = topCategories.first.slug);
      });
    }
    final wallet = defaultWallet ?? (wallets.isNotEmpty ? wallets.first : null);
    final currency = wallet?.moneda ?? AppFormattingPreferences.currencyCode;
    final isCompact = media.size.height < 820;
    final parsedAmount =
        double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final canSave =
        !_isSaving &&
        wallet != null &&
        _selectedCategorySlug != null &&
        parsedAmount > 0;

    return MenudoGestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: media.size.height * (isCompact ? 0.76 : 0.72),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 10),
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.p8,
                  AppSpacing.screen,
                  media.padding.bottom + AppSpacing.p18,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gasto rápido',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: colors.textMain,
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(height: AppSpacing.p8),
                    Text(
                      wallet == null
                          ? 'Necesitas una cuenta antes de registrar gastos.'
                          : 'Se guardará como gasto normal en ${wallet.nombre}.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.p18),
                    MenudoCard(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.p18,
                        AppSpacing.p16,
                        AppSpacing.p18,
                        AppSpacing.p18,
                      ),
                      child: TextField(
                        controller: _amountCtrl,
                        focusNode: _amountFocus,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          MenudoHaptics.light();
                          setState(() => _formMessage = null);
                        },
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            color: colors.textMuted.withValues(alpha: 0.4),
                            letterSpacing: -1.2,
                          ),
                          prefixText:
                              '${formatMoney(0, currency: currency).replaceAll('0', '')} ',
                          prefixStyle: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: colors.textMuted,
                          ),
                          filled: true,
                          fillColor: colors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.p16,
                            vertical: AppSpacing.p20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: AppColors.o5,
                              width: 1.6,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 46,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: colors.textMain,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.p14),
                    MenudoCard(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.p18,
                        AppSpacing.p16,
                        AppSpacing.p18,
                        AppSpacing.p18,
                      ),
                      child: _OneTapCategoryGrid(
                        categories: topCategories,
                        selectedSlug: _selectedCategorySlug,
                        onSelected: (category) {
                          MenudoHaptics.selection();
                          setState(() {
                            _selectedCategorySlug = category.slug;
                            _formMessage = null;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: AppSpacing.p14),
                    MenudoCard(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.p18,
                        AppSpacing.p16,
                        AppSpacing.p18,
                        AppSpacing.p18,
                      ),
                      child: TextField(
                        controller: _noteCtrl,
                        textInputAction: TextInputAction.done,
                        minLines: 1,
                        maxLines: 3,
                        onChanged: (_) {
                          if (_formMessage == null) return;
                          setState(() => _formMessage = null);
                        },
                        decoration: InputDecoration(
                          hintText: 'Añade una nota...',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: colors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.p16,
                            vertical: AppSpacing.p16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: AppColors.o5,
                              width: 1.6,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textMain,
                        ),
                      ),
                    ),
                    if (_formMessage != null) ...[
                      SizedBox(height: AppSpacing.p14),
                      AnimatedBuilder(
                        animation: _shakeOffset,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.p14,
                            vertical: AppSpacing.p12,
                          ),
                          decoration: BoxDecoration(
                            color: context.menudo.dangerLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.r5.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Text(
                            _formMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.r5,
                            ),
                          ),
                        ),
                        builder: (context, child) => Transform.translate(
                          offset: Offset(_shakeOffset.value, 0),
                          child: child,
                        ),
                      ),
                    ],
                    SizedBox(height: AppSpacing.p18),
                    MenudoButton(
                      label: _isSaving ? 'Guardando...' : 'Registrar gasto',
                      isFullWidth: true,
                      isDisabled: !canSave,
                      onTap: _save,
                      icon: MenudoCupertinoIcons.plusCircle,
                    ),
                    SizedBox(height: AppSpacing.p10),
                    Center(
                      child: Text(
                        widget.source == 'transaction_automation'
                            ? 'Abierto desde una automatización.'
                            : 'También puedes abrir esto desde un acceso rápido del dispositivo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OneTapCategoryGrid extends StatelessWidget {
  const _OneTapCategoryGrid({
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
  });

  final List<MenudoCategory> categories;
  final String? selectedSlug;
  final ValueChanged<MenudoCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    if (categories.isEmpty) {
      return Text(
        'Crea una categoría de gasto para usar el registro rápido.',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => SizedBox(width: AppSpacing.p10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.slug == selectedSlug;
          return _OneTapCategoryTile(
            category: category,
            selected: selected,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _OneTapCategoryTile extends StatelessWidget {
  const _OneTapCategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final MenudoCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final color = category.color;

    return Semantics(
      button: true,
      selected: selected,
      label: category.nombre,
      child: MenudoGestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 82,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.p10,
            vertical: AppSpacing.p10,
          ),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.13) : colors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.8) : colors.border,
              width: selected ? 1.4 : 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(category.icono, color: color, size: (22)),
              ),
              SizedBox(height: AppSpacing.p8),
              Text(
                category.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected ? colors.textMain : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
