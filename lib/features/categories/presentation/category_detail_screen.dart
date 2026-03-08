import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String catKey;

  const CategoryDetailScreen({super.key, required this.catKey});

  String fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  @override
  Widget build(BuildContext context) {
    final activeBudget = mockBudgets.firstWhere((b) => b.activo, orElse: () => mockBudgets.first);
    final BudgetCategory? budgetCat = activeBudget.cats[catKey];

    // Fallback meta for categories not in budget
    final Map<String, Map<String, dynamic>> fallbackMeta = {
      'vivienda': {'label': 'Vivienda', 'icono': LucideIcons.home, 'color': AppColors.e7},
      'comida': {'label': 'Comida', 'icono': LucideIcons.utensils, 'color': AppColors.o5},
      'transporte': {'label': 'Transporte', 'icono': LucideIcons.car, 'color': AppColors.p5},
      'estiloVida': {'label': 'Estilo de vida', 'icono': LucideIcons.sparkles, 'color': AppColors.pk},
      'salud': {'label': 'Salud', 'icono': LucideIcons.heartPulse, 'color': AppColors.e6},
      'educacion': {'label': 'Educacion', 'icono': LucideIcons.graduationCap, 'color': AppColors.b5},
      'entretenimiento': {'label': 'Entretenimiento', 'icono': LucideIcons.gamepad2, 'color': AppColors.pk},
      'servicios': {'label': 'Servicios', 'icono': LucideIcons.wrench, 'color': AppColors.a5},
    };

    final String label = budgetCat?.label ?? fallbackMeta[catKey]?['label'] ?? (catKey[0].toUpperCase() + catKey.substring(1));
    final IconData icono = budgetCat?.icono ?? fallbackMeta[catKey]?['icono'] ?? LucideIcons.tag;
    final Color color = budgetCat?.color ?? fallbackMeta[catKey]?['color'] ?? AppColors.g4;

    // Filter transactions for this category
    final txns = mockTxns.where((t) => t.catKey == catKey).toList();
    final double totalSpent = txns.where((t) => t.tipo == 'gasto').fold(0.0, (s, t) => s + t.monto.abs());

    final bool hasLimit = budgetCat != null;
    final double limite = budgetCat?.limite ?? 0;
    final double pct = hasLimit && limite > 0 ? min(totalSpent / limite, 1.0) : 0;
    final bool over = hasLimit && totalSpent > limite;

    return Scaffold(
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.e8, size: 22),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'cat-icon-$catKey',
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Icon(icono, size: 14, color: color),
              ),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.e8)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.e8,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [const BoxShadow(color: Color(0x44065F46), blurRadius: 40, offset: Offset(0, 12))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: Icon(icono, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("GASTADO EN ${label.toUpperCase()}", style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(fmt(totalSpent), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasLimit) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                    alignment: Alignment.centerLeft,
                    child: LayoutBuilder(
                      builder: (ctx, constraints) => AnimatedContainer(
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        height: 8,
                        width: constraints.maxWidth * pct,
                        decoration: BoxDecoration(
                          color: over ? AppColors.r5 : color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${(pct * 100).round()}% del limite", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
                      Text("Limite: ${fmt(limite)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ),
                  if (over) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.r5.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.alertTriangle, size: 14, color: Color(0xFFFCA5A5)),
                          const SizedBox(width: 6),
                          Text("Excedido por ${fmt(totalSpent - limite)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFCA5A5))),
                        ],
                      ),
                    ),
                  ],
                ],
                if (!hasLimit) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text("Sin limite en presupuesto", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),

          const SizedBox(height: 20),

          // Transactions header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Transacciones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
              Text("${txns.length} registros", style: const TextStyle(fontSize: 13, color: AppColors.g4, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),

          // Transaction list or empty state
          if (txns.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(18)),
                    alignment: Alignment.center,
                    child: Icon(LucideIcons.inbox, size: 28, color: AppColors.g3),
                  ),
                  const SizedBox(height: 14),
                  const Text("Sin transacciones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
                  const SizedBox(height: 4),
                  const Text("No hay gastos registrados en esta categoria", style: TextStyle(fontSize: 13, color: AppColors.g4), textAlign: TextAlign.center),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms)
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: List.generate(txns.length, (i) {
                  final t = txns[i];
                  final dayStr = t.dateString.split('-');
                  final months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
                  final monthLabel = months[int.tryParse(dayStr[1]) ?? 0];

                  return Column(
                    children: [
                      if (i > 0) const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 68, endIndent: 16),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => TransactionDetailSheet(transaction: t),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(13)),
                                alignment: Alignment.center,
                                child: Icon(t.icono, size: 19, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.desc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text("${dayStr[2]} $monthLabel", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t.tipo == "ingreso" ? "+ ${fmt(t.monto.abs())}" : "- ${fmt(t.monto.abs())}",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: t.tipo == "ingreso" ? AppColors.e6 : AppColors.e8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 200.ms),
        ],
      ),
    );
  }
}
