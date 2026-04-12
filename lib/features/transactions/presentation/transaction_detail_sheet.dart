import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../controllers/transaction_controller.dart';
import '../../../core/data/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_presenter.dart';
import '../../auth/auth_state.dart';
import '../../budgets/budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../quick_log/presentation/register_transaction_sheet.dart';
import '../../wallet/providers/wallet_providers.dart';
import 'transaction_presentation_utils.dart';

class TransactionDetailSheet extends ConsumerWidget {
  final MenudoTransaction transaction;
  final int? contextWalletId;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    this.contextWalletId,
  });

  String fmt(double val, {String currency = 'DOP'}) {
    final prefix = currency == 'USD' ? 'US\$' : 'RD\$';
    return "$prefix${val.toInt().toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]},')}";
  }

  MenudoBudget? _findBudget(
    List<MenudoBudget> budgets,
    MenudoTransaction transaction,
    MenudoBudget? selectedBudget,
  ) {
    if (transaction.budgetId != null) {
      for (final budget in budgets) {
        if (budget.id == transaction.budgetId) return budget;
      }
    }
    return selectedBudget;
  }

  MenudoCategory? _findCategoryBySlug(
    List<MenudoCategory> categories,
    String slug,
  ) {
    for (final category in categories) {
      if (category.slug == slug) return category;
    }
    return null;
  }

  MenudoCategory? _findCategoryById(
    List<MenudoCategory> categories,
    int? categoryId,
  ) {
    if (categoryId == null) return null;
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final budgets = ref.watch(effectiveBudgetsProvider);
    final selectedBudget = ref.watch(selectedBudgetProvider);
    final categories = ref.watch(effectiveCategoriesProvider);
    final wallets = ref.watch(effectiveWalletsProvider);
    final authState = ref.watch(authProvider);

    final activeBudget = _findBudget(budgets, t, selectedBudget);
    final budgetCat = activeBudget?.cats[t.catKey];
    final resolvedCategory =
        _findCategoryBySlug(categories, t.catKey) ??
        _findCategoryById(categories, t.categoryId);
    final parentCategory = resolvedCategory?.categoriaParadreId != null
        ? _findCategoryById(categories, resolvedCategory!.categoriaParadreId)
        : resolvedCategory;
    final childCategory = resolvedCategory?.categoriaParadreId != null
        ? resolvedCategory
        : null;
    final presentation = buildTransactionPresentation(
      t,
      wallets,
      contextWalletId: contextWalletId,
    );

    final String catLabel =
        budgetCat?.label ??
        resolvedCategory?.nombre ??
        (t.catKey.isEmpty
            ? 'Sin categoría'
            : t.catKey[0].toUpperCase() + t.catKey.substring(1));
    final IconData catIcon =
        budgetCat?.icono ?? resolvedCategory?.icono ?? t.icono;
    final Color catColor =
        budgetCat?.color ?? resolvedCategory?.color ?? AppColors.g4;

    final bool isTransfer = t.tipo == 'transferencia';
    final bool isGasto = t.tipo == 'gasto';
    final Color amountColor = presentation.amountColor;
    final String amountPrefix = presentation.prefix;
    final currentUserId = int.tryParse(authState.userId ?? '');
    final performerLabel = (t.userName != null && t.userName!.trim().isNotEmpty)
        ? t.userName!.trim()
        : (currentUserId != null && t.usuarioId == currentUserId ? 'Tú' : null);
    final String transferBadgeLabel = contextWalletId == null
        ? 'Transferencia'
        : (presentation.destinationWallet?.id == contextWalletId &&
                  presentation.destinationWallet?.tipo == 'deudas'
              ? 'Abono'
              : (amountPrefix == '+' ? 'Entrada' : 'Salida'));
    final bool isSharedBudget =
        (activeBudget?.miembros.length ?? 0) > 1 ||
        activeBudget?.espacioId != null;
    final String? accountLabel =
        presentation.sourceWallet?.nombre ??
        presentation.destinationWallet?.nombre;

    final parts = t.dateString.split('-');
    final months = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final int monthIdx = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final String formattedDate = parts.length == 3
        ? "${int.tryParse(parts[2]) ?? parts[2]} de ${months[monthIdx]} de ${parts[0]}"
        : t.dateString;
    final String categoryPathLabel =
        childCategory != null && parentCategory != null
        ? '${parentCategory.nombre} · ${childCategory.nombre}'
        : catLabel;
    final String summaryLabel = isTransfer
        ? transferBadgeLabel
        : (isGasto ? 'Gasto' : 'Ingreso');
    final String summaryTitle = isTransfer
        ? presentation.routeLabel
        : categoryPathLabel;
    final String? summaryDescription =
        t.desc.trim().isEmpty || t.desc.trim() == summaryTitle
        ? null
        : t.desc.trim();
    final String formattedAmount = amountPrefix.isEmpty
        ? fmt(t.monto.abs(), currency: t.moneda)
        : "$amountPrefix${fmt(t.monto.abs(), currency: t.moneda)}";
    final summaryColor = isTransfer
        ? AppColors.b5
        : _mix(amountColor, catColor, 0.4);
    final summaryIcon = isTransfer ? LucideIcons.arrowRightLeft : catIcon;

    final detailRows = <_SimpleDetailRowData>[
      if (!isTransfer)
        _SimpleDetailRowData(
          icon: parentCategory?.icono ?? catIcon,
          iconColor: parentCategory?.color ?? catColor,
          label: 'Categoría',
          value: categoryPathLabel,
        ),
      if (isTransfer)
        _SimpleDetailRowData(
          icon: LucideIcons.arrowUpFromLine,
          iconColor: AppColors.e8,
          label: 'Origen',
          value: presentation.sourceWallet?.nombre ?? 'No registrada',
        ),
      if (isTransfer)
        _SimpleDetailRowData(
          icon: LucideIcons.arrowDownToLine,
          iconColor: AppColors.e6,
          label: 'Destino',
          value: presentation.destinationWallet?.nombre ?? 'No registrada',
        ),
      if (!isTransfer && accountLabel != null)
        _SimpleDetailRowData(
          icon: LucideIcons.wallet,
          iconColor: AppColors.b5,
          label: 'Cuenta',
          value: accountLabel,
        ),
      _SimpleDetailRowData(
        icon: LucideIcons.calendarDays,
        iconColor: AppColors.o5,
        label: 'Fecha',
        value: formattedDate,
      ),
      if (activeBudget != null)
        _SimpleDetailRowData(
          icon: isSharedBudget ? LucideIcons.users : LucideIcons.layoutGrid,
          iconColor: isSharedBudget ? AppColors.e6 : AppColors.p5,
          label: 'Presupuesto',
          value: activeBudget.nombre,
        ),
      if (performerLabel != null && (isSharedBudget || t.usuarioId != null))
        _SimpleDetailRowData(
          icon: LucideIcons.user,
          iconColor: AppColors.o5,
          label: 'Hecho por',
          value: performerLabel,
        ),
    ];

    Future<void> deleteTransaction() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Eliminar movimiento'),
          content: const Text(
            'Esta acción eliminará el movimiento de tu historial.',
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

      if (confirm != true || !context.mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      try {
        await ref
            .read(transactionControllerProvider.notifier)
            .deleteTransaction(t.id);
        if (!context.mounted) return;
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Movimiento eliminado'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (error) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(presentError(error)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.g0,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 5,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.g2,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _SimpleSummaryCard(
                          icon: summaryIcon,
                          iconColor: summaryColor,
                          label: summaryLabel,
                          title: summaryTitle,
                          amount: formattedAmount,
                          description: summaryDescription,
                        )
                        .animate()
                        .fadeIn(duration: 320.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 16),
                    _DetailSection(
                          title: 'Detalles',
                          child: _SimpleDetailList(rows: detailRows),
                        )
                        .animate()
                        .fadeIn(duration: 280.ms, delay: 100.ms)
                        .slideY(begin: 0.04, end: 0),
                    if (t.nota != null && t.nota!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _DetailSection(
                        title: 'Nota',
                        child: _NoteCard(
                          note: t.nota!.trim(),
                          accentColor: summaryColor,
                        ),
                      ).animate().fadeIn(duration: 280.ms, delay: 140.ms),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                useRootNavigator: true,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    RegisterTransactionSheet(transaction: t),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              decoration: BoxDecoration(
                                color: AppColors.e8,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.pencil,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Editar',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
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
                          child: Semantics(
                            label: 'Eliminar transaccion ${t.desc}',
                            button: true,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                deleteTransaction();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 17,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.r1,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.r5.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.trash2,
                                      size: 16,
                                      color: AppColors.r5,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Eliminar',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.r5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 280.ms, delay: 180.ms),
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

class _SimpleSummaryCard extends StatelessWidget {
  const _SimpleSummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.title,
    required this.amount,
    this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String title;
  final String amount;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.g4,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            amount,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: iconColor,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
              letterSpacing: -0.3,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.g5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SimpleDetailList extends StatelessWidget {
  const _SimpleDetailList({required this.rows});

  final List<_SimpleDetailRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _SimpleDetailRow(row: rows[i]),
            if (i != rows.length - 1)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.g1,
              ),
          ],
        ],
      ),
    );
  }
}

class _SimpleDetailRow extends StatelessWidget {
  const _SimpleDetailRow({required this.row});

  final _SimpleDetailRowData row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: row.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(row.icon, size: 17, color: row.iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.g4,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.e8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleDetailRowData {
  const _SimpleDetailRowData({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.accentColor});

  final String note;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor.withValues(alpha: 0.08), AppColors.g0],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.stickyNote, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.e8,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
