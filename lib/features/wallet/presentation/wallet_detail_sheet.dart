import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import '../../budgets/budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../quick_log/presentation/register_transaction_sheet.dart';
import '../../transactions/presentation/transaction_presentation_utils.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../providers/wallet_providers.dart';
import 'add_wallet_sheet.dart';

class _DefaultWalletToggle extends ConsumerStatefulWidget {
  final int walletId;
  const _DefaultWalletToggle({required this.walletId});

  @override
  ConsumerState<_DefaultWalletToggle> createState() =>
      _DefaultWalletToggleState();
}

class _DefaultWalletToggleState extends ConsumerState<_DefaultWalletToggle> {
  bool _isUpdating = false;

  WalletAccount? _findWallet(List<WalletAccount> wallets) {
    for (final wallet in wallets) {
      if (wallet.id == widget.walletId) {
        return wallet;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _findWallet(ref.watch(effectiveWalletsProvider));
    final isDefault = wallet?.esDefault ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDefault ? AppColors.e8.withValues(alpha: 0.3) : AppColors.g2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDefault ? AppColors.o1 : AppColors.g1,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.star,
                  size: 18,
                  color: isDefault ? AppColors.o5 : AppColors.g3,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cuenta principal",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.e8,
                      ),
                    ),
                    Text(
                      "Usar por defecto en transacciones",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.g4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: isDefault || _isUpdating
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        setState(() => _isUpdating = true);
                        try {
                          await ref
                              .read(walletNotifierProvider.notifier)
                              .setDefaultWallet(widget.walletId);
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error.toString()),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isUpdating = false);
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: isDefault ? AppColors.e1 : AppColors.e8,
                  foregroundColor: isDefault ? AppColors.e8 : Colors.white,
                  disabledBackgroundColor: AppColors.e1,
                  disabledForegroundColor: AppColors.e8,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isDefault
                      ? 'Principal'
                      : _isUpdating
                      ? 'Guardando...'
                      : 'Marcar',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (isDefault)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 14, color: AppColors.e6),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Esta cuenta aparecerá seleccionada automáticamente al registrar gastos o ingresos.",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.e6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
        ],
      ),
    );
  }
}

class _NetWorthWalletToggle extends ConsumerStatefulWidget {
  const _NetWorthWalletToggle({required this.walletId});

  final int walletId;

  @override
  ConsumerState<_NetWorthWalletToggle> createState() =>
      _NetWorthWalletToggleState();
}

class _NetWorthWalletToggleState extends ConsumerState<_NetWorthWalletToggle> {
  bool _isUpdating = false;

