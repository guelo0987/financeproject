import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/data/models.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_presenter.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../budgets/budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../categories/presentation/category_picker_sheet.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';

class RegisterTransactionSheet extends ConsumerStatefulWidget {
  final MenudoTransaction? transaction;
  final String? initialType;
  final int? initialFromAccountId;

  const RegisterTransactionSheet({
    super.key,
    this.transaction,
    this.initialType,
    this.initialFromAccountId,
  });

  @override
  ConsumerState<RegisterTransactionSheet> createState() =>
      _RegisterTransactionSheetState();
}

class _RegisterTransactionSheetState
    extends ConsumerState<RegisterTransactionSheet> {
  String _amount = "";
  int _selectedTypeIndex = 0; // 0: Gasto, 1: Ingreso, 2: Transferencia
  int? _budgetId;
  String? _catKey;
  String? _nota;
  int? _fromAccountId;
  int? _toAccountId;
  bool _isSaving = false;
  String? _formMessage;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    if (!_isEditing && widget.initialType != null) {
      _selectedTypeIndex = switch (widget.initialType) {
        'ingreso' => 1,
        'transferencia' => 2,
        _ => 0,
      };
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

  Color get _accentColor {
    if (_selectedTypeIndex == 1) {
      return AppColors.e6;
    }
    if (_selectedTypeIndex == 2) {
      return AppColors.b5;
    }
    return AppColors.e8;
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
    HapticFeedback.lightImpact();
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
      budgetId: _budgetId,
      categoryId: _selectedType == 'transferencia'
          ? null
          : selectedCategory?.id,
      monto: _selectedType == 'ingreso' ? amountValue : -amountValue,
      tipo: _selectedType,
      icono:
          (_selectedType == 'transferencia'
              ? LucideIcons.arrowLeftRight
              : selectedCategory?.icono) ??
          widget.transaction?.icono ??
          LucideIcons.circle,
      fromAccountId: _fromAccountId,
      toAccountId: _selectedType == 'transferencia' ? _toAccountId : null,
      nota: _nota,
      moneda:
          widget.transaction?.moneda ?? AppFormattingPreferences.currencyCode,
    );

    HapticFeedback.mediumImpact();
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
      Navigator.pop(context);
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
    setState(() => _formMessage = message);
  }

  WalletAccount? _findWallet(int? id, List<WalletAccount> wallets) {
    if (id == null) return null;
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
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

  Future<void> _pickCategory() async {
    if (_selectedType == 'transferencia') return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryPickerSheet(
        initialCatKey: _catKey,
        allowedType: _selectedType,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _catKey = selected;
        _formMessage = null;
      });
    }
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
    HapticFeedback.lightImpact();
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

    return Container(
      height: media.size.height * (compactSheet ? 0.95 : 0.92),
      decoration: const BoxDecoration(
        color: AppColors.g0,
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
                color: AppColors.g2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              compactSheet ? 10 : 14,
              24,
              compactSheet ? 14 : 20,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.g1,
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
          Padding(
            padding: EdgeInsets.only(bottom: compactSheet ? 4 : 8),
            child: Column(
              children: [
                Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            isTransfer
                                ? 'RD\$'
                                : (_selectedTypeIndex == 1 ? '+RD\$' : '-RD\$'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: Text(
                            _formattedAmountDisplay(),
                            key: ValueKey('${_selectedTypeIndex}_$_amount'),
                            style: TextStyle(
                              fontSize: compactSheet ? 42 : 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2,
                              color: _accentColor,
                            ),
                          ),
                        ),
                      ],
                    )
                    .animate(key: ValueKey(_selectedTypeIndex))
                    .fadeIn()
                    .scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(height: 10),
                Text(
                  isTransfer
                      ? 'Mover entre tus cuentas'
                      : _selectedTypeIndex == 1
                      ? 'Registrar ingreso'
                      : 'Registrar gasto',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.g4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, compactSheet ? 4 : 2, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isTransfer) ...[
                    if (stackFieldPairs) ...[
                      _FieldCard(
                        icon: LucideIcons.arrowUpFromLine,
                        color: AppColors.e6,
                        label: 'Origen',
                        value: _accountName(_fromAccountId, wallets),
                        onTap: () =>
                            _pickAccount(isFrom: true, wallets: wallets),
                        isPlaceholder: _fromAccountId == null,
                      ),
                      const SizedBox(height: 12),
                      _FieldCard(
                        icon: LucideIcons.arrowDownToLine,
                        color: AppColors.b5,
                        label: 'Destino',
                        value: _accountName(_toAccountId, wallets),
                        onTap: () =>
                            _pickAccount(isFrom: false, wallets: wallets),
                        isPlaceholder: _toAccountId == null,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: _FieldCard(
                              icon: LucideIcons.arrowUpFromLine,
                              color: AppColors.e6,
                              label: 'Origen',
                              value: _accountName(_fromAccountId, wallets),
                              onTap: () =>
                                  _pickAccount(isFrom: true, wallets: wallets),
                              isPlaceholder: _fromAccountId == null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FieldCard(
                              icon: LucideIcons.arrowDownToLine,
                              color: AppColors.b5,
                              label: 'Destino',
                              value: _accountName(_toAccountId, wallets),
                              onTap: () =>
                                  _pickAccount(isFrom: false, wallets: wallets),
                              isPlaceholder: _toAccountId == null,
                            ),
                          ),
                        ],
                      ),
                  ] else ...[
                    if (stackFieldPairs) ...[
                      _FieldCard(
                        icon: LucideIcons.tag,
                        color: AppColors.o5,
                        label: 'Categoría',
                        value: categoryLabel,
                        onTap: _pickCategory,
                        isPlaceholder: selectedCategory == null,
                      ),
                      const SizedBox(height: 12),
                      _FieldCard(
                        icon: LucideIcons.landmark,
                        color: AppColors.b5,
                        label: 'Cuenta',
                        value: _accountName(_fromAccountId, wallets),
                        onTap: () =>
                            _pickAccount(isFrom: true, wallets: wallets),
                        isPlaceholder: _fromAccountId == null,
                      ),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _FieldCard(
                              icon: LucideIcons.tag,
                              color: AppColors.o5,
                              label: 'Categoría',
                              value: categoryLabel,
                              onTap: _pickCategory,
                              isPlaceholder: selectedCategory == null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FieldCard(
                              icon: LucideIcons.landmark,
                              color: AppColors.b5,
                              label: 'Cuenta',
                              value: _accountName(_fromAccountId, wallets),
                              onTap: () =>
                                  _pickAccount(isFrom: true, wallets: wallets),
                              isPlaceholder: _fromAccountId == null,
                            ),
                          ),
                        ],
                      ),
                  ],
                  const SizedBox(height: 12),
                  _InfoStrip(
                    isGeneralMode: _budgetId == null,
                    budgetName: budgetLabel,
                    onBudgetTap: budgets.isEmpty
                        ? null
                        : () => _pickBudget(budgets),
                  ),
                  const SizedBox(height: 12),
                  _SecondaryActionCard(
                    icon: LucideIcons.fileText,
                    color: AppColors.p5,
                    label: 'Nota',
                    value: noteLabel,
                    onTap: _showNoteDialog,
                  ),
                  const SizedBox(height: 16),
                ],
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
              color: AppColors.g0,
              border: Border(
                top: BorderSide(color: AppColors.g1.withValues(alpha: 0.9)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Numpad(onKeyTap: _onKeyTap),
                const SizedBox(height: 12),
                if (_formMessage != null || missingFields.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _formMessage != null
                          ? AppColors.negative.withValues(alpha: 0.08)
                          : AppColors.g1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _formMessage != null
                            ? AppColors.negative.withValues(alpha: 0.22)
                            : AppColors.g2,
                      ),
                    ),
                    child: Text(
                      _formMessage ??
                          'Falta ${_missingFieldsLabel(missingFields)} para registrar este movimiento.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _formMessage != null
                            ? AppColors.negative
                            : AppColors.g5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                MenudoButton(
                  label: _isSaving
                      ? "Guardando movimiento..."
                      : (_isEditing
                            ? "Guardar movimiento"
                            : "Registrar movimiento"),
                  isFullWidth: true,
                  isDisabled: !canSubmit,
                  onTap: () => _saveTransaction(),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Nota",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.e8,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: "Añade un detalle si lo necesitas",
            filled: true,
            fillColor: AppColors.g0,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: AppColors.g4),
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
            child: const Text(
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
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
              color: active ? AppColors.e8 : AppColors.g4,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.g2),
      ),
      child: _InfoStripItem(
        label: isGeneralMode ? 'Registro' : 'Presupuesto',
        value: budgetName,
        icon: isGeneralMode ? LucideIcons.fileText : LucideIcons.layoutGrid,
        color: isGeneralMode ? AppColors.e6 : AppColors.e8,
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
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.g4,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
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
                        color: color == AppColors.g5 ? AppColors.e8 : color,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: AppColors.g3,
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap!();
      },
      behavior: HitTestBehavior.opaque,
      child: child,
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaceholder
                ? AppColors.o5.withValues(alpha: 0.28)
                : AppColors.g2,
            width: isPlaceholder ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.g4,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isPlaceholder ? AppColors.g4 : AppColors.e8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronRight, size: 15, color: AppColors.g3),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.g2),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.g4,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.e8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Editar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
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
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.g2.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isBack
            ? const Icon(LucideIcons.delete, color: AppColors.e8, size: 22)
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.e8,
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
      decoration: const BoxDecoration(
        color: Colors.white,
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
              color: AppColors.g2,
              borderRadius: BorderRadius.circular(3),
            ),
            margin: const EdgeInsets.only(bottom: 24),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 24),
          ...visibleAccounts.map(
            (wallet) => GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, wallet.id);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: wallet.id == selectedId ? AppColors.e8 : AppColors.g0,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      wallet.icono,
                      color: wallet.id == selectedId
                          ? Colors.white
                          : wallet.color,
                    ),
                    const SizedBox(width: 16),
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
                                        ? Colors.white
                                        : AppColors.e8,
                                  ),
                                ),
                              ),
                              if (wallet.esDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: wallet.id == selectedId
                                        ? Colors.white.withValues(alpha: 0.16)
                                        : AppColors.e1,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'PRINCIPAL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: wallet.id == selectedId
                                          ? Colors.white
                                          : AppColors.e8,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
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
                                  ? Colors.white.withValues(alpha: 0.76)
                                  : AppColors.g4,
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
                            color: AppColors.r1,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
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
                      const Icon(
                        LucideIcons.check,
                        color: Colors.white,
                        size: 18,
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
      decoration: const BoxDecoration(
        color: Colors.white,
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
                  color: AppColors.g2,
                  borderRadius: BorderRadius.circular(3),
                ),
                margin: const EdgeInsets.only(bottom: 24),
              ),
              const Text(
                'Presupuesto opcional',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.e8,
                ),
              ),
              const SizedBox(height: 24),
              _BudgetChoiceTile(
                label: 'General',
                subtitle: 'Guardar este movimiento como actividad general.',
                selected: selectedId == null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context, 0);
                },
              ),
              const SizedBox(height: 12),
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
                      HapticFeedback.lightImpact();
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.e8 : AppColors.g0,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.14)
                    : AppColors.e1,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.layoutGrid,
                size: 18,
                color: selected ? Colors.white : AppColors.e8,
              ),
            ),
            const SizedBox(width: 14),
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
                      color: selected ? Colors.white : AppColors.e8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.76)
                          : AppColors.g4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (selected)
              const Icon(LucideIcons.check, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
