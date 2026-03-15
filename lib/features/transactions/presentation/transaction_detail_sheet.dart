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
    final String compactDate = parts.length == 3
        ? "${int.tryParse(parts[2]) ?? parts[2]} ${['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'][monthIdx]}"
        : t.dateString;

    final String categoryPathLabel =
        childCategory != null && parentCategory != null
        ? '${parentCategory.nombre} · ${childCategory.nombre}'
        : catLabel;
    final String heroOverline = isTransfer
        ? transferBadgeLabel
        : (isGasto ? 'Gasto registrado' : 'Ingreso registrado');
    final String hierarchyHint = childCategory != null
        ? 'Pertenece a ${parentCategory?.nombre ?? catLabel}'
        : (isGasto
              ? 'Se guardó directo en la categoría principal'
              : 'Movimiento asociado a esta categoría');
    final String formattedAmount = amountPrefix.isEmpty
        ? fmt(t.monto.abs(), currency: t.moneda)
        : "$amountPrefix${fmt(t.monto.abs(), currency: t.moneda)}";

    final Color heroBase = AppColors.e8;
    final Color heroAccent = isTransfer
        ? AppColors.b5
        : _mix(AppColors.e7, catColor, 0.35);
    final Color heroShadow = _mix(heroAccent, Colors.black, 0.28);

    final metrics = <_DetailMetric>[
      _DetailMetric(
        icon: isTransfer
            ? LucideIcons.arrowRightLeft
            : (isGasto ? LucideIcons.trendingDown : LucideIcons.trendingUp),
        iconColor: amountColor,
        label: 'Monto',
        value: formattedAmount,
      ),
      if (!isTransfer)
        _DetailMetric(
          icon: parentCategory?.icono ?? catIcon,
          iconColor: parentCategory?.color ?? catColor,
          label: childCategory != null ? 'Categoría padre' : 'Categoría',
          value: parentCategory?.nombre ?? catLabel,
          helper: childCategory != null
              ? 'Grupo principal del gasto'
              : 'Sin subcategoría asignada',
        ),
      if (childCategory != null)
        _DetailMetric(
          icon: childCategory.icono,
          iconColor: childCategory.color,
          label: 'Subcategoría',
          value: childCategory.nombre,
          helper: 'Te ayuda a leer mejor dónde se fue el dinero',
        ),
      if (isTransfer)
        _DetailMetric(
          icon: LucideIcons.arrowUpFromLine,
          iconColor: AppColors.e8,
          label: 'Origen',
          value: presentation.sourceWallet?.nombre ?? 'No registrada',
        ),
      if (isTransfer)
        _DetailMetric(
          icon: LucideIcons.arrowDownToLine,
          iconColor: AppColors.e6,
          label: 'Destino',
          value: presentation.destinationWallet?.nombre ?? 'No registrada',
        ),
      if (!isTransfer && accountLabel != null)
        _DetailMetric(
          icon: LucideIcons.wallet,
          iconColor: AppColors.b5,
          label: 'Cuenta',
          value: accountLabel,
          helper: isGasto ? 'De aquí salió el dinero' : 'Aquí entró el dinero',
        ),
      _DetailMetric(
        icon: LucideIcons.calendarDays,
        iconColor: AppColors.o5,
        label: 'Fecha',
        value: formattedDate,
        helper: compactDate,
      ),
      if (activeBudget != null)
        _DetailMetric(
          icon: isSharedBudget ? LucideIcons.users : LucideIcons.layoutGrid,
          iconColor: isSharedBudget ? AppColors.e6 : AppColors.p5,
          label: 'Presupuesto',
          value: activeBudget.nombre,
          helper: isSharedBudget
              ? 'Movimiento compartido'
              : 'Presupuesto activo',
        ),
      if (performerLabel != null && (isSharedBudget || t.usuarioId != null))
        _DetailMetric(
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
                    Center(
                      child: _TypeBadge(
                        label: isTransfer
                            ? transferBadgeLabel
                            : (isGasto ? 'Gasto' : 'Ingreso'),
                        backgroundColor: isTransfer
                            ? amountColor.withValues(alpha: 0.12)
                            : (isGasto ? AppColors.r1 : AppColors.e1),
                        textColor: amountColor,
                      ),
                    ).animate().fadeIn(duration: 250.ms),
                    const SizedBox(height: 16),
                    _HeroCard(
                          icon: isTransfer
                              ? LucideIcons.arrowRightLeft
                              : catIcon,
                          iconColor: Colors.white,
                          overline: heroOverline,
                          title: categoryPathLabel,
                          subtitle: hierarchyHint,
                          amount: formattedAmount,
                          description: t.desc,
                          startColor: heroBase,
                          endColor: _mix(heroAccent, Colors.black, 0.14),
                          shadowColor: heroShadow,
                          pills: [
                            _HeroMetaPill(
                              icon: LucideIcons.calendarDays,
                              label: compactDate,
                            ),
                            if (!isTransfer &&
                                accountLabel != null &&
                                accountLabel.isNotEmpty)
                              _HeroMetaPill(
                                icon: LucideIcons.wallet,
                                label: accountLabel,
                              ),
                            if (activeBudget != null)
                              _HeroMetaPill(
                                icon: isSharedBudget
                                    ? LucideIcons.users
                                    : LucideIcons.layoutGrid,
                                label: activeBudget.nombre,
                              ),
                            if (performerLabel != null &&
                                (isSharedBudget || t.usuarioId != null))
                              _HeroMetaPill(
                                icon: LucideIcons.user,
                                label: performerLabel,
                              ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 360.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 16),
                    _DetailSection(
                          title: 'Detalles',
                          child: _MetricGrid(metrics: metrics),
                        )
                        .animate()
                        .fadeIn(duration: 320.ms, delay: 140.ms)
                        .slideY(begin: 0.04, end: 0),
                    if (t.nota != null && t.nota!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _DetailSection(
                        title: 'Nota',
                        child: _NoteCard(
                          note: t.nota!.trim(),
                          accentColor: heroAccent,
                        ),
                      ).animate().fadeIn(duration: 320.ms, delay: 180.ms),
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
                    ).animate().fadeIn(duration: 320.ms, delay: 220.ms),
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

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.icon,
    required this.iconColor,
    required this.overline,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.description,
    required this.startColor,
    required this.endColor,
    required this.shadowColor,
    required this.pills,
  });

  final IconData icon;
  final Color iconColor;
  final String overline;
  final String title;
  final String subtitle;
  final String amount;
  final String description;
  final Color startColor;
  final Color endColor;
  final Color shadowColor;
  final List<Widget> pills;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 22, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        overline.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.58),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.76),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
            if (pills.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: pills),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroMetaPill extends StatelessWidget {
  const _HeroMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

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
          Icon(icon, size: 13, color: Colors.white),
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_DetailMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 460;
        final tileWidth = wide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: tileWidth,
                  child: _MetricTile(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _DetailMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: metric.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(metric.icon, size: 18, color: metric.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.g4,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.e8,
                    height: 1.25,
                  ),
                ),
                if (metric.helper != null &&
                    metric.helper!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    metric.helper!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.g5,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
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

class _DetailMetric {
  const _DetailMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.helper,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? helper;
}
