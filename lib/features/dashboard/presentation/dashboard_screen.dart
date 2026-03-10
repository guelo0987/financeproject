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
import '../../../../shared/widgets/glass_card.dart';
import '../../budgets/budget_providers.dart';
import '../../budgets/presentation/budget_detail_sheet.dart';
import '../../quick_log/presentation/register_transaction_sheet.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../tools/presentation/tools_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';
import '../../transactions/presentation/spending_breakdown_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetNotifierProvider).valueOrNull ?? mockBudgets;
    final txns = ref.watch(transactionNotifierProvider).valueOrNull ?? mockTxns;
    final selectedIdx = ref.watch(selectedBudgetIdxProvider).clamp(0, budgets.length - 1);
    final budget = budgets[selectedIdx];
    final double spent = budget.cats.values.fold(0, (s, c) => s + c.gastado);
    final double remaining = budget.ingresos - spent;
    final double pct = spent / (budget.ingresos > 0 ? budget.ingresos : 1);

    final now = DateTime.now();
    final monthPrefix = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final txnsThisPeriod = txns.where((t) => t.dateString.startsWith(monthPrefix)).toList();
    final double ingresos = txnsThisPeriod.where((t) => t.tipo == 'ingreso').fold(0.0, (s, t) => s + t.monto.abs());
    final double gastos  = txnsThisPeriod.where((t) => t.tipo == 'gasto').fold(0.0, (s, t) => s + t.monto.abs());
    final recent = txns.where((t) => t.tipo != 'transferencia').take(4).toList();

    final periodoLabel = {
      'mensual': 'este mes', 'quincenal': 'esta quincena',
      'semanal': 'esta semana', 'anual': 'este año',
    }[budget.periodo.toLowerCase()] ?? budget.periodo.toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.g0,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [

            // ── Header ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hola, Miguel",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.e8,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Tu resumen financiero de $periodoLabel",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.g5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                _HeaderCircleButton(
                  icon: LucideIcons.settings,
                  onTap: () => context.push('/settings'),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0, curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            // ── Budget Card ────────────────────────────────────────────
            _buildBudgetCard(context, ref, budgets, budget, selectedIdx, remaining, pct, periodoLabel)
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms)
                .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack, delay: 100.ms),

            const SizedBox(height: 20),

            // ── Quick Log Action ────────────────────────────────────────
            _buildQuickLogButton(context)
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 20),

            // ── Summary Metrics ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: "GASTOS",
                    amount: _fmt(gastos),
                    icon: LucideIcons.trendingDown,
                    color: AppColors.r5,
                    bgColor: AppColors.r1,
                    onTap: () => _showBreakdown(context, txnsThisPeriod, true, periodoLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: "INGRESOS",
                    amount: _fmt(ingresos),
                    icon: LucideIcons.trendingUp,
                    color: AppColors.e6,
                    bgColor: AppColors.e1,
                    onTap: () => _showBreakdown(context, txnsThisPeriod, false, periodoLabel),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 20),

            // ── Action Grid ────────────────────────────────────────────
            Row(
              children: [
                _QuickAction(
                  icon: LucideIcons.pieChart,
                  label: "Categorías",
                  color: AppColors.e6,
                  bgColor: AppColors.e1,
                  onTap: () => context.push('/categories'),
                ),
                const SizedBox(width: 10),
                _QuickAction(
                  icon: LucideIcons.repeat2,
                  label: "Automáticas",
                  color: AppColors.o5,
                  bgColor: AppColors.o1,
                  onTap: () => context.push('/recurring'),
                ),
                const SizedBox(width: 10),
                _QuickAction(
                  icon: LucideIcons.clock,
                  label: "Historial",
                  color: AppColors.p5,
                  bgColor: const Color(0xFFF3EEFF),
                  onTap: () => context.push('/history'),
                ),
                const SizedBox(width: 10),
                _QuickAction(
                  icon: LucideIcons.wrench,
                  label: "Herramientas",
                  color: AppColors.b5,
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: () => context.push('/tools'),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 32),

            // ── Recent Transactions ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transacciones recientes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.e8, letterSpacing: -0.4),
                ),
                TextButton(
                  onPressed: () => context.push('/history'),
                  child: Row(
                    children: [
                      Text("Ver todo", style: TextStyle(color: AppColors.o5, fontWeight: FontWeight.w700)),
                      const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.o5),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

            const SizedBox(height: 4),

            _buildRecentTransactions(budget, recent)
                .animate()
                .fadeIn(duration: 500.ms, delay: 600.ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  void _showBreakdown(BuildContext context, List<MenudoTransaction> txns, bool isGastos, String label) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpendingBreakdownSheet(
        transactions: txns,
        isGastos: isGastos,
        periodoLabel: label,
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, WidgetRef ref, List<MenudoBudget> budgets, MenudoBudget budget, int selectedIdx, double remaining, double pct, String periodoLabel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.e8,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.e8.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.nombre,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 4),
                    MenudoChip.custom(
                      label: budget.periodo.toUpperCase(),
                      color: Colors.white,
                      bgColor: Colors.white.withValues(alpha: 0.15),
                      isSmall: true,
                    ),
                  ],
                ),
                _buildVerButton(context, budget),
              ],
            ),
          ),
          
          _buildBudgetSelector(ref, budgets, selectedIdx),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SALDO DISPONIBLE",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmt(remaining),
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        "/ ${_fmt(budget.ingresos)}",
                        style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMainProgressBar(pct, periodoLabel),
                const SizedBox(height: 16),
                _buildSavingsGoal(budget),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              children: budget.cats.values.take(3).map((cat) => _buildCategoryRow(cat)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerButton(BuildContext context, MenudoBudget budget) {
    return GestureDetector(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: const Text("Detalles", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildBudgetSelector(WidgetRef ref, List<MenudoBudget> budgets, int selectedIdx) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: budgets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final b = budgets[i];
          final isSelected = i == selectedIdx;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(selectedBudgetIdxProvider.notifier).state = i;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: Text(
                b.nombre,
                style: TextStyle(
                  color: isSelected ? AppColors.e8 : Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavingsGoal(MenudoBudget budget) {
    if (budget.ahorroObjetivo <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.piggyBank, size: 16, color: Color(0xFF6EE7B7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "META DE AHORRO",
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.45), letterSpacing: 0.5),
                ),
                Text(
                  _fmt(budget.ahorroObjetivo),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainProgressBar(double pct, String periodoLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: LayoutBuilder(
            builder: (_, constraints) => AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutQuart,
              width: constraints.maxWidth * min(pct, 1.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: pct > 0.9 ? [AppColors.r5, AppColors.r5.withValues(alpha: 0.7)] : [const Color(0xFF6EE7B7), const Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  if (pct < 0.9) BoxShadow(color: const Color(0xFF6EE7B7).withValues(alpha: 0.4), blurRadius: 8)
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${(pct * 100).round()}% de tu presupuesto utilizado",
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(BudgetCategory cat) {
    final double p = min(cat.gastado / (cat.limite > 0 ? cat.limite : 1), 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: Icon(cat.icono, size: 14, color: cat.color),
                  ),
                  const SizedBox(width: 10),
                  Text(cat.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
              Text(
                "${(p * 100).round()}%",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: p,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(p > 0.95 ? AppColors.r5 : cat.color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLogButton(BuildContext context) {
    return GestureDetector(
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
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.o5,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: AppColors.o5.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plusCircle, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text("NUEVA TRANSACCIÓN", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(MenudoBudget budget, List<MenudoTransaction> recent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        children: List.generate(recent.length, (i) {
          final t = recent[i];
          final cat = budget.cats[t.catKey];
          final color = cat?.color ?? AppColors.g4;
          return _TransactionTile(
            transaction: t,
            categoryName: cat?.label ?? t.catKey,
            color: color,
            isLast: i == recent.length - 1,
            onTap: (context) {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TransactionDetailSheet(transaction: t),
              );
            },
          );
        }),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.g2, width: 1.5),
        ),
        child: Icon(icon, size: 20, color: AppColors.e8),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, amount;
  final IconData icon;
  final Color color, bgColor;
  final VoidCallback onTap;

  const _SummaryCard({required this.label, required this.amount, required this.icon, required this.color, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.g2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 16, color: color),
                ),
                Icon(LucideIcons.chevronRight, size: 14, color: AppColors.g3),
              ],
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.g4, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bgColor;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.g2),
          ),
          child: Column(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.g5), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final MenudoTransaction transaction;
  final String categoryName;
  final Color color;
  final bool isLast;
  final Function(BuildContext) onTap;

  const _TransactionTile({required this.transaction, required this.categoryName, required this.color, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(transaction.icono, size: 20, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(transaction.desc, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.e8), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text("$categoryName · ${transaction.dateString}", style: const TextStyle(fontSize: 12, color: AppColors.g4, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  transaction.tipo == "ingreso" ? "+RD\$${transaction.monto.abs().toInt()}" : "-RD\$${transaction.monto.abs().toInt()}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: transaction.tipo == "ingreso" ? AppColors.e6 : AppColors.e8,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) Divider(height: 1, color: AppColors.g1, indent: 74, endIndent: 16),
        ],
      ),
    );
  }
}

