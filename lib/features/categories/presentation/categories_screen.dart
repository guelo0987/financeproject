import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  String fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  @override
  Widget build(BuildContext context) {
    final activeBudget = mockBudgets.firstWhere((b) => b.activo, orElse: () => mockBudgets.first);
    final budgetCats = activeBudget.cats;

    // Calculate spent per catKey from mockTxns
    final Map<String, double> spentByCategory = {};
    for (final t in mockTxns) {
      if (t.tipo == 'gasto') {
        spentByCategory[t.catKey] = (spentByCategory[t.catKey] ?? 0) + t.monto.abs();
      }
    }

    // Find categories NOT in the active budget
    final Set<String> extraCatKeys = spentByCategory.keys.toSet().difference(budgetCats.keys.toSet());

    // Total spent this month
    final double totalSpent = spentByCategory.values.fold(0, (s, v) => s + v);

    // Icon/color fallback for extra categories
    final Map<String, Map<String, dynamic>> extraCatMeta = {
      'salud': {'label': 'Salud', 'icono': LucideIcons.heartPulse, 'color': AppColors.e6},
      'educacion': {'label': 'Educacion', 'icono': LucideIcons.graduationCap, 'color': AppColors.b5},
      'entretenimiento': {'label': 'Entretenimiento', 'icono': LucideIcons.gamepad2, 'color': AppColors.pk},
      'servicios': {'label': 'Servicios', 'icono': LucideIcons.wrench, 'color': AppColors.a5},
      'otro': {'label': 'Otro', 'icono': LucideIcons.helpCircle, 'color': AppColors.g4},
    };

    return Scaffold(
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.e8, size: 22),
          ),
        ),
        title: const Text('Categorias', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.e8)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          // Hero summary card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.e8,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [const BoxShadow(color: Color(0x44065F46), blurRadius: 40, offset: Offset(0, 12))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("GASTO TOTAL ESTE MES", style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(fmt(totalSpent), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("${budgetCats.length + extraCatKeys.length} categorias", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8))),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("${mockTxns.where((t) => t.tipo == 'gasto').length} transacciones", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8))),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),

          const SizedBox(height: 20),

          // Budget categories section header
          const Text("En tu presupuesto", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
          const SizedBox(height: 4),
          Text("Categorias del presupuesto activo", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
          const SizedBox(height: 12),

          // Budget category cards
          ...budgetCats.entries.toList().asMap().entries.map((entry) {
            final int idx = entry.key;
            final String catKey = entry.value.key;
            final BudgetCategory cat = entry.value.value;
            final double spent = spentByCategory[catKey] ?? 0;
            final double pct = cat.limite > 0 ? min(spent / cat.limite, 1.0) : 0;
            final bool over = spent > cat.limite;

            return Semantics(
              label: '${cat.label}, ${fmt(spent)} de ${fmt(cat.limite)}${over ? ", excedido" : ""}',
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CategoryDetailScreen(catKey: catKey),
                  ));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: over ? cat.color.withValues(alpha: 0.3) : const Color(0xFFF3F4F6), width: 1.5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Hero(
                          tag: 'cat-icon-$catKey',
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(14)),
                            alignment: Alignment.center,
                            child: Icon(cat.icono, size: 20, color: cat.color),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(cat.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.e8)),
                                  if (over)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.r1, borderRadius: BorderRadius.circular(6)),
                                      child: const Text("Excedido", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.r5)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text("${fmt(spent)} / ${fmt(cat.limite)}", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(LucideIcons.chevronRight, size: 18, color: AppColors.g3),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(3)),
                      alignment: Alignment.centerLeft,
                      child: LayoutBuilder(
                        builder: (ctx, constraints) => AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          height: 6,
                          width: constraints.maxWidth * pct,
                          decoration: BoxDecoration(
                            color: over ? AppColors.r5 : cat.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("${(pct * 100).round()}%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: over ? AppColors.r5 : AppColors.g4)),
                      ],
                    ),
                  ],
                ),
                ),
              ),
            ).animate().fadeIn(duration: 350.ms, delay: (100 + idx * 60).ms).slideY(begin: 0.06, end: 0, duration: 350.ms, delay: (100 + idx * 60).ms);
          }),

          // Extra categories section
          if (extraCatKeys.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text("Otras categorias", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
            const SizedBox(height: 4),
            const Text("Gastos fuera de tu presupuesto activo", style: TextStyle(fontSize: 12, color: AppColors.g4)),
            const SizedBox(height: 12),

            ...extraCatKeys.toList().asMap().entries.map((entry) {
              final int idx = entry.key;
              final String catKey = entry.value;
              final double spent = spentByCategory[catKey] ?? 0;
              final meta = extraCatMeta[catKey];
              final String label = meta?['label'] ?? catKey[0].toUpperCase() + catKey.substring(1);
              final IconData icono = meta?['icono'] ?? LucideIcons.tag;
              final Color color = meta?['color'] ?? AppColors.g4;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CategoryDetailScreen(catKey: catKey),
                  ));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'cat-icon-$catKey',
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.center,
                          child: Icon(icono, size: 20, color: color),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.e8)),
                            const SizedBox(height: 2),
                            Text("Sin limite asignado", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                          ],
                        ),
                      ),
                      Text(fmt(spent), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.e8)),
                      const SizedBox(width: 8),
                      Icon(LucideIcons.chevronRight, size: 18, color: AppColors.g3),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms, delay: (300 + idx * 60).ms).slideY(begin: 0.06, end: 0, duration: 350.ms, delay: (300 + idx * 60).ms);
            }),
          ],
        ],
      ),
    );
  }
}