  WalletAccount? _findWallet(List<WalletAccount> wallets) {
    for (final wallet in wallets) {
      if (wallet.id == widget.walletId) {
        return wallet;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _findWallet(ref.watch(effectiveWalletsProvider));
    final isIncluded = wallet?.incluirEnPatrimonio ?? true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isIncluded ? AppColors.e1 : AppColors.g2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isIncluded ? AppColors.e1 : AppColors.g1,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIncluded
                      ? Icons.pie_chart_rounded
                      : Icons.remove_circle_outline_rounded,
                  size: 18,
                  color: isIncluded ? AppColors.e8 : AppColors.g5,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Incluir en patrimonio",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.e8,
                      ),
                    ),
                    Text(
                      isIncluded
                          ? "Esta wallet cuenta en el patrimonio neto."
                          : "Esta wallet queda fuera del patrimonio neto.",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.g4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: wallet == null || _isUpdating
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        setState(() => _isUpdating = true);
                        try {
                          await ref
                              .read(walletNotifierProvider.notifier)
                              .updateWallet(
                                wallet.copyWith(
                                  incluirEnPatrimonio:
                                      !wallet.incluirEnPatrimonio,
                                ),
                              );
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error.toString()),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isUpdating = false);
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: isIncluded ? AppColors.g1 : AppColors.e8,
                  foregroundColor: isIncluded ? AppColors.g5 : Colors.white,
                  disabledBackgroundColor: AppColors.g1,
                  disabledForegroundColor: AppColors.g4,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isUpdating
                      ? 'Guardando...'
                      : isIncluded
                      ? 'Excluir'
                      : 'Incluir',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isIncluded ? AppColors.e0 : AppColors.g0,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              isIncluded
                  ? 'Se usará en la tarjeta de patrimonio y en los totales de activos/deudas.'
                  : 'Útil para tarjetas de crédito u otras wallets que no deben sumarse al patrimonio.',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.g5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderMetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.88)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class WalletDetailSheet extends ConsumerWidget {
  final WalletAccount wallet;
  final void Function(Object error)? onError;

  const WalletDetailSheet({super.key, required this.wallet, this.onError});

  String fmt(double val, {String currency = 'DOP'}) {
    final prefix = currency == 'USD' ? 'US\$' : 'RD\$';
    final amount = val.abs().toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$prefix$amount';
  }

  MenudoCategory? _findCategory(List<MenudoCategory> categories, String slug) {
    for (final category in categories) {
      if (category.slug == slug) return category;
    }
    return null;
  }

  WalletAccount? _findWallet(List<WalletAccount> wallets, int walletId) {
    for (final wallet in wallets) {
      if (wallet.id == walletId) {
        return wallet;
      }
    }
    return null;
  }

  void _showError(BuildContext context, Object error) {
    if (onError != null) {
      onError!(error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(effectiveWalletsProvider);
    final w = _findWallet(wallets, wallet.id) ?? wallet;
    final bool isNegative = w.saldo < 0;

    // Type labels
    final Map<String, String> tipoLabels = {
      'cuentas': 'Cuenta principal',
      'gastos': 'Tarjeta o efectivo',
      'deudas': 'Préstamo o deuda',
    };

    final activeBudget = ref.watch(selectedBudgetProvider);
    final categories = ref.watch(effectiveCategoriesProvider);
    final txns = [...ref.watch(selectedBudgetPeriodTransactionsProvider)]
      ..retainWhere((t) => t.fromAccountId == w.id || t.toAccountId == w.id)
      ..sort((a, b) => b.dateString.compareTo(a.dateString));
    final recentTxns = txns.take(5).toList();

    Future<void> openTransfer() async {
      HapticFeedback.lightImpact();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RegisterTransactionSheet(
          initialType: 'transferencia',
          initialFromAccountId: w.id,
        ),
      );
    }

    Future<void> openEditWallet() async {
      HapticFeedback.lightImpact();
      final updatedWallet = await showModalBottomSheet<WalletAccount>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddWalletSheet(initialWallet: w),
      );

      if (updatedWallet == null) return;

      try {
        await ref
            .read(walletNotifierProvider.notifier)
            .updateWallet(updatedWallet);
        if (context.mounted) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Cuenta actualizada'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          _showError(context, error);
        }
      }
    }

    Future<void> deleteWallet() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Eliminar cuenta'),
          content: Text(
            'Eliminarás "${w.nombre}" de tu cartera. Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.r5,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      try {
        await ref.read(walletNotifierProvider.notifier).removeWallet(w.id);
        if (context.mounted) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Cuenta eliminada'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          _showError(context, error);
        }
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.g0,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Dark header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: const BoxDecoration(
                  color: AppColors.e8,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        height: 5,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    // Close + title row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.arrowLeft,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "Detalle de cuenta",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: deleteWallet,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.trash2,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Account icon + name
                    Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: w.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Icon(w.icono, size: 28, color: Colors.white),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms),

                    const SizedBox(height: 12),

                    Text(
                      w.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms, delay: 50.ms),

                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tipoLabels[w.tipo] ?? w.tipo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                    if (w.esDefault)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.o5,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.star,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Cuenta principal',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 120.ms),

                    if (!w.incluirEnPatrimonio)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Fuera del patrimonio',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 140.ms),

                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _HeaderMetaPill(
                          icon: LucideIcons.badgeDollarSign,
                          label: w.moneda,
                        ),
                        if (activeBudget != null)
                          _HeaderMetaPill(
                            icon: LucideIcons.layoutGrid,
                            label: activeBudget.nombre,
                          ),
                        _HeaderMetaPill(
                          icon: w.incluirEnPatrimonio
                              ? LucideIcons.pieChart
                              : LucideIcons.minusCircle,
                          label: w.incluirEnPatrimonio
                              ? 'Cuenta en patrimonio'
                              : 'Fuera patrimonio',
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms, delay: 145.ms),

                    const SizedBox(height: 16),

                    // Balance
                    Text(
                      "SALDO ACTUAL",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                    const SizedBox(height: 4),
                    Text(
                          isNegative
                              ? '-${fmt(w.saldo.abs(), currency: w.moneda)}'
                              : fmt(w.saldo.abs(), currency: w.moneda),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: isNegative
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFF6EE7B7),
                            letterSpacing: -1.5,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 400.ms,
                          delay: 200.ms,
                        ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    // Action buttons
                    Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: openTransfer,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.o5,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      const BoxShadow(
                                        color: Color(0x44F97316),
                                        blurRadius: 16,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        LucideIcons.arrowLeftRight,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Transferir",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: openEditWallet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFF3F4F6),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        LucideIcons.pencil,
                                        size: 16,
                                        color: AppColors.e8,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Editar",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.e8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 250.ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 350.ms,
                          delay: 250.ms,
                        ),

                    const SizedBox(height: 20),

                    // Default Wallet Toggle
                    _DefaultWalletToggle(walletId: w.id),

                    const SizedBox(height: 20),

                    _NetWorthWalletToggle(walletId: w.id),

                    const SizedBox(height: 20),

                    // Recent transactions header
                    const Text(
                      "Últimas transacciones",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.e8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeBudget == null
                          ? "Movimientos recientes de esta cuenta."
                          : "Movimientos recientes dentro de ${activeBudget.nombre}.",
                      style: const TextStyle(fontSize: 12, color: AppColors.g4),
                    ),
                    const SizedBox(height: 12),

                    if (recentTxns.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFF3F4F6),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Text(
                          "No hay movimientos para esta cuenta en el presupuesto seleccionado.",
                          style: TextStyle(fontSize: 13, color: AppColors.g4),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: 350.ms)
                    else
                      Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFF3F4F6),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              children: List.generate(recentTxns.length, (i) {
                                final t = recentTxns[i];
                                final ci = activeBudget?.cats[t.catKey];
                                final presentation =
                                    buildTransactionPresentation(
                                      t,
                                      wallets,
                                      contextWalletId: w.id,
                                    );
                                final category = _findCategory(
                                  categories,
                                  t.catKey,
                                );
                                final dayStr = t.dateString.split('-');
                                final months = [
                                  '',
                                  'ene',
                                  'feb',
                                  'mar',
                                  'abr',
                                  'may',
                                  'jun',
                                  'jul',
                                  'ago',
                                  'sep',
                                  'oct',
                                  'nov',
                                  'dic',
                                ];
                                final monthLabel =
                                    months[int.tryParse(dayStr[1]) ?? 0];
                                final subtitleText = t.tipo == 'transferencia'
                                    ? '${presentation.routeLabel} · ${dayStr[2]} $monthLabel'
                                    : '${ci?.label ?? category?.nombre ?? t.catKey} · ${dayStr[2]} $monthLabel';
                                final amountText = presentation.prefix.isEmpty
                                    ? fmt(t.monto.abs(), currency: t.moneda)
                                    : '${presentation.prefix}${fmt(t.monto.abs(), currency: t.moneda)}';

                                return Column(
                                  children: [
                                    if (i > 0)
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFFF3F4F6),
                                        indent: 68,
                                        endIndent: 16,
                                      ),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) =>
                                              TransactionDetailSheet(
                                                transaction: t,
                                                contextWalletId: w.id,
                                              ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color:
                                                    (ci?.color ??
                                                            category?.color ??
                                                            AppColors.g4)
                                                        .withValues(
                                                          alpha: 0.13,
                                                        ),
                                                borderRadius:
                                                    BorderRadius.circular(13),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                ci?.icono ??
                                                    category?.icono ??
                                                    t.icono,
                                                size: 19,
                                                color:
                                                    ci?.color ??
                                                    category?.color ??
                                                    AppColors.g4,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    t.desc,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.e8,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    subtitleText,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.g4,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              amountText,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: presentation.amountColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 350.ms)
                          .slideY(
                            begin: 0.04,
                            end: 0,
                            duration: 400.ms,
                            delay: 350.ms,
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
