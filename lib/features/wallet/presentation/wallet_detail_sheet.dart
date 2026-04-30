import 'dart:async';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import 'package:financeproject/shared/widgets/menudo_destructive_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../core/utils/formatters.dart';
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
    final colors = context.menudo;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDefault
              ? colors.primary.withValues(alpha: 0.3)
              : colors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDefault
                      ? context.menudo.primaryLight
                      : context.menudo.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  MenudoCupertinoIcons.star,
                  size: (18),
                  color: isDefault ? AppColors.o5 : context.menudo.textMuted,
                ),
              ),
              SizedBox(width: (14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cuenta preferida",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textMain,
                      ),
                    ),
                    Text(
                      "La usaremos primero cuando registres un movimiento.",
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
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
                        MenudoHaptics.medium();
                        setState(() => _isUpdating = true);
                        try {
                          await ref
                              .read(walletNotifierProvider.notifier)
                              .setDefaultWallet(widget.walletId);
                          if (!context.mounted) return;
                          MenudoHaptics.success();
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(presentError(error)),
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
                  backgroundColor: isDefault
                      ? context.menudo.successLight
                      : context.menudo.textMain,
                  foregroundColor: isDefault
                      ? context.menudo.primary
                      : context.menudo.surface,
                  disabledBackgroundColor: context.menudo.successLight,
                  disabledForegroundColor: context.menudo.textMain,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isDefault
                      ? 'Lista'
                      : _isUpdating
                      ? 'Guardando...'
                      : 'Elegir',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
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
    final colors = context.menudo;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isIncluded ? context.menudo.successLight : colors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isIncluded
                      ? context.menudo.successLight
                      : context.menudo.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIncluded
                      ? MenudoCupertinoIcons.pie_chart_rounded
                      : MenudoCupertinoIcons.remove_circle_outline_rounded,
                  size: (18),
                  color: isIncluded
                      ? context.menudo.primary
                      : context.menudo.textSecondary,
                ),
              ),
              SizedBox(width: (14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Patrimonio",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textMain,
                      ),
                    ),
                    Text(
                      isIncluded
                          ? "La tomamos en cuenta en tu total."
                          : "La dejamos fuera de tu total.",
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
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
                        MenudoHaptics.medium();
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
                          if (!context.mounted) return;
                          MenudoHaptics.success();
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(presentError(error)),
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
                  backgroundColor: isIncluded
                      ? context.menudo.surface
                      : context.menudo.textMain,
                  foregroundColor: isIncluded
                      ? context.menudo.textSecondary
                      : context.menudo.surface,
                  disabledBackgroundColor: context.menudo.surface,
                  disabledForegroundColor: context.menudo.textMuted,
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
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
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

  String _effectiveCurrency(String? currency) {
    final fallback = AppFormattingPreferences.currencyCode;
    final normalized = currency?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return fallback;
    if (normalized == 'DOP' && fallback != 'DOP') return fallback;
    return normalized;
  }

  String fmt(double val, {String? currency}) {
    return formatMoney(val, currency: _effectiveCurrency(currency));
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
        content: Text(presentError(error)),
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
      'cuentas': 'Cuenta',
      'gastos': 'Tarjeta o efectivo',
      'deudas': 'Deuda',
    };

    final categories = ref.watch(effectiveCategoriesProvider);
    final txns = [...ref.watch(effectiveTransactionsProvider)]
      ..retainWhere((t) => t.fromAccountId == w.id || t.toAccountId == w.id)
      ..sort((a, b) => b.dateString.compareTo(a.dateString));
    final recentTxns = txns.take(5).toList();

    Future<void> openTransfer() async {
      MenudoHaptics.light();
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      final rootContext = rootNavigator.context;
      Navigator.pop(context);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!rootContext.mounted) return;
      await showModalBottomSheet<void>(
        context: rootContext,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RegisterTransactionSheet(
          initialType: 'transferencia',
          initialFromAccountId: w.id,
        ),
      );
    }

    Future<void> openEditWallet() async {
      MenudoHaptics.light();
      final walletNotifier = ref.read(walletNotifierProvider.notifier);
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      final rootContext = rootNavigator.context;
      Navigator.pop(context);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!rootContext.mounted) return;
      final updatedWallet = await showModalBottomSheet<WalletAccount>(
        context: rootContext,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddWalletSheet(initialWallet: w),
      );

      if (updatedWallet == null) return;

      try {
        await walletNotifier.updateWallet(updatedWallet);
        if (rootContext.mounted) {
          MenudoHaptics.success();
        }
      } catch (error) {
        if (rootContext.mounted) {
          _showError(rootContext, error);
        }
      }
    }

    Future<void> deleteWallet() async {
      final confirmed = await MenudoDestructiveDialog.show(
        context: context,
        title: 'Eliminar cuenta',
        message:
            'Eliminarás "${w.nombre}" de tu cartera y ya no podrás recuperarla.',
        confirmLabel: 'Sí, eliminar',
      );

      if (confirmed != true) return;
      if (!context.mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      Future<void> restoreWallet() async {
        try {
          await ref
              .read(walletNotifierProvider.notifier)
              .addWallet(
                WalletAccount(
                  id: 0,
                  nombre: w.nombre,
                  tipo: w.tipo,
                  saldo: w.saldo,
                  color: w.color,
                  icono: w.icono,
                  moneda: w.moneda,
                  incluirEnPatrimonio: w.incluirEnPatrimonio,
                ),
              );
          MenudoHaptics.success();
        } catch (error) {
          if (context.mounted) {
            _showError(context, error);
          }
        }
      }

      try {
        await ref.read(walletNotifierProvider.notifier).removeWallet(w.id);
        if (context.mounted) {
          MenudoHaptics.success();
          Navigator.pop(context);

          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('"${w.nombre}" fue eliminada.'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 6),
                action: SnackBarAction(
                  label: 'Deshacer',
                  onPressed: () {
                    unawaited(restoreWallet());
                  },
                ),
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
          decoration: BoxDecoration(
            color: context.menudo.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Dark header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  color: context.menudo.hero,
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
                        MenudoGestureDetector(
                          onTap: () {
                            MenudoHaptics.light();
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
                            child: Icon(
                              MenudoCupertinoIcons.arrowLeft,
                              color: Colors.white,
                              size: (18),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Detalle de cuenta",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        MenudoGestureDetector(
                          onTap: deleteWallet,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              MenudoCupertinoIcons.trash2,
                              color: Colors.white,
                              size: (18),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: (20)),

                    // Account icon + name
                    Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: w.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Icon(w.icono, size: (28), color: Colors.white),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms),

                    SizedBox(height: (12)),

                    Text(
                      w.nombre,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms, delay: 50.ms),

                    SizedBox(height: 4),

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

                    SizedBox(height: (14)),

                    SizedBox(height: (16)),

                    // Balance
                    Text(
                      "SALDO",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                    SizedBox(height: 4),
                    Text(
                          isNegative
                              ? '-${fmt(w.saldo.abs(), currency: w.moneda)}'
                              : fmt(w.saldo.abs(), currency: w.moneda),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: isNegative
                                ? context.menudo.danger
                                : context.menudo.success,
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
                              child: MenudoGestureDetector(
                                onTap: openTransfer,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.o5,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x44F97316),
                                        blurRadius: 16,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        MenudoCupertinoIcons.arrowLeftRight,
                                        size: (16),
                                        color: context.menudo.surface,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Mover dinero",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: context.menudo.surface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: (10)),
                            Expanded(
                              child: MenudoGestureDetector(
                                onTap: openEditWallet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.menudo.surfaceElevated,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: context.menudo.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        MenudoCupertinoIcons.pencil,
                                        size: (16),
                                        color: context.menudo.textMain,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Editar cuenta",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: context.menudo.textMain,
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

                    SizedBox(height: (20)),

                    // Default Wallet Toggle
                    _DefaultWalletToggle(walletId: w.id),

                    SizedBox(height: (20)),

                    _NetWorthWalletToggle(walletId: w.id),

                    SizedBox(height: (20)),

                    // Recent transactions header
                    Text(
                      "Últimas transacciones",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.menudo.textMain,
                      ),
                    ),
                    SizedBox(height: (12)),

                    if (recentTxns.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.menudo.surface,
                          border: Border.all(color: context.menudo.border),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          "Todavía no hay movimientos en esta cuenta.",
                          style: TextStyle(
                            fontSize: 13,
                            color: context.menudo.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: 350.ms)
                    else
                      Container(
                            decoration: BoxDecoration(
                              color: context.menudo.surface,
                              border: Border.all(color: context.menudo.border),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              children: List.generate(recentTxns.length, (i) {
                                final t = recentTxns[i];
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
                                    : '${category?.nombre ?? t.catKey} · ${dayStr[2]} $monthLabel';
                                final amountText = presentation.prefix.isEmpty
                                    ? fmt(
                                        t.monto.abs(),
                                        currency: transactionCurrencyCode(t),
                                      )
                                    : '${presentation.prefix}${fmt(t.monto.abs(), currency: transactionCurrencyCode(t))}';

                                return Column(
                                  children: [
                                    if (i > 0)
                                      Divider(
                                        height: 1,
                                        thickness: 0.5,
                                        color: context.menudo.border,
                                        indent: 68,
                                        endIndent: 16,
                                      ),
                                    MenudoGestureDetector(
                                      onTap: () {
                                        MenudoHaptics.light();
                                        showModalBottomSheet(
                                          context: context,
                                          useRootNavigator: true,
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
                                                    (category?.color ??
                                                            context
                                                                .menudo
                                                                .textMuted)
                                                        .withValues(
                                                          alpha: 0.13,
                                                        ),
                                                borderRadius:
                                                    BorderRadius.circular(13),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                category?.icono ?? t.icono,
                                                size: (19),
                                                color:
                                                    category?.color ??
                                                    context.menudo.textMuted,
                                              ),
                                            ),
                                            SizedBox(width: (12)),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    t.desc,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: context
                                                          .menudo
                                                          .textMain,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    subtitleText,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: context
                                                          .menudo
                                                          .textSecondary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 8),
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
