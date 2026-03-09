import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../shared/widgets/menudo_chip.dart';
import '../../budgets/budget_providers.dart';
import '../../budgets/presentation/budget_detail_sheet.dart';
import '../../quick_log/presentation/register_transaction_sheet.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../tools/presentation/tools_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetNotifierProvider).valueOrNull ?? mockBudgets;
    final txns = ref.watch(transactionNotifierProvider).valueOrNull ?? mockTxns;
    final selectedIdx = ref.watch(selectedBudgetIdxProvider).clamp(0, budgets.isEmpty ? 0 : budgets.length - 1);

    if (budgets.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.g0,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final budget = budgets[selectedIdx];
    final double spent = budget.cats.values.fold(0, (s, c) => s + c.gastado);
    final double remaining = budget.ingresos - spent;
    final double pct = spent / (budget.ingresos > 0 ? budget.ingresos : 1);

    final double ingresos = txns.where((t) => t.tipo == 'ingreso').fold(0.0, (s, t) => s + t.monto.abs());
    final double gastos  = txns.where((t) => t.tipo == 'gasto').fold(0.0, (s, t) => s + t.monto.abs());
    final recent = txns.where((t) => t.tipo != 'transferencia').take(4).toList();

    final periodoLabel = {
      'mensual': 'este mes', 'quincenal': 'esta quincena',
      'semanal': 'esta semana', 'anual': 'este año',
    }[budget.periodo.toLowerCase()] ?? budget.periodo.toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.g0,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [

            // ── Header ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Hola, Miguel", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.e8, letterSpacing: -0.5)),
                    SizedBox(height: 2),
                    Text("Tu resumen financiero", style: TextStyle(fontSize: 13, color: AppColors.g4)),
                  ],
                ),
                GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); context.push('/settings'); },
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.g2, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.settings, size: 19, color: AppColors.g5),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.04, end: 0, duration: 350.ms),

            const SizedBox(height: 18),

            // ── Budget Card ────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.e8,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [const BoxShadow(color: Color(0x55065F46), blurRadius: 36, offset: Offset(0, 14))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Card top row: name + Ver button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget.nombre,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 6),
                              MenudoChip.custom(
                                label: budget.periodo,
                                color: Colors.white,
                                bgColor: Colors.white.withValues(alpha: 0.18),
                                isSmall: true,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BudgetDetailSheet(budget: budget),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text("Ver →", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Budget selector chips
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 30,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: budgets.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        if (i == budgets.length) {
                          // "+ Nuevo" pill
                          return GestureDetector(
                            onTap: () { HapticFeedback.lightImpact(); context.go('/budgets'); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.plus, size: 12, color: Colors.white.withValues(alpha: 0.6)),
                                  const SizedBox(width: 4),
                                  Text("Nuevo", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        }
                        final b = budgets[i];
                        final isSelected = i == selectedIdx;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(selectedBudgetIdxProvider.notifier).state = i;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.2)),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  Icon(LucideIcons.checkCircle, size: 11, color: AppColors.e8),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  b.nombre,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.e8 : Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Remaining amount + main progress bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RESTANTE",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.45), letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _fmt(remaining),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.2),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                "de ${_fmt(budget.ingresos)}",
                                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Overall progress bar
                        Container(
                          height: 6,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(3)),
                          child: LayoutBuilder(
                            builder: (_, constraints) => AnimatedContainer(
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              height: 6,
                              width: constraints.maxWidth * min(pct, 1.0),
                              decoration: BoxDecoration(
                                color: pct > 0.9 ? AppColors.r5 : pct > 0.7 ? AppColors.a5 : const Color(0xFF6EE7B7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${(pct * 100).round()}% usado $periodoLabel",
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38)),
                        ),
                      ],
                    ),
                  ),

                  // ── Category bars
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: Column(
                      children: budget.cats.values.map((cat) {
                        final double p = min(cat.gastado / (cat.limite > 0 ? cat.limite : 1), 1.0);
                        final bool over = cat.gastado > cat.limite;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Icon(cat.icono, size: 13, color: Colors.white.withValues(alpha: 0.8)),
                                    const SizedBox(width: 6),
                                    Text(cat.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85))),
                                    if (over) ...[
                                      const SizedBox(width: 6),
                                      Icon(LucideIcons.alertTriangle, size: 11, color: AppColors.a5),
                                    ],
                                  ]),
                                  Row(children: [
                                    Text(_fmt(cat.gastado), style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                                    Text(" / ${_fmt(cat.limite)}", style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.28))),
                                  ]),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Container(
                                height: 4,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)),
                                child: LayoutBuilder(
                                  builder: (_, constraints) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    height: 4,
                                    width: constraints.maxWidth * p,
                                    decoration: BoxDecoration(
                                      color: over ? AppColors.r5 : cat.color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 80.ms).slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 80.ms),

            const SizedBox(height: 14),

            // ── Register Button ────────────────────────────────────────
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const RegisterTransactionSheet(),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.o5,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [const BoxShadow(color: Color(0x44F97316), blurRadius: 22, offset: Offset(0, 8))],
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text("Registrar transacción", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 350.ms, delay: 220.ms),

            const SizedBox(height: 14),

            // ── Summary Cards ──────────────────────────────────────────
            Row(
              children: [
                // Gastos card
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.g2, width: 1.5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(color: AppColors.r1, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(LucideIcons.trendingDown, size: 15, color: AppColors.r5),
                              ),
                              const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.g3),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text("GASTÉ ${periodoLabel.toUpperCase()}", style: const TextStyle(fontSize: 10, color: AppColors.g4, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                          const SizedBox(height: 3),
                          Text(_fmt(gastos), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.r5, letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Ingresos card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.g2, width: 1.5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(color: AppColors.e1, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(LucideIcons.trendingUp, size: 15, color: AppColors.e6),
                        ),
                        const SizedBox(height: 10),
                        Text("INGRESÉ ${periodoLabel.toUpperCase()}", style: const TextStyle(fontSize: 10, color: AppColors.g4, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                        const SizedBox(height: 3),
                        Text(_fmt(ingresos), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.e6, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 380.ms, delay: 300.ms).slideY(begin: 0.04, end: 0, duration: 380.ms, delay: 300.ms),

            const SizedBox(height: 14),

            // ── Quick Actions ──────────────────────────────────────────
            Row(
              children: [
                _quickAction(
                  icon: LucideIcons.pieChart,
                  label: "Categorías",
                  iconColor: AppColors.e6,
                  bgColor: AppColors.e1,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                ),
                const SizedBox(width: 8),
                _quickAction(
                  icon: LucideIcons.repeat2,
                  label: "Automáticas",
                  iconColor: AppColors.o5,
                  bgColor: AppColors.o1,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen())),
                ),
                const SizedBox(width: 8),
                _quickAction(
                  icon: LucideIcons.clock,
                  label: "Historial",
                  iconColor: AppColors.p5,
                  bgColor: const Color(0xFFF3EEFF),
                  onTap: () => context.push('/history'),
                ),
                const SizedBox(width: 8),
                _quickAction(
                  icon: LucideIcons.wrench,
                  label: "Herramientas",
                  iconColor: AppColors.b5,
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen())),
                ),
              ],
            ).animate().fadeIn(duration: 380.ms, delay: 380.ms).slideY(begin: 0.04, end: 0, duration: 380.ms, delay: 380.ms),

            const SizedBox(height: 26),

            // ── Recent Transactions ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Últimas transacciones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
                GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); context.push('/history'); },
                  child: const Text("Ver todas →", style: TextStyle(fontSize: 13, color: AppColors.o5, fontWeight: FontWeight.w600)),
                ),
              ],
            ).animate().fadeIn(duration: 350.ms, delay: 440.ms),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.g2, width: 1.5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: List.generate(recent.length, (i) {
                  final t = recent[i];
                  final ci = budget.cats[t.catKey];
                  final Color tileColor = ci?.color ?? AppColors.g4;
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
                                decoration: BoxDecoration(color: tileColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                                alignment: Alignment.center,
                                child: Icon(t.icono, size: 19, color: tileColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.desc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text("${ci?.label ?? t.catKey} · ${t.dateString.split('-')[2]} mar", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t.tipo == "ingreso" ? "+${_fmt(t.monto.abs())}" : "-${_fmt(t.monto.abs())}",
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
            ).animate().fadeIn(duration: 380.ms, delay: 480.ms).slideY(begin: 0.04, end: 0, duration: 380.ms, delay: 480.ms),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.g2, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(11)),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(height: 7),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.g5), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
