import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/data/models.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_presenter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../../../shared/widgets/menudo_card.dart';
import '../../budgets/budget_providers.dart';
import '../../categories/presentation/category_picker_sheet.dart';
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
    extends ConsumerState<QuickExpenseShortcutSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  bool _isSaving = false;
  String? _selectedCategorySlug;
  String? _formMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryPickerSheet(
        initialCatKey: _selectedCategorySlug,
        allowedType: 'gasto',
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedCategorySlug = selected;
        _formMessage = null;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
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
      Navigator.of(context).pop(true);
    } catch (error) {
      _showError(presentError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final wallets = ref.watch(effectiveWalletsProvider);
    final defaultWallet = ref.watch(defaultWalletProvider);
    final categories = ref.watch(effectiveCategoriesProvider);
    final selectedCategory = categories
        .where((item) => item.slug == _selectedCategorySlug)
        .firstOrNull;
    final selectedParent = selectedCategory?.categoriaParadreId == null
        ? null
        : categories
              .where((item) => item.id == selectedCategory!.categoriaParadreId)
              .firstOrNull;
    final wallet = defaultWallet ?? (wallets.isNotEmpty ? wallets.first : null);
    final currency = wallet?.moneda ?? AppFormattingPreferences.currencyCode;
    final isCompact = media.size.height < 820;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: media.size.height * (isCompact ? 0.76 : 0.72),
        decoration: const BoxDecoration(
          color: AppColors.g0,
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
                  color: AppColors.g2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  media.padding.bottom + 18,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gasto rápido',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.e8,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      wallet == null
                          ? 'Necesitas una cuenta antes de registrar gastos.'
                          : 'Se guardará como gasto normal en ${wallet.nombre}.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.g4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    MenudoCard(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monto',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.g4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _amountCtrl,
                            focusNode: _amountFocus,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            onChanged: (_) {
                              if (_formMessage == null) return;
                              setState(() => _formMessage = null);
                            },
                            decoration: InputDecoration(
                              prefixText:
                                  '${formatMoney(0, currency: currency).replaceAll('0', '')} ',
                              prefixStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.g4,
                              ),
                              filled: true,
                              fillColor: AppColors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: AppColors.g2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: AppColors.g2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: AppColors.o5,
                                  width: 1.6,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.e8,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _pickCategory,
                      borderRadius: BorderRadius.circular(24),
                      child: MenudoCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color:
                                    selectedCategory?.color.withValues(
                                      alpha: 0.12,
                                    ) ??
                                    AppColors.e1,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                selectedCategory?.icono ?? LucideIcons.tags,
                                color: selectedCategory?.color ?? AppColors.e6,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Categoría',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.g4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    selectedCategory == null
                                        ? 'Elegir categoría'
                                        : selectedParent == null
                                        ? selectedCategory.nombre
                                        : '${selectedParent.nombre} / ${selectedCategory.nombre}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.e8,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              LucideIcons.chevronRight,
                              color: AppColors.g4,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    MenudoCard(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nota',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.g4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _noteCtrl,
                            textInputAction: TextInputAction.done,
                            minLines: 1,
                            maxLines: 3,
                            onChanged: (_) {
                              if (_formMessage == null) return;
                              setState(() => _formMessage = null);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: AppColors.g2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: AppColors.g2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: AppColors.o5,
                                  width: 1.6,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.e8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_formMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.r1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.r5.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          _formMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.r5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    MenudoButton(
                      label: _isSaving ? 'Guardando...' : 'Registrar gasto',
                      isFullWidth: true,
                      isDisabled: _isSaving || wallet == null,
                      onTap: _save,
                      icon: LucideIcons.plusCircle,
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        widget.source == 'transaction_automation'
                            ? 'Abierto desde una automatización.'
                            : 'También puedes abrir esto desde un acceso rápido del dispositivo.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.g4,
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
