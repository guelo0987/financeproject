import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';

import '../../../../core/data/models.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/preferences/app_preferences_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_presenter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../../../shared/widgets/menudo_toast.dart';
import '../../auth/auth_state.dart';
import '../../budgets/budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/presentation/transaction_presentation_utils.dart';
import '../../wallet/providers/wallet_providers.dart';

enum _TransactionEntryStep { amount, details }

class RegisterTransactionSheet extends ConsumerStatefulWidget {
  final MenudoTransaction? transaction;
  final String? initialType;
  final int? initialFromAccountId;
  final int? initialBudgetId;

  const RegisterTransactionSheet({
    super.key,
    this.transaction,
    this.initialType,
    this.initialFromAccountId,
    this.initialBudgetId,
  });

  @override
  ConsumerState<RegisterTransactionSheet> createState() =>
      _RegisterTransactionSheetState();
}

class _RegisterTransactionSheetState
    extends ConsumerState<RegisterTransactionSheet>
    with SingleTickerProviderStateMixin {
  String _amount = "";
  int _selectedTypeIndex = 0; // 0: Gasto, 1: Ingreso, 2: Transferencia
  _TransactionEntryStep _step = _TransactionEntryStep.amount;
  int? _budgetId;
  String? _catKey;
  String? _nota;
  int? _fromAccountId;
  int? _toAccountId;
  bool _isSaving = false;
  String? _formMessage;
  bool _budgetSelectionInitialized = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;

  bool get _isEditing => widget.transaction != null;

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

    if (!_isEditing && widget.initialType != null) {
      _selectedTypeIndex = switch (widget.initialType) {
        'ingreso' => 1,
        'transferencia' => 2,
        _ => 0,
      };
    }

    if (!_isEditing && widget.initialBudgetId != null) {
      _budgetId = widget.initialBudgetId;
      _budgetSelectionInitialized = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditing) return;

      final defaultId =
          widget.initialFromAccountId ?? ref.read(defaultWalletIdProvider);
      final wallets = ref.read(walletNotifierProvider).valueOrNull ?? [];
      final initialId =
          defaultId != null && wallets.any((wallet) => wallet.id == defaultId)
          ? defaultId
          : wallets.isNotEmpty
          ? wallets.first.id
          : null;

      if (initialId != null && mounted) {
        setState(() => _fromAccountId = initialId);
      }
    });

    if (_isEditing) {
      final txn = widget.transaction!;
      _step = _TransactionEntryStep.details;
      _amount = txn.monto.abs().toStringAsFixed(
        txn.monto.abs() % 1 == 0 ? 0 : 2,
      );
      _budgetId = txn.budgetId;
      _catKey = txn.catKey;
      _nota = txn.nota;
      _fromAccountId = txn.fromAccountId;
      _toAccountId = txn.toAccountId;
      _selectedTypeIndex = switch (txn.tipo) {
        'ingreso' => 1,
        'transferencia' => 2,
        _ => 0,
      };
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    if (_selectedTypeIndex == 1) {
      return AppColors.e6;
    }
    if (_selectedTypeIndex == 2) {
      return AppColors.b5;
    }
    return AppColors.r5;
  }

  String get _selectedType {
    switch (_selectedTypeIndex) {
      case 1:
        return 'ingreso';
      case 2:
        return 'transferencia';
      default:
        return 'gasto';
    }
  }

  void _setTypeIndex(int index) {
    final categories = ref.read(effectiveCategoriesProvider);
    final selectedCategory = _catKey == null
        ? null
        : categories.where((category) => category.slug == _catKey).firstOrNull;
    final nextType = switch (index) {
      1 => 'ingreso',
      2 => 'transferencia',
      _ => 'gasto',
    };

    setState(() {
      _selectedTypeIndex = index;
      _formMessage = null;
      if (nextType == 'transferencia' ||
          (selectedCategory != null && selectedCategory.tipo != nextType)) {
        _catKey = null;
      }
      if (nextType != 'transferencia') {
        _toAccountId = null;
      }
    });
  }

  void _onKeyTap(String key) {
    MenudoHaptics.light();
    setState(() {
      _formMessage = null;
      if (key == 'backspace') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount = _amount.isEmpty ? "0." : "$_amount.";
        }
      } else {
        if (_amount == "0") {
          _amount = key;
        } else if (_amount.length < 9) {
          _amount += key;
        }
      }
    });
  }

  void _goToDetails(List<WalletAccount> wallets) {
    final amountValue = double.tryParse(_amount) ?? 0;
    if (amountValue <= 0) {
      _showError('Escribe un monto mayor que cero.');
      return;
    }

    final hasFromAccount =
        _fromAccountId != null &&
        wallets.any((wallet) => wallet.id == _fromAccountId);
    if (!hasFromAccount) {
      _showError('Agrega una cuenta para guardar este movimiento.');
      return;
    }

    MenudoHaptics.medium();
    setState(() {
      _formMessage = null;
      _step = _TransactionEntryStep.details;
    });
  }

  void _returnToAmount() {
    if (_isEditing) return;
    MenudoHaptics.light();
    setState(() {
      _formMessage = null;
      _step = _TransactionEntryStep.amount;
    });
  }

  Future<void> _saveTransaction() async {
    if (_isSaving) return;

    if (_amount.isEmpty) {
      _showError('Escribe un monto para guardar este movimiento.');
      return;
    }

    final amountValue = double.tryParse(_amount);
    if (amountValue == null || amountValue == 0) {
      _showError('El monto debe ser mayor que cero.');
      return;
    }

    final wallets = ref.read(effectiveWalletsProvider);
    final categories = ref.read(effectiveCategoriesProvider);
    final categoriesBySlug = {
      for (final category in categories) category.slug: category,
    };
    final selectedCategory = _catKey == null
        ? null
        : categoriesBySlug[_catKey!];
    final requiresCategory = _selectedType != 'transferencia';

    if (requiresCategory && (_catKey == null || _catKey!.isEmpty)) {
      _showError('Elige una categoría para continuar.');
      return;
    }

    if (_fromAccountId == null ||
        !wallets.any((wallet) => wallet.id == _fromAccountId)) {
      _showError('Elige la cuenta desde donde saldrá este movimiento.');
      return;
    }

    if (_selectedType == 'transferencia') {
      if (_toAccountId == null ||
          !wallets.any((wallet) => wallet.id == _toAccountId)) {
        _showError('Elige la cuenta a la que quieres mover el dinero.');
        return;
      }
      if (_toAccountId == _fromAccountId) {
        _showError('Usa dos cuentas distintas para mover dinero.');
        return;
      }
    }

    final sourceWallet = _findWallet(_fromAccountId, wallets);
    final destinationWallet = _findWallet(_toAccountId, wallets);
    final transactionCurrency = _transactionCurrencyFor(wallets);
    final destinationCurrency = _effectiveConfiguredCurrency(
      destinationWallet?.moneda,
    );
    if (_selectedType == 'transferencia' &&
        destinationCurrency != transactionCurrency) {
      _showError(
        'Elige cuentas con la misma moneda para mover dinero entre ellas.',
      );
      return;
    }

    final amountValidationMessage = validateTransactionAmountAgainstWallets(
      transactionType: _selectedType,
      amount: amountValue,
      sourceWallet: sourceWallet,
      destinationWallet: destinationWallet,
    );
    if (amountValidationMessage != null) {
      _showError(amountValidationMessage);
      return;
    }

    final fallbackDescription = _selectedType == 'transferencia'
        ? 'Transferencia'
        : (selectedCategory?.nombre ?? _catKey!);
    final description = _isEditing && widget.transaction!.tipo == _selectedType
        ? widget.transaction!.desc
        : fallbackDescription;
    final transaction = MenudoTransaction(
      id: widget.transaction?.id ?? 0,
      dateString:
          widget.transaction?.dateString ??
          DateTime.now().toIso8601String().split('T').first,
      desc: description,
      catKey: _selectedType == 'transferencia' ? '' : _catKey!,
      budgetId: _selectedType == 'transferencia' ? null : _budgetId,
      categoryId: _selectedType == 'transferencia'
          ? null
          : selectedCategory?.id,
      monto: _selectedType == 'ingreso' ? amountValue : -amountValue,
      tipo: _selectedType,
      icono:
          (_selectedType == 'transferencia'
              ? MenudoCupertinoIcons.arrowLeftRight
              : selectedCategory?.icono) ??
          widget.transaction?.icono ??
          MenudoCupertinoIcons.circle,
      fromAccountId: _fromAccountId,
      toAccountId: _selectedType == 'transferencia' ? _toAccountId : null,
      nota: _nota,
      moneda: transactionCurrency,
    );

    setState(() {
      _formMessage = null;
      _isSaving = true;
    });

    try {
      final notifier = ref.read(transactionNotifierProvider.notifier);
      if (_isEditing) {
        await notifier.updateTransaction(transaction);
      } else {
        await notifier.addTransaction(transaction);
      }
      await ref.read(walletNotifierProvider.notifier).refresh();
      await ref.read(budgetNotifierProvider.notifier).refresh();

      if (!mounted) return;
      final rootContext = Navigator.of(context, rootNavigator: true).context;
      MenudoHaptics.success();
      Navigator.pop(context);
      if (rootContext.mounted) {
        MenudoToast.success(
          rootContext,
          title: _isEditing ? 'Movimiento actualizado' : 'Movimiento guardado',
          message: transaction.desc,
        );
      }
    } catch (error) {
      _showError(presentError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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

  WalletAccount? _findWallet(int? id, List<WalletAccount> wallets) {
    if (id == null) return null;
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  String? _normalizeCurrency(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String _configuredCurrencyCode() {
    return _normalizeCurrency(
          ref.read(appPreferencesProvider).valueOrNull?.currencyCode,
        ) ??
        _normalizeCurrency(ref.read(authProvider).profile?.baseCurrency) ??
        AppFormattingPreferences.currencyCode;
  }

  String _effectiveConfiguredCurrency(String? value) {
    final configured = _configuredCurrencyCode();
    final normalized = _normalizeCurrency(value);
    if (normalized == null) return configured;
    if (normalized == 'DOP' && configured != 'DOP') return configured;
    return normalized;
  }

  String _transactionCurrencyFor(List<WalletAccount> wallets) {
    final configured = _configuredCurrencyCode();

    String? resolved(String? value) {
      final normalized = _normalizeCurrency(value);
      if (normalized == null) return null;
      if (normalized == 'DOP' && configured != 'DOP') return null;
      return normalized;
    }

    return resolved(_findWallet(_fromAccountId, wallets)?.moneda) ??
        resolved(widget.transaction?.moneda) ??
        configured;
  }

  List<_CategoryChoiceGroup> _categoryGroupsFor(
    List<MenudoCategory> categories,
  ) {
    final filtered = categories
        .where((category) => category.tipo == _selectedType)
        .toList();
    final parents = filtered.where((category) => category.esParent).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    final children = filtered.where((category) => !category.esParent).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    final childrenByParent = <int?, List<MenudoCategory>>{};

    for (final child in children) {
      childrenByParent
          .putIfAbsent(child.categoriaParadreId, () => [])
          .add(child);
    }

    final groups = <_CategoryChoiceGroup>[
      for (final parent in parents)
        if ((childrenByParent[parent.id] ?? const <MenudoCategory>[])
            .isNotEmpty)
          _CategoryChoiceGroup(
            parent: parent,
            categories: childrenByParent[parent.id]!,
          ),
    ];

    final orphanCategories = childrenByParent.entries
        .where(
          (entry) =>
              entry.key == null ||
              !parents.any((parent) => parent.id == entry.key),
        )
        .expand((entry) => entry.value)
        .toList();

    if (orphanCategories.isNotEmpty) {
      groups.add(
        _CategoryChoiceGroup(parent: null, categories: orphanCategories),
      );
    }

    return groups;
  }

  void _maybeSeedFromAccount(List<WalletAccount> wallets) {
    if (wallets.isEmpty) return;

    final currentIsValid =
        _fromAccountId != null &&
        wallets.any((wallet) => wallet.id == _fromAccountId);
    if (currentIsValid) return;

    final defaultId =
        widget.initialFromAccountId ?? ref.read(defaultWalletIdProvider);
    final fallbackId =
        defaultId != null && wallets.any((wallet) => wallet.id == defaultId)
        ? defaultId
        : wallets.first.id;

    if (_fromAccountId == fallbackId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final stillInvalid =
          _fromAccountId == null ||
          !wallets.any((wallet) => wallet.id == _fromAccountId);
      if (!stillInvalid) return;

      setState(() {
        _fromAccountId = fallbackId;
      });
    });
  }

  void _maybeSeedBudget(List<MenudoBudget> budgets) {
    if (_isEditing || _budgetSelectionInitialized || budgets.isEmpty) return;

    final preferredBudgetId =
        widget.initialBudgetId ?? ref.read(selectedBudgetIdProvider);
    final activeBudget = budgets.where((budget) => budget.activo).firstOrNull;
    final fallbackBudgetId = activeBudget?.id ?? budgets.first.id;
    final nextBudgetId =
        preferredBudgetId != null &&
            budgets.any((budget) => budget.id == preferredBudgetId)
        ? preferredBudgetId
        : fallbackBudgetId;

    _budgetSelectionInitialized = true;
    if (_budgetId == nextBudgetId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _budgetId != null) return;
      setState(() => _budgetId = nextBudgetId);
    });
  }

  List<String> _missingFields(List<WalletAccount> wallets, double amountValue) {
    final items = <String>[];
    final hasFromAccount =
        _fromAccountId != null &&
        wallets.any((wallet) => wallet.id == _fromAccountId);

    if (amountValue <= 0) {
      items.add('monto');
    }

    if (_selectedType != 'transferencia' &&
        (_catKey == null || _catKey!.isEmpty)) {
      items.add('categoría');
    }

    if (!hasFromAccount) {
      items.add('cuenta');
    }

    if (_selectedType == 'transferencia') {
      final hasDestination =
          _toAccountId != null &&
          wallets.any((wallet) => wallet.id == _toAccountId);
      if (!hasDestination) {
        items.add('destino');
      } else if (_toAccountId == _fromAccountId) {
        items.add('cuentas distintas');
      }
    }

    return items;
  }

  String _missingFieldsLabel(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items.first} y ${items.last}';
    return '${items.take(items.length - 1).join(', ')} y ${items.last}';
  }

  String _accountName(int? id, List<WalletAccount> wallets) {
    if (id == null) return "Elegir";
    final fallback = wallets.isNotEmpty ? wallets.first : null;
    final wallet = _findWallet(id, wallets);
    return wallet?.nombre ?? fallback?.nombre ?? "Elegir";
  }

  String _budgetName(int? id, List<MenudoBudget> budgets) {
    if (id == null) return 'General';
    for (final budget in budgets) {
      if (budget.id == id) return budget.nombre;
    }
    return 'Presupuesto #$id';
  }

  String _formattedAmountDisplay() {
    if (_amount.isEmpty) return '0';
    final parts = _amount.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    if (parts.length == 1) return whole;
    return '$whole.${parts.sublist(1).join()}';
  }

  Future<void> _pickBudget(List<MenudoBudget> budgets) async {
    if (budgets.isEmpty) return;

    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _BudgetPickerSheet(budgets: budgets, selectedId: _budgetId),
    );

    if (selected != null && mounted) {
      setState(() {
        _budgetId = selected <= 0 ? null : selected;
        _formMessage = null;
      });
    }
  }

  void _pickAccount({
    required bool isFrom,
    required List<WalletAccount> wallets,
  }) {
    MenudoHaptics.light();
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountPickerSheet(
        accounts: wallets,
        title: isFrom ? "Cuenta origen" : "Cuenta destino",
        selectedId: isFrom ? _fromAccountId : _toAccountId,
        excludeId: isFrom ? _toAccountId : _fromAccountId,
      ),
    ).then((id) {
      if (id != null && mounted) {
        setState(() {
          _formMessage = null;
          if (isFrom) {
            _fromAccountId = id;
          } else {
            _toAccountId = id;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compactSheet = media.size.height < 900 || media.size.width < 420;
    final stackFieldPairs = media.size.width <= 390;
    final amountValue = double.tryParse(_amount) ?? 0;
    final isTransfer = _selectedTypeIndex == 2;
    final wallets = ref.watch(effectiveWalletsProvider);
    _maybeSeedFromAccount(wallets);
    final budgets = ref.watch(effectiveBudgetsProvider);
    _maybeSeedBudget(budgets);
    final categories = ref.watch(effectiveCategoriesProvider);
    final categoriesBySlug = {
      for (final category in categories) category.slug: category,
    };
    final selectedCategory = _catKey == null
        ? null
        : categoriesBySlug[_catKey!];
    final selectedParent = selectedCategory?.categoriaParadreId == null
        ? null
        : categories
              .where(
                (category) =>
                    category.id == selectedCategory!.categoriaParadreId,
              )
              .firstOrNull;
    final categoryLabel = selectedCategory == null
        ? "Elegir"
        : selectedParent == null
        ? selectedCategory.nombre
        : "${selectedParent.nombre} / ${selectedCategory.nombre}";
    final budgetLabel = _budgetName(_budgetId, budgets);
    final noteLabel = (_nota == null || _nota!.trim().isEmpty)
        ? 'Agregar nota'
        : _nota!.trim();
    final missingFields = _missingFields(wallets, amountValue);
    final canSubmit = missingFields.isEmpty && !_isSaving;
    final keypadBottomPadding =
        media.padding.bottom + (compactSheet ? 8.0 : 10.0);
    final amountPrefix = currencyPrefix(_transactionCurrencyFor(wallets));

    final categoryChoiceGroups = _categoryGroupsFor(categories);
    final isAmountStep = _step == _TransactionEntryStep.amount && !_isEditing;
    final canContinue = amountValue > 0 && !_isSaving;
    final showMissingFields = !isAmountStep && missingFields.isNotEmpty;
    final primaryLabel = isAmountStep
        ? switch (_selectedType) {
            'ingreso' => 'Registrar ingreso',
            'transferencia' => 'Preparar movimiento',
            _ => 'Registrar gasto',
          }
        : _isSaving
        ? 'Guardando movimiento...'
        : _isEditing
        ? 'Guardar movimiento'
        : switch (_selectedType) {
            'ingreso' => 'Guardar ingreso',
            'transferencia' => 'Mover dinero',
            _ => 'Guardar gasto',
          };

    return Container(
      height: media.size.height * (compactSheet ? 0.95 : 0.92),
      decoration: BoxDecoration(
        color: context.menudo.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: context.menudo.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              compactSheet ? 6 : 10,
              20,
              compactSheet ? 12 : 16,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (!isAmountStep && !_isEditing) ...[
                      MenudoIconButton(
                        onPressed: _returnToAmount,
                        icon: Icon(
                          MenudoCupertinoIcons.chevronLeft,
                          color: context.menudo.textMain,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.menudo.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _TypeSegment(
                              label: 'Gasto',
                              index: 0,
                              current: _selectedTypeIndex,
                              onTap: _setTypeIndex,
                            ),
                            _TypeSegment(
                              label: 'Ingreso',
                              index: 1,
                              current: _selectedTypeIndex,
                              onTap: _setTypeIndex,
                            ),
                            _TypeSegment(
                              label: 'Mover',
                              index: 2,
                              current: _selectedTypeIndex,
                              onTap: _setTypeIndex,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compactSheet ? 14 : 20),
                _AmountHero(
                  prefix: isTransfer
                      ? amountPrefix
                      : (_selectedTypeIndex == 1
                            ? '+$amountPrefix'
                            : '-$amountPrefix'),
                  amount: _formattedAmountDisplay(),
                  accentColor: _accentColor,
                  isCompact: compactSheet,
                  isFocused: isAmountStep,
                  subtitle: isTransfer
                      ? 'Mover entre tus cuentas'
                      : _selectedTypeIndex == 1
                      ? 'Ingreso'
                      : 'Gasto',
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: isAmountStep
                  ? _AmountOnlyStage(
                      key: const ValueKey('amount-stage'),
                      accountName: _accountName(_fromAccountId, wallets),
                      hasAccount: _fromAccountId != null,
                      accentColor: _accentColor,
                      onAccountTap: () =>
                          _pickAccount(isFrom: true, wallets: wallets),
                    )
                  : SingleChildScrollView(
                      key: const ValueKey('details-stage'),
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        compactSheet ? 4 : 2,
                        20,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isTransfer) ...[
                            if (stackFieldPairs) ...[
                              _FieldCard(
                                icon: MenudoCupertinoIcons.arrowUpFromLine,
                                color: AppColors.e6,
                                label: 'Origen',
                                value: _accountName(_fromAccountId, wallets),
                                onTap: () => _pickAccount(
                                  isFrom: true,
                                  wallets: wallets,
                                ),
                                isPlaceholder: _fromAccountId == null,
                              ),
                              SizedBox(height: (12)),
                              _FieldCard(
                                icon: MenudoCupertinoIcons.arrowDownToLine,
                                color: AppColors.b5,
                                label: 'Destino',
                                value: _accountName(_toAccountId, wallets),
                                onTap: () => _pickAccount(
                                  isFrom: false,
                                  wallets: wallets,
                                ),
                                isPlaceholder: _toAccountId == null,
                              ),
                            ] else
                              Row(
                                children: [
                                  Expanded(
                                    child: _FieldCard(
                                      icon:
                                          MenudoCupertinoIcons.arrowUpFromLine,
                                      color: AppColors.e6,
                                      label: 'Origen',
                                      value: _accountName(
                                        _fromAccountId,
                                        wallets,
                                      ),
                                      onTap: () => _pickAccount(
                                        isFrom: true,
                                        wallets: wallets,
                                      ),
                                      isPlaceholder: _fromAccountId == null,
                                    ),
                                  ),
                                  SizedBox(width: (12)),
                                  Expanded(
                                    child: _FieldCard(
                                      icon:
                                          MenudoCupertinoIcons.arrowDownToLine,
                                      color: AppColors.b5,
                                      label: 'Destino',
                                      value: _accountName(
                                        _toAccountId,
                                        wallets,
                                      ),
                                      onTap: () => _pickAccount(
                                        isFrom: false,
                                        wallets: wallets,
                                      ),
                                      isPlaceholder: _toAccountId == null,
                                    ),
                                  ),
                                ],
                              ),
                          ] else ...[
                            _CategoryChoicePanel(
                              title: _selectedTypeIndex == 1
                                  ? 'Elige el origen'
                                  : 'Elige la categoría',
                              subtitle: categoryLabel,
                              selectedCategory: selectedCategory,
                              selectedParent: selectedParent,
                              groups: categoryChoiceGroups,
                              selectedKey: _catKey,
                              accentColor: _accentColor,
                              onSelected: (category) {
                                MenudoHaptics.selection();
                                setState(() {
                                  _catKey = category.slug;
                                  _formMessage = null;
                                });
                              },
                            ),
                            SizedBox(height: (12)),
                            _FieldCard(
                              icon: MenudoCupertinoIcons.landmark,
                              color: AppColors.b5,
                              label: 'Cuenta',
                              value: _accountName(_fromAccountId, wallets),
                              onTap: () =>
                                  _pickAccount(isFrom: true, wallets: wallets),
                              isPlaceholder: _fromAccountId == null,
                            ),
                            SizedBox(height: (12)),
                            _InfoStrip(
                              isGeneralMode: _budgetId == null,
                              budgetName: budgetLabel,
                              onBudgetTap: budgets.isEmpty
                                  ? null
                                  : () => _pickBudget(budgets),
                            ),
                          ],
                          SizedBox(height: (12)),
                          _SecondaryActionCard(
                            icon: MenudoCupertinoIcons.fileText,
                            color: AppColors.p5,
                            label: 'Nota',
                            value: noteLabel,
                            onTap: _showNoteDialog,
                          ),
                          SizedBox(height: (16)),
                        ],
                      ),
                    ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              compactSheet ? 8 : 10,
              20,
              keypadBottomPadding,
            ),
            decoration: BoxDecoration(
              color: context.menudo.background,
              border: Border(
                top: BorderSide(
                  color: context.menudo.surface.withValues(alpha: 0.9),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAmountStep) ...[
                  _Numpad(onKeyTap: _onKeyTap),
                  SizedBox(height: (12)),
                ],
                if (_formMessage != null || showMissingFields) ...[
                  AnimatedBuilder(
                    animation: _shakeOffset,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _formMessage != null
                            ? AppColors.negative.withValues(alpha: 0.08)
                            : context.menudo.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _formMessage != null
                              ? AppColors.negative.withValues(alpha: 0.22)
                              : context.menudo.border,
                        ),
                      ),
                      child: Text(
                        _formMessage ??
                            'Falta ${_missingFieldsLabel(missingFields)} para guardar este movimiento.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _formMessage != null
                              ? AppColors.negative
                              : context.menudo.textSecondary,
                        ),
                      ),
                    ),
                    builder: (context, child) => Transform.translate(
                      offset: Offset(_shakeOffset.value, 0),
                      child: child,
                    ),
                  ),
                  SizedBox(height: (12)),
                ],
                MenudoButton(
                  label: primaryLabel,
                  isFullWidth: true,
                  isDisabled: isAmountStep ? !canContinue : !canSubmit,
                  onTap: () =>
                      isAmountStep ? _goToDetails(wallets) : _saveTransaction(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog() {
    final ctrl = TextEditingController(text: _nota);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.menudo.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Nota",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: context.menudo.textMain,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: "Añade un detalle si lo necesitas",
            filled: true,
            fillColor: context.menudo.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: TextStyle(color: context.menudo.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _formMessage = null;
                _nota = ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: Text(
              "Guardar",
              style: TextStyle(
                color: AppColors.o5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSegment extends StatelessWidget {
  final String label;
  final int index;
  final int current;
  final Function(int) onTap;

  const _TypeSegment({
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: MenudoGestureDetector(
        onTap: () {
          MenudoHaptics.selection();
          onTap(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? context.menudo.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: context.menudo.background.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? context.menudo.primary : context.menudo.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final bool isGeneralMode;
  final String budgetName;
  final VoidCallback? onBudgetTap;

  const _InfoStrip({
    required this.isGeneralMode,
    required this.budgetName,
    this.onBudgetTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: context.menudo.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.menudo.border),
      ),
      child: _InfoStripItem(
        label: isGeneralMode ? 'Registro' : 'Presupuesto',
        value: budgetName,
        icon: isGeneralMode
            ? MenudoCupertinoIcons.fileText
            : MenudoCupertinoIcons.layoutGrid,
        color: isGeneralMode ? AppColors.e6 : context.menudo.textMain,
        onTap: onBudgetTap,
      ),
    );
  }
}

class _InfoStripItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _InfoStripItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: (30),
          height: (30),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: (15), color: color),
        ),
        SizedBox(width: (10)),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    SizedBox(width: 6),
                    Icon(
                      MenudoCupertinoIcons.chevronRight,
                      size: (14),
                      color: context.menudo.textMuted,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap == null) return child;

    return MenudoGestureDetector(
      onTap: () {
        MenudoHaptics.light();
        onTap!();
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _AmountHero extends StatelessWidget {
  final String prefix;
  final String amount;
  final String subtitle;
  final Color accentColor;
  final bool isCompact;
  final bool isFocused;

  const _AmountHero({
    required this.prefix,
    required this.amount,
    required this.subtitle,
    required this.accentColor,
    required this.isCompact,
    required this.isFocused,
  });

  @override
  Widget build(BuildContext context) {
    final amountFont = isFocused
        ? (isCompact ? 58.0 : 68.0)
        : (isCompact ? 38.0 : 44.0);

    return Column(
      children: [
        AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isFocused ? 18 : 14,
                vertical: isFocused ? 16 : 10,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isFocused ? 0.10 : 0.06),
                borderRadius: BorderRadius.circular(isFocused ? 30 : 24),
                border: Border.all(
                  color: accentColor.withValues(alpha: isFocused ? 0.18 : 0.10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: isFocused ? 14 : 8),
                    child: Text(
                      prefix,
                      style: TextStyle(
                        fontSize: isFocused ? 22 : 18,
                        fontWeight: FontWeight.w800,
                        color: accentColor.withValues(alpha: 0.52),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        amount,
                        key: ValueKey(amount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: amountFont,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          color: accentColor,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate(key: ValueKey(isFocused))
            .fadeIn()
            .scale(begin: const Offset(0.97, 0.97)),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.menudo.textMuted,
          ),
        ),
      ],
    );
  }
}

class _AmountOnlyStage extends StatelessWidget {
  final String accountName;
  final bool hasAccount;
  final Color accentColor;
  final VoidCallback onAccountTap;

  const _AmountOnlyStage({
    super.key,
    required this.accountName,
    required this.hasAccount,
    required this.accentColor,
    required this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.menudo.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.menudo.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  MenudoCupertinoIcons.landmark,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuenta',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: context.menudo.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      accountName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: hasAccount
                            ? context.menudo.textMain
                            : context.menudo.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              MenudoIconButton(
                onPressed: onAccountTap,
                icon: Icon(
                  MenudoCupertinoIcons.chevronRight,
                  color: context.menudo.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChoicePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final MenudoCategory? selectedCategory;
  final MenudoCategory? selectedParent;
  final List<_CategoryChoiceGroup> groups;
  final String? selectedKey;
  final Color accentColor;
  final ValueChanged<MenudoCategory> onSelected;

  const _CategoryChoicePanel({
    required this.title,
    required this.subtitle,
    required this.selectedCategory,
    required this.selectedParent,
    required this.groups,
    required this.selectedKey,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: colors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(MenudoCupertinoIcons.tag, color: accentColor),
            ],
          ),
          const SizedBox(height: 16),
          _SelectedCategorySummary(
            selectedCategory: selectedCategory,
            selectedParent: selectedParent,
            fallbackLabel: subtitle,
            accentColor: accentColor,
          ),
          const SizedBox(height: 14),
          if (groups.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                'No hay categorías disponibles todavía.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: [
                for (var index = 0; index < groups.length; index++) ...[
                  _CategoryChoiceGroupSection(
                    group: groups[index],
                    selectedKey: selectedKey,
                    accentColor: accentColor,
                    onSelected: onSelected,
                  ),
                  if (index != groups.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryChoiceGroup {
  final MenudoCategory? parent;
  final List<MenudoCategory> categories;

  const _CategoryChoiceGroup({required this.parent, required this.categories});
}

class _SelectedCategorySummary extends StatelessWidget {
  final MenudoCategory? selectedCategory;
  final MenudoCategory? selectedParent;
  final String fallbackLabel;
  final Color accentColor;

  const _SelectedCategorySummary({
    required this.selectedCategory,
    required this.selectedParent,
    required this.fallbackLabel,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final category = selectedCategory;
    final parent = selectedParent;
    final hasSelection = category != null;
    final displayColor = category?.color ?? accentColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasSelection
            ? displayColor.withValues(alpha: 0.12)
            : colors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasSelection
              ? displayColor.withValues(alpha: 0.32)
              : colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              category?.icono ?? MenudoCupertinoIcons.tag,
              color: displayColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSelection ? category.nombre : fallbackLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: hasSelection ? colors.textMain : colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasSelection && parent != null
                      ? parent.nombre
                      : 'Agrupadas por categoría padre',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (hasSelection)
            Icon(MenudoCupertinoIcons.checkCircle, color: displayColor),
        ],
      ),
    );
  }
}

class _CategoryChoiceGroupSection extends StatelessWidget {
  final _CategoryChoiceGroup group;
  final String? selectedKey;
  final Color accentColor;
  final ValueChanged<MenudoCategory> onSelected;

  const _CategoryChoiceGroupSection({
    required this.group,
    required this.selectedKey,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final parent = group.parent;
    final groupColor = parent?.color ?? accentColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: groupColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  parent?.icono ?? MenudoCupertinoIcons.layoutGrid,
                  color: groupColor,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  parent?.nombre ?? 'Sin grupo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: colors.textMain,
                  ),
                ),
              ),
              Text(
                '${group.categories.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 360 ? 2 : 3;
              final spacing = 10.0;
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final category in group.categories)
                    _CategoryChoiceTile(
                      width: tileWidth,
                      category: category,
                      parentColor: groupColor,
                      isSelected: category.slug == selectedKey,
                      onTap: () => onSelected(category),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryChoiceTile extends StatelessWidget {
  final double width;
  final MenudoCategory category;
  final Color parentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChoiceTile({
    required this.width,
    required this.category,
    required this.parentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: MenudoGestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? category.color.withValues(alpha: 0.16)
                : context.menudo.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? category.color.withValues(alpha: 0.55)
                  : parentColor.withValues(alpha: 0.12),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      category.icono,
                      color: category.color,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: isSelected ? 1 : 0,
                    child: Icon(
                      MenudoCupertinoIcons.checkCircle,
                      size: 18,
                      color: category.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                category.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: context.menudo.textMain,
                  height: 1.08,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isPlaceholder;

  const _FieldCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: () {
        MenudoHaptics.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: context.menudo.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaceholder
                ? AppColors.o5.withValues(alpha: 0.28)
                : context.menudo.border,
            width: isPlaceholder ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: (32),
              height: (32),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: (16), color: color),
            ),
            SizedBox(width: (12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: context.menudo.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isPlaceholder
                          ? context.menudo.textMuted
                          : context.menudo.textMain,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6),
            Icon(
              MenudoCupertinoIcons.chevronRight,
              size: (15),
              color: context.menudo.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SecondaryActionCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: () {
        MenudoHaptics.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: context.menudo.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.menudo.border),
        ),
        child: Row(
          children: [
            Container(
              width: (30),
              height: (30),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: (15), color: color),
            ),
            SizedBox(width: (10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: context.menudo.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.menudo.textMain,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(MenudoCupertinoIcons.pencil, size: (12), color: color),
                  SizedBox(width: (5)),
                  Text(
                    'Editar',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: color,
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

class _Numpad extends StatelessWidget {
  final Function(String) onKeyTap;

  const _Numpad({required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.height < 900 || media.size.width < 420;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: compact ? 2.7 : 2.2,
      mainAxisSpacing: compact ? 8 : 9,
      crossAxisSpacing: compact ? 8 : 9,
      children: [...'123456789.0'.split(''), 'backspace']
          .map((key) => _NumpadKey(value: key, onTap: () => onKeyTap(key)))
          .toList(),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _NumpadKey({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBack = value == 'backspace';
    return MenudoGestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        decoration: BoxDecoration(
          color: context.menudo.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.menudo.border.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: context.menudo.background.withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isBack
            ? Icon(
                MenudoCupertinoIcons.delete,
                color: context.menudo.textMain,
                size: (22),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.menudo.textMain,
                ),
              ),
      ),
    );
  }
}

class _AccountPickerSheet extends StatelessWidget {
  final List<WalletAccount> accounts;
  final String title;
  final int? selectedId;
  final int? excludeId;

  const _AccountPickerSheet({
    required this.accounts,
    required this.title,
    this.selectedId,
    this.excludeId,
  });

  @override
  Widget build(BuildContext context) {
    final visibleAccounts =
        accounts.where((wallet) => wallet.id != excludeId).toList()
          ..sort((a, b) {
            if (a.esDefault != b.esDefault) {
              return a.esDefault ? -1 : 1;
            }
            return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
          });

    return Container(
      decoration: BoxDecoration(
        color: context.menudo.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: context.menudo.border,
              borderRadius: BorderRadius.circular(3),
            ),
            margin: const EdgeInsets.only(bottom: 24),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.menudo.textMain,
            ),
          ),
          SizedBox(height: (24)),
          ...visibleAccounts.map(
            (wallet) => MenudoGestureDetector(
              onTap: () {
                MenudoHaptics.light();
                Navigator.pop(context, wallet.id);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: wallet.id == selectedId
                      ? context.menudo.primary
                      : context.menudo.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      wallet.icono,
                      color: wallet.id == selectedId
                          ? context.menudo.surface
                          : wallet.color,
                    ),
                    SizedBox(width: (16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  wallet.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: wallet.id == selectedId
                                        ? context.menudo.surface
                                        : context.menudo.textMain,
                                  ),
                                ),
                              ),
                              if (wallet.esDefault) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: wallet.id == selectedId
                                        ? context.menudo.surface.withValues(
                                            alpha: 0.16,
                                          )
                                        : context.menudo.successLight,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'PRINCIPAL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: wallet.id == selectedId
                                          ? context.menudo.surface
                                          : context.menudo.textMain,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 3),
                          Text(
                            wallet.tipo == 'deudas'
                                ? 'Deuda o prestamo'
                                : wallet.tipo == 'gastos'
                                ? 'Tarjeta o efectivo'
                                : 'Cuenta bancaria o ahorro',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: wallet.id == selectedId
                                  ? context.menudo.surface.withValues(
                                      alpha: 0.76,
                                    )
                                  : context.menudo.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (wallet.tipo == 'deudas' && wallet.id != selectedId)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: context.menudo.dangerLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'DEUDA',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.r5,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    if (wallet.id == selectedId)
                      Icon(
                        MenudoCupertinoIcons.check,
                        color: context.menudo.surface,
                        size: (18),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetPickerSheet extends StatelessWidget {
  final List<MenudoBudget> budgets;
  final int? selectedId;

  const _BudgetPickerSheet({required this.budgets, this.selectedId});

  @override
  Widget build(BuildContext context) {
    final sortedBudgets = [...budgets]
      ..sort((a, b) {
        if (a.activo != b.activo) {
          return a.activo ? -1 : 1;
        }
        return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      });

    return Container(
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: context.menudo.border,
                  borderRadius: BorderRadius.circular(3),
                ),
                margin: const EdgeInsets.only(bottom: 24),
              ),
              Text(
                'Presupuesto opcional',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: context.menudo.textMain,
                ),
              ),
              SizedBox(height: (24)),
              _BudgetChoiceTile(
                label: 'General',
                subtitle: 'Guardar este movimiento como actividad general.',
                selected: selectedId == null,
                onTap: () {
                  MenudoHaptics.light();
                  Navigator.pop(context, 0);
                },
              ),
              SizedBox(height: (12)),
              ...sortedBudgets.map(
                (budget) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BudgetChoiceTile(
                    label: budget.nombre,
                    subtitle: budget.activo
                        ? 'Presupuesto activo'
                        : 'Disponible',
                    selected: budget.id == selectedId,
                    onTap: () {
                      MenudoHaptics.light();
                      Navigator.pop(context, budget.id);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetChoiceTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _BudgetChoiceTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? context.menudo.primary : context.menudo.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? context.menudo.surface.withValues(alpha: 0.14)
                    : context.menudo.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                MenudoCupertinoIcons.layoutGrid,
                size: (18),
                color: selected
                    ? context.menudo.surface
                    : context.menudo.textMain,
              ),
            ),
            SizedBox(width: (14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? context.menudo.surface
                          : context.menudo.textMain,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? context.menudo.surface.withValues(alpha: 0.76)
                          : context.menudo.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            if (selected)
              Icon(
                MenudoCupertinoIcons.check,
                color: context.menudo.surface,
                size: (18),
              ),
          ],
        ),
      ),
    );
  }
}
