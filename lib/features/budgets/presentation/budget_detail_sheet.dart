import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../shared/widgets/menudo_chip.dart';
import '../../../../shared/widgets/menudo_gauge.dart';
import '../../quick_log/presentation/register_transaction_sheet.dart';

class BudgetDetailSheet extends StatefulWidget {
  final MenudoBudget budget;

  const BudgetDetailSheet({super.key, required this.budget});

  @override
  State<BudgetDetailSheet> createState() => _BudgetDetailSheetState();
}

class _BudgetDetailSheetState extends State<BudgetDetailSheet> {
  String _tab = "restante"; // plan, restante, insights

  String fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  @override
  Widget build(BuildContext context) {
    final double spent = widget.budget.cats.values.fold(0, (sum, c) => sum + c.gastado);
    final double left = widget.budget.ingresos - spent;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
          // Header (Dark Section)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            decoration: const BoxDecoration(
              color: AppColors.e8,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                // Drag handle
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 12))),
                
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), alignment: Alignment.center, child: const Icon(Icons.arrow_back, color: Colors.white, size: 16)),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(widget.budget.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MenudoChip.custom(label: widget.budget.periodo, color: Colors.white.withValues(alpha: 0.8), bgColor: Colors.white.withValues(alpha: 0.15), isSmall: true),
                              const SizedBox(width: 6),
                              MenudoChip.custom(label: "24 días", color: Colors.white.withValues(alpha: 0.8), bgColor: Colors.white.withValues(alpha: 0.15), isSmall: true),
                            ],
                          )
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const RegisterTransactionSheet(),
                        );
                      },
                      child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: AppColors.o5, shape: BoxShape.circle), alignment: Alignment.center, child: const Text("+", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                MenudoGauge(budget: widget.budget, isDark: true),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...widget.budget.miembros.map((m) => Container(
                      width: 28, height: 28, margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(color: m.c, shape: BoxShape.circle, border: Border.all(color: AppColors.e8, width: 2)),
                      alignment: Alignment.center, child: Text(m.i, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    )),
                    if (widget.budget.miembros.length < 4)
                      Container(
                        width: 28, height: 28, margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5, style: BorderStyle.solid)), // Fallback for dashed border
                        alignment: Alignment.center, child: Text("+", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w600)),
                      )
                  ],
                ),
                const SizedBox(height: 12),
                
                // Tabs
                Container(
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15)))),
                  child: Row(
                    children: ["plan", "restante", "insights"].map((t) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tab == t ? AppColors.o5 : Colors.transparent, width: 3))),
                          alignment: Alignment.center,
                          child: Text(t.toUpperCase(), style: TextStyle(color: _tab == t ? Colors.white : Colors.white.withValues(alpha: 0.5), fontWeight: _tab == t ? FontWeight.w800 : FontWeight.w600, fontSize: 12, letterSpacing: 0.5)),
                        ),
                      ),
                    )).toList(),
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                if (_tab == "restante") _buildRestanteTab(spent, left),
                if (_tab == "plan") _buildPlanTab(),
                if (_tab == "insights") _buildInsightsTab(),
              ],
            ),
          )
        ],
        ),
      ),
    );
  }

  Widget _buildRestanteTab(double spent, double left) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("GASTADO", style: TextStyle(fontSize: 11, color: AppColors.g4, fontWeight: FontWeight.w700, letterSpacing: 0.5)), Text(fmt(spent), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.r5))]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("RESTANTE", style: TextStyle(fontSize: 11, color: AppColors.g4, fontWeight: FontWeight.w700, letterSpacing: 0.5)), Text(fmt(left), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.e6))]),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 8, decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.centerLeft,
                child: LayoutBuilder(builder: (ctx, constraints) => Container(height: 8, width: constraints.maxWidth * min(spent / widget.budget.ingresos, 1.0), decoration: BoxDecoration(color: AppColors.o5, borderRadius: BorderRadius.circular(4)))),
              ),
              const SizedBox(height: 6),
              Text("${(spent / widget.budget.ingresos * 100).round()}% del presupuesto usado", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
            ],
          ),
        ),
        
        ...widget.budget.cats.values.map((cat) {
          final catLeft = cat.limite - cat.gastado;
          final pct = min(cat.gastado / cat.limite, 1.0);
          final over = cat.gastado > cat.limite;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: over ? cat.color.withValues(alpha: 0.3) : const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(13)), alignment: Alignment.center, child: Icon(cat.icono, size: 20, color: cat.color)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(cat.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.e8)), if (over) MenudoChip.custom(label: "Límite", color: AppColors.r5, isSmall: true)]),
                          const SizedBox(height: 2),
                          Text("Límite: ${fmt(cat.limite)}", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 8, decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(4)),
                  alignment: Alignment.centerLeft,
                  child: LayoutBuilder(builder: (ctx, constraints) => Container(height: 8, width: constraints.maxWidth * pct, decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(4)))),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Gastado: ", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                    Text(fmt(cat.gastado), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.g5)),
                    const Spacer(),
                    Text(over ? "Excedido" : "${fmt(catLeft)} libre", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: over ? AppColors.r5 : AppColors.e6)),
                  ],
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPlanTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(18), width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("INGRESOS", style: TextStyle(fontSize: 11, color: AppColors.g4, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(fmt(widget.budget.ingresos), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.e6)),
            ],
          ),
        ),
        ...widget.budget.cats.values.map((cat) => Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Icon(cat.icono, size: 20, color: cat.color)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8)),
                    const SizedBox(height: 2),
                    Text("${(cat.limite / widget.budget.ingresos * 100).round()}% del ingreso", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                  ],
                ),
              ),
              Text(fmt(cat.limite), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildInsightsTab() {
    final insights = [
      {"icon": LucideIcons.trendingUp,     "color": AppColors.e6, "bg": AppColors.e0,             "title": "¡Buen ritmo!",       "body": "Llevas 7 días y has gastado solo el 47% del presupuesto mensual."},
      {"icon": LucideIcons.alertTriangle,  "color": AppColors.a5, "bg": AppColors.a1,             "title": "Vivienda al límite", "body": "Ya usaste el 100% de vivienda. Cuidado con gastos extras del hogar."},
      {"icon": LucideIcons.lightbulb,      "color": AppColors.b5, "bg": const Color(0xFFEFF6FF),  "title": "Tendencia comida",   "body": "A este ritmo gastarías RD\$43,000 en comida este mes. Límite: RD\$15,000."},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: insights.map((ins) => Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ins["bg"] as Color, borderRadius: BorderRadius.circular(18), border: Border.all(color: (ins["color"] as Color).withValues(alpha: 0.2))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: (ins["color"] as Color).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(ins["icon"] as IconData, size: 16, color: ins["color"] as Color),
                ),
                const SizedBox(width: 10),
                Text(ins["title"] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.e8)),
              ],
            ),
            const SizedBox(height: 8),
            Text(ins["body"] as String, style: const TextStyle(fontSize: 13, color: AppColors.g5, height: 1.5)),
          ],
        ),
      )).toList(),
    );
  }
}
