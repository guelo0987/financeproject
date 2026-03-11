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

  String fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

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

  MenudoCategory? _findCategory(List<MenudoCategory> categories, String slug) {
    for (final category in categories) {
      if (category.slug == slug) return category;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final budgets = ref.watch(effectiveBudgetsProvider);
    final selectedBudget = ref.watch(selectedBudgetProvider);
    final categories = ref.watch(effectiveCategoriesProvider);
    final wallets = ref.watch(effectiveWalletsProvider);

    final activeBudget = _findBudget(budgets, t, selectedBudget);
    final budgetCat = activeBudget?.cats[t.catKey];
    final category = _findCategory(categories, t.catKey);
    final presentation = buildTransactionPresentation(
      t,
      wallets,
      contextWalletId: contextWalletId,
    );

    final String catLabel =
        budgetCat?.label ??
        category?.nombre ??
        (t.catKey[0].toUpperCase() + t.catKey.substring(1));
    final IconData catIcon = budgetCat?.icono ?? category?.icono ?? t.icono;
    final Color catColor = budgetCat?.color ?? category?.color ?? AppColors.g4;

    final bool isTransfer = t.tipo == 'transferencia';
    final bool isGasto = t.tipo == 'gasto';
    final Color amountColor = presentation.amountColor;
    final String amountPrefix = presentation.prefix;
    final String transferBadgeLabel = contextWalletId == null
        ? 'Transferencia'
        : (presentation.destinationWallet?.id == contextWalletId &&
                  presentation.destinationWallet?.tipo == 'deudas'
              ? 'Abono'
              : (amountPrefix == '+' ? 'Entrada' : 'Salida'));
    final bool isSharedBudget =
        (activeBudget?.miembros.length ?? 0) > 1 ||
        activeBudget?.espacioId != null;
    final String accountLabel =
        presentation.sourceWallet?.nombre ??
        presentation.destinationWallet?.nombre ??
        'Cuenta sin asignar';

    // Format date in Spanish
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
    final int monthIdx = int.tryParse(parts[1]) ?? 0;
    final String formattedDate =
        "${int.parse(parts[2])} de ${months[monthIdx]} de ${parts[0]}";

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.g0,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Drag handle
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
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    // Type label
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isTransfer
                              ? amountColor.withValues(alpha: 0.12)
                              : isGasto
                              ? AppColors.r1
                              : AppColors.e1,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          isTransfer
                              ? transferBadgeLabel
                              : (isGasto ? 'Gasto' : 'Ingreso'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isTransfer ? amountColor : amountColor,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 16),

                    // Large amount
                    Center(
                          child: Text(
                            amountPrefix.isEmpty
                                ? fmt(t.monto.abs())
                                : "$amountPrefix${fmt(t.monto.abs())}",
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: amountColor,
                              letterSpacing: -1.5,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.08, end: 0, duration: 400.ms),

                    const SizedBox(height: 6),

                    // Description
                    Center(
                      child: Text(
                        t.desc,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.g5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                    if (isTransfer &&
                        (presentation.contextTitle != null ||
                            presentation.contextSubtitle != null)) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: amountColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: amountColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (presentation.contextTitle != null)
                              Text(
                                presentation.contextTitle!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: amountColor,
                                ),
                              ),
                            if (presentation.contextSubtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                presentation.contextSubtitle!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.g5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(duration: 350.ms, delay: 120.ms),
                    ],

                    const SizedBox(height: 24),

                    // Detail card
                    Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFF3F4F6),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            children: [
                              // Category row
                              _buildDetailRow(
                                icon: catIcon,
                                iconColor: catColor,
                                label: 'Categoria',
                                value: catLabel,
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF3F4F6),
                                indent: 16,
                                endIndent: 16,
                              ),

                              // Date row
                              _buildDetailRow(
                                icon: LucideIcons.calendar,
                                iconColor: AppColors.b5,
                                label: 'Fecha',
                                value: formattedDate,
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF3F4F6),
                                indent: 16,
                                endIndent: 16,
                              ),

                              if (isTransfer) ...[
                                _buildDetailRow(
                                  icon: LucideIcons.arrowUpFromLine,
                                  iconColor: AppColors.e8,
                                  label: 'Origen',
                                  value:
                                      presentation.sourceWallet?.nombre ??
                                      'Cuenta origen sin asignar',
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF3F4F6),
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                _buildDetailRow(
                                  icon: LucideIcons.arrowDownToLine,
                                  iconColor: AppColors.e6,
                                  label: 'Destino',
                                  value:
                                      presentation.destinationWallet?.nombre ??
                                      'Cuenta destino sin asignar',
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF3F4F6),
                                  indent: 16,
                                  endIndent: 16,
                                ),
                              ] else ...[
                                _buildDetailRow(
                                  icon: LucideIcons.landmark,
                                  iconColor: AppColors.e7,
                                  label: 'Cuenta',
                                  value: accountLabel,
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF3F4F6),
                                  indent: 16,
                                  endIndent: 16,
                                ),
                              ],

                              // Performed by row
                              if (t.userName != null) ...[
                                _buildDetailRow(
                                  icon: LucideIcons.user,
                                  iconColor: AppColors.o5,
                                  label: 'Realizado por',
                                  value: t.userName!,
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF3F4F6),
                                  indent: 16,
                                  endIndent: 16,
                                ),
                              ],

                              // ID row
                              _buildDetailRow(
                                icon: LucideIcons.hash,
                                iconColor: AppColors.g4,
                                label: 'ID',
                                value: '#${t.id.toString().padLeft(4, '0')}',
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF3F4F6),
                                indent: 16,
                                endIndent: 16,
                              ),

                              // Budget / space row
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            (isSharedBudget
                                                    ? AppColors.e6
                                                    : AppColors.p5)
                                                .withValues(alpha: 0.13),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        isSharedBudget
                                            ? LucideIcons.users
                                            : LucideIcons.layoutGrid,
                                        size: 18,
                                        color: isSharedBudget
                                            ? AppColors.e6
                                            : AppColors.p5,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isSharedBudget
                                                ? 'Espacio compartido'
                                                : 'Presupuesto',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.g4,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            activeBudget?.nombre ??
                                                'Sin presupuesto',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.e8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSharedBudget)
                                      Builder(
                                        builder: (context) {
                                          final members =
                                              (activeBudget?.miembros ??
                                                      const <BudgetMember>[])
                                                  .take(3)
                                                  .toList();
                                          if (members.isEmpty) {
                                            return Container(
                                              width: 26,
                                              height: 26,
                                              margin: const EdgeInsets.only(
                                                left: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.e1,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                LucideIcons.users,
                                                size: 12,
                                                color: AppColors.e8,
                                              ),
                                            );
                                          }

                                          return Row(
                                            children: members
                                                .map(
                                                  (m) => Container(
                                                    width: 26,
                                                    height: 26,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          left: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: m.c,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      m.i,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          duration: 400.ms,
                          delay: 200.ms,
                        ),

                    const SizedBox(height: 24),

                    // Edit + Delete row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    RegisterTransactionSheet(transaction: t),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.e8,
                                borderRadius: BorderRadius.circular(16),
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
                                    "Editar",
                                    style: TextStyle(
                                      fontSize: 15,
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
                          child: Semantics(
                            label: 'Eliminar transaccion ${t.desc}',
                            button: true,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Transaccion eliminada',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: AppColors.r5,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.r1,
                                  borderRadius: BorderRadius.circular(16),
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
                                      "Eliminar",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
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
                    ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.g4,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
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
        ],
      ),
    );
  }
}
