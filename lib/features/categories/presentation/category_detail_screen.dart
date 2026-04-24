import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import '../../../shared/widgets/menudo_loading_view.dart';
import '../providers/category_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String catKey;

  const CategoryDetailScreen({super.key, required this.catKey});

  String fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  MenudoCategory? _findCategory(List<MenudoCategory> categories, String slug) {
    for (final category in categories) {
      if (category.slug == slug) return category;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoryNotifierProvider);
    final transactionsState = ref.watch(transactionNotifierProvider);
    final categories = ref.watch(effectiveCategoriesProvider);
    final category = _findCategory(categories, catKey);

    // Fallback meta for categories not in budget
    final Map<String, Map<String, dynamic>> fallbackMeta = {
      'vivienda': {
        'label': 'Vivienda',
        'icono': MenudoCupertinoIcons.home,
        'color': AppColors.e7,
      },
      'comida': {
        'label': 'Comida',
        'icono': MenudoCupertinoIcons.utensils,
        'color': AppColors.o5,
      },
      'transporte': {
        'label': 'Transporte',
        'icono': MenudoCupertinoIcons.car,
        'color': AppColors.p5,
      },
      'estiloVida': {
        'label': 'Estilo de vida',
        'icono': MenudoCupertinoIcons.sparkles,
        'color': AppColors.pk,
      },
      'salud': {
        'label': 'Salud',
        'icono': MenudoCupertinoIcons.heartPulse,
        'color': AppColors.e6,
      },
      'educacion': {
        'label': 'Educacion',
        'icono': MenudoCupertinoIcons.graduationCap,
        'color': AppColors.b5,
      },
      'entretenimiento': {
        'label': 'Entretenimiento',
        'icono': MenudoCupertinoIcons.gamepad2,
        'color': AppColors.pk,
      },
      'servicios': {
        'label': 'Servicios',
        'icono': MenudoCupertinoIcons.wrench,
        'color': AppColors.a5,
      },
    };

    final String label =
        category?.nombre ??
        fallbackMeta[catKey]?['label'] ??
        (catKey[0].toUpperCase() + catKey.substring(1));
    final IconData icono =
        category?.icono ??
        fallbackMeta[catKey]?['icono'] ??
        MenudoCupertinoIcons.tag;
    final Color color =
        category?.color ??
        fallbackMeta[catKey]?['color'] ??
        context.menudo.textMuted;

    final txns = ref
        .watch(currentMonthTransactionsProvider)
        .where((t) => t.catKey == catKey)
        .toList();
    final double totalSpent = txns
        .where((t) => t.tipo == 'gasto')
        .fold(0.0, (s, t) => s + t.monto.abs());
    final double averageSpent = txns.isEmpty ? 0 : totalSpent / txns.length;

    if ((categoriesState.isLoading && categories.isEmpty) ||
        (transactionsState.isLoading && txns.isEmpty)) {
      return Scaffold(
        backgroundColor: context.menudo.background,
        body: MenudoLoadingView(
          title: 'Cargando categoría',
          message: 'Estamos preparando el detalle de esta categoría.',
          logoSize: 88,
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.menudo.background,
      appBar: AppBar(
        backgroundColor: context.menudo.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: MenudoGestureDetector(
          onTap: () {
            MenudoHaptics.light();
            Navigator.pop(context);
          },
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              MenudoCupertinoIcons.arrowLeft,
              color: context.menudo.textMain,
              size: (22),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'cat-icon-$catKey',
              child: Container(
                width: (28),
                height: (28),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icono, size: (14), color: color),
              ),
            ),
            SizedBox(width: (10)),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.menudo.textMain,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.menudo.textOnDark,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: context.menudo.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Icon(icono, size: (22), color: color),
                        ),
                        SizedBox(width: (14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total en ${label.toLowerCase()}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.menudo.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                fmt(totalSpent),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: context.menudo.textMain,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: (16)),
                    Row(
                      children: [
                        Expanded(
                          child: _CategoryStatCard(
                            label: 'Movimientos',
                            value: '${txns.length}',
                          ),
                        ),
                        SizedBox(width: (10)),
                        Expanded(
                          child: _CategoryStatCard(
                            label: 'Promedio',
                            value: fmt(averageSpent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.05, end: 0, duration: 400.ms),

          SizedBox(height: (20)),

          // Transactions header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transacciones",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textMain,
                ),
              ),
              Text(
                "${txns.length} movimientos",
                style: TextStyle(
                  fontSize: 13,
                  color: context.menudo.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: (10)),

          // Transaction list or empty state
          if (txns.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: context.menudo.textOnDark,
                border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: context.menudo.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      MenudoCupertinoIcons.inbox,
                      size: (28),
                      color: context.menudo.textMuted,
                    ),
                  ),
                  SizedBox(height: (14)),
                  Text(
                    "Todavía no hay movimientos en esta categoría",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.menudo.textMain,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Cuando registres uno, lo verás aquí.",
                    style: TextStyle(
                      fontSize: 13,
                      color: context.menudo.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms)
          else
            Container(
                  decoration: BoxDecoration(
                    color: context.menudo.textOnDark,
                    border: Border.all(
                      color: const Color(0xFFF3F4F6),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: List.generate(txns.length, (i) {
                      final t = txns[i];
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
                      final monthLabel = months[int.tryParse(dayStr[1]) ?? 0];

                      return Column(
                        children: [
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Color(0xFFF3F4F6),
                              indent: 68,
                              endIndent: 16,
                            ),
                          MenudoGestureDetector(
                            onTap: () {
                              MenudoHaptics.light();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    TransactionDetailSheet(transaction: t),
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
                                      color: color.withValues(alpha: 0.13),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      t.icono,
                                      size: (19),
                                      color: color,
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
                                            fontWeight: FontWeight.w700,
                                            color: context.menudo.textMain,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          "${dayStr[2]} $monthLabel",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.menudo.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    t.tipo == "ingreso"
                                        ? "+ ${fmt(t.monto.abs())}"
                                        : "- ${fmt(t.monto.abs())}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: t.tipo == "ingreso"
                                          ? AppColors.e6
                                          : context.menudo.textMain,
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
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 200.ms),
        ],
      ),
    );
  }
}

class _CategoryStatCard extends StatelessWidget {
  const _CategoryStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.menudo.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: context.menudo.textMain,
            ),
          ),
        ],
      ),
    );
  }
}
