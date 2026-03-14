import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/data/models.dart';
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
  String? _catKey;
  String? _nota;
  int? _fromAccountId;
  int? _toAccountId;
  bool _isSaving = false;

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
      if (selectedCategory != null && selectedCategory.tipo != nextType) {
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
    if (_isSaving || _amount.isEmpty) return;

    final amountValue = double.tryParse(_amount);
    if (amountValue == null || amountValue == 0) return;

    final budget = ref.read(selectedBudgetProvider);
    if (budget == null) {
      _showError(
        'Selecciona un presupuesto antes de registrar la transaccion.',
      );
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

    if (_catKey == null || _catKey!.isEmpty) {
      _showError('Selecciona una categoria antes de continuar.');
      return;
    }

    if (_fromAccountId == null ||
        !wallets.any((wallet) => wallet.id == _fromAccountId)) {
      _showError('Selecciona una cuenta valida.');
      return;
    }

    if (_selectedType == 'transferencia') {
      if (_toAccountId == null ||
          !wallets.any((wallet) => wallet.id == _toAccountId)) {
        _showError('Selecciona la cuenta destino de la transferencia.');
        return;
      }
      if (_toAccountId == _fromAccountId) {
        _showError('La cuenta origen y destino no pueden ser la misma.');
        return;
      }
    }

    final fallbackDescription = selectedCategory?.nombre ?? _catKey!;
    final transaction = MenudoTransaction(
      id: widget.transaction?.id ?? 0,
      dateString:
          widget.transaction?.dateString ??
          DateTime.now().toIso8601String().split('T').first,
      desc: _isEditing ? widget.transaction!.desc : fallbackDescription,
      catKey: _catKey!,
      budgetId: budget.id,
      categoryId: selectedCategory?.id,
      monto: _selectedType == 'ingreso' ? amountValue : -amountValue,
      tipo: _selectedType,
      icono:
          selectedCategory?.icono ??
          widget.transaction?.icono ??
          LucideIcons.circle,
      fromAccountId: _fromAccountId,
      toAccountId: _selectedType == 'transferencia' ? _toAccountId : null,
      nota: _nota,
      moneda: widget.transaction?.moneda ?? 'DOP',
    );

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  WalletAccount? _findWallet(int? id, List<WalletAccount> wallets) {
    if (id == null) return null;
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  String _accountName(int? id, List<WalletAccount> wallets) {
    if (id == null) return "Seleccionar";
    final fallback = wallets.isNotEmpty ? wallets.first : null;
    final wallet = _findWallet(id, wallets);
    return wallet?.nombre ?? fallback?.nombre ?? "Seleccionar";
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

  Widget _buildTransferContextCard(List<WalletAccount> wallets) {
    final fromWallet = _findWallet(_fromAccountId, wallets);
    final toWallet = _findWallet(_toAccountId, wallets);

    IconData icon = LucideIcons.arrowLeftRight;
    Color accent = AppColors.b5;
    String title = 'Transferencia entre wallets';
    String subtitle =
        'Mueve dinero entre cuentas, tarjetas y deudas según tu flujo real.';

    if (fromWallet != null && toWallet != null) {
      if (fromWallet.tipo == 'deudas' && toWallet.tipo != 'deudas') {
        icon = LucideIcons.arrowDownToLine;
        accent = AppColors.r5;
        title = 'Tomando dinero prestado';
        subtitle =
            'El monto entra en ${toWallet.nombre} y aumenta lo que debes en ${fromWallet.nombre}.';
      } else if (toWallet.tipo == 'deudas' && fromWallet.tipo != 'deudas') {
        icon = LucideIcons.badgeDollarSign;
        accent = AppColors.e6;
        title = 'Abonando a una deuda';
        subtitle =
            'El monto sale de ${fromWallet.nombre} y reduce lo que debes en ${toWallet.nombre}.';
      } else if (toWallet.tipo == 'deudas' && fromWallet.tipo == 'deudas') {
        icon = LucideIcons.scale;
        accent = AppColors.p5;
        title = 'Movimiento entre deudas';
        subtitle =
            'Esta transferencia cambia dónde queda registrada la obligación.';
      } else {
        title = 'Movimiento entre wallets';
        subtitle =
            'El dinero sale de ${fromWallet.nombre} y entra en ${toWallet.nombre}.';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18), width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.g5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCategory() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryPickerSheet(
        initialCatKey: _catKey,
        allowedType: _selectedType,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _catKey = selected);
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
    final amountValue = double.tryParse(_amount) ?? 0;
    final isTransfer = _selectedTypeIndex == 2;
    final wallets = ref.watch(effectiveWalletsProvider);
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
        ? "Seleccionar"
        : selectedParent == null
        ? selectedCategory.nombre
        : "${selectedParent.nombre} / ${selectedCategory.nombre}";

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                    label: 'Transfer.',
                    index: 2,
                    current: _selectedTypeIndex,
                    onTap: _setTypeIndex,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child:
                Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          isTransfer
                              ? 'RD\$'
                              : (_selectedTypeIndex == 1 ? '+RD\$' : '-RD\$'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _accentColor.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                              fontSize: 52,
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
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                if (isTransfer) _buildTransferContextCard(wallets),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.g2),
                  ),
                  child: Column(
                    children: [
                      if (isTransfer) ...[
                        _DetailRow(
                          icon: LucideIcons.arrowUpFromLine,
                          color: AppColors.e6,
                          label: "Origen",
                          value: _accountName(_fromAccountId, wallets),
                          onTap: () =>
                              _pickAccount(isFrom: true, wallets: wallets),
                        ),
                        _DetailRow(
                          icon: LucideIcons.arrowDownToLine,
                          color: AppColors.b5,
                          label: "Destino",
                          value: _accountName(_toAccountId, wallets),
                          onTap: () =>
                              _pickAccount(isFrom: false, wallets: wallets),
                        ),
                      ],
                      _DetailRow(
                        icon: LucideIcons.layoutGrid,
                        color: AppColors.e8,
                        label: "Presupuesto",
                        value:
                            ref.watch(selectedBudgetProvider)?.nombre ??
                            "Sin presupuesto",
                      ),
                      _DetailRow(
                        icon: LucideIcons.tag,
                        color: AppColors.o5,
                        label: "Categoría",
                        value: categoryLabel,
                        onTap: _pickCategory,
                      ),
                      if (!isTransfer)
                        _DetailRow(
                          icon: LucideIcons.landmark,
                          color: AppColors.b5,
                          label: "Cuenta",
                          value: _accountName(_fromAccountId, wallets),
                          onTap: () =>
                              _pickAccount(isFrom: true, wallets: wallets),
                        ),
                      _DetailRow(
                        icon: LucideIcons.fileText,
                        color: AppColors.p5,
                        label: "Nota",
                        value: _nota ?? "Opcional",
                        onTap: _showNoteDialog,
                      ),
                      _DetailRow(
                        icon: LucideIcons.calendar,
                        color: AppColors.e8,
                        label: "Fecha",
                        value: "Hoy",
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _Numpad(onKeyTap: _onKeyTap),
                const SizedBox(height: 32),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24 + MediaQuery.of(context).padding.bottom,
            ),
            child: MenudoButton(
              label: _isSaving
                  ? (_isEditing ? "ACTUALIZANDO..." : "REGISTRANDO...")
                  : (_isEditing ? "ACTUALIZAR" : "REGISTRAR"),
              isFullWidth: true,
              isDisabled: amountValue == 0 || _isSaving,
              onTap: () => _saveTransaction(),
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
          "Nota de transacción",
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
            hintText: "Escribe algo aquí...",
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
              setState(
                () =>
                    _nota = ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
              );
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 14),
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
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.e8,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(LucideIcons.chevronRight, size: 16, color: AppColors.g3),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              color: AppColors.g1,
              indent: 56,
              endIndent: 16,
            ),
        ],
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final Function(String) onKeyTap;

  const _Numpad({required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
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
