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
import '../../../../shared/widgets/menudo_gauge.dart';
import '../../quick_log/presentation/register_transaction_sheet.dart';

class BudgetDetailSheet extends ConsumerStatefulWidget {
  final MenudoBudget budget;

  const BudgetDetailSheet({super.key, required this.budget});

  @override
  ConsumerState<BudgetDetailSheet> createState() => _BudgetDetailSheetState();
}

class _BudgetDetailSheetState extends ConsumerState<BudgetDetailSheet> {
  String _tab = "resumen"; // plan, resumen, insights

  String _fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  @override
  Widget build(BuildContext context) {
    final double spent = widget.budget.cats.values.fold(
      0,
      (sum, c) => sum + c.gastado,
    );
    final double left = widget.budget.ingresos - spent;
    final bool isShared =
        widget.budget.miembros.length > 1 || widget.budget.espacioId != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        children: [
          // ── Premium Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            decoration: const BoxDecoration(
              color: AppColors.e8,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HeaderAction(
                      icon: LucideIcons.pencil,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Editando presupuesto...',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: AppColors.e6,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.budget.nombre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MenudoChip.custom(
                                label: widget.budget.periodo.toUpperCase(),
                                color: Colors.white.withValues(alpha: 0.9),
                                bgColor: Colors.white.withValues(alpha: 0.15),
                                isSmall: true,
                              ),
                              if (isShared) ...[
                                const SizedBox(width: 6),
                                MenudoChip.custom(
                                  label: "COMPARTIDO",
                                  color: const Color(0xFF6EE7B7),
                                  bgColor: const Color(
                                    0xFF6EE7B7,
                                  ).withValues(alpha: 0.15),
                                  isSmall: true,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    _HeaderAction(
                      icon: LucideIcons.plus,
                      isPrimary: true,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const RegisterTransactionSheet(),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                MenudoGauge(
                  budget: widget.budget,
                  isDark: true,
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),

                // Tabs
                _TabSwitcher(
                  activeTab: _tab,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _tab = val);
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              children: [
                if (_tab == "resumen") ...[
                  _buildSummaryMetrics(spent, left),
                  if (isShared) _buildSharedSpaceSection(spent),
                  _buildCategoriesSection(),
                ],
                if (_tab == "plan") _buildPlanTab(),
                if (_tab == "insights") _buildInsightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics(double spent, double left) {
    return Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: "GASTADO",
                amount: _fmt(spent),
                color: AppColors.r5,
                icon: LucideIcons.trendingDown,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: "RESTANTE",
                amount: _fmt(left),
                color: AppColors.e6,
                icon: LucideIcons.wallet,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildSharedSpaceSection(double totalSpent) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.g2),
      ),
      child:
          Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.e1,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.users,
                              size: 16,
                              color: AppColors.e6,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Espacio Compartido",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.e8,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                "Distribución de gastos",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.g4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _SmallActionButton(
                        label: "Gestionar",
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context); // Close sheet
                          context.push('/spaces-manager');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...widget.budget.miembros.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final m = entry.value;
                    // Simulated split for mock UI
                    final ratios = [0.65, 0.35, 0.2, 0.1];
                    final memberSpent =
                        totalSpent * (ratios.length > idx ? ratios[idx] : 0.1);
                    final pct = totalSpent > 0 ? memberSpent / totalSpent : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _MemberRow(
                        member: m,
                        amount: _fmt(memberSpent),
                        pct: pct,
                      ),
                    );
                  }),
                ],
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 32, 0, 12),
          child: Text(
            "Categorías del presupuesto",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
              letterSpacing: -0.4,
            ),
          ),
        ),
        ...widget.budget.cats.values.toList().asMap().entries.map((entry) {
          return _CategoryDetailCard(cat: entry.value, fmt: _fmt)
              .animate()
              .fadeIn(duration: 400.ms, delay: (entry.key * 50).ms)
              .slideX(begin: 0.05, end: 0);
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            // Trigger category addition flow
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.g2,
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(LucideIcons.plus, size: 20, color: AppColors.g5),
                SizedBox(width: 8),
                Text(
                  "Añadir categoría",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.g5,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
      ],
    );
  }

  Widget _buildPlanTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlanSummaryHeader(
          total: _fmt(widget.budget.ingresos),
          savings: _fmt(widget.budget.ahorroObjetivo),
        ),
        const SizedBox(height: 20),
        ...widget.budget.cats.values.map(
          (cat) => _PlanCategoryRow(
            cat: cat,
            budgetTotal: widget.budget.ingresos,
            fmt: _fmt,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildInsightsTab() {
    final insights = [
      {
        "icon": LucideIcons.trendingUp,
        "color": AppColors.e6,
        "title": "¡Excelente ritmo!",
        "body":
            "Basado en tus gastos actuales, terminarás el mes con un ahorro proyectado de RD\$12,400.",
      },
      {
        "icon": LucideIcons.alertTriangle,
        "color": AppColors.r5,
        "title": "Alerta: Comida",
        "body":
            "Has gastado el 85% de tu límite en 'Comida' y solo ha pasado el 40% del periodo.",
      },
      {
        "icon": LucideIcons.zap,
        "color": AppColors.o5,
        "title": "Gasto inusual",
        "body":
            "Detectamos una suscripción de RD\$1,200 que no estaba en tu planificación original.",
      },
    ];

    return Column(
      children: insights
          .asMap()
          .entries
          .map(
            (entry) =>
                _InsightCard(
                      icon: entry.value["icon"] as IconData,
                      color: entry.value["color"] as Color,
                      title: entry.value["title"] as String,
                      body: entry.value["body"] as String,
                    )
                    .animate()
                    .fadeIn(delay: (entry.key * 100).ms)
                    .slideY(begin: 0.1, end: 0),
          )
          .toList(),
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeaderAction({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.o5
              : Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  final String activeTab;
  final Function(String) onChanged;

  const _TabSwitcher({required this.activeTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          _TabItem(
            label: "Resumen",
            id: "resumen",
            isActive: activeTab == "resumen",
            onTap: () => onChanged("resumen"),
          ),
          _TabItem(
            label: "Plan",
            id: "plan",
            isActive: activeTab == "plan",
            onTap: () => onChanged("plan"),
          ),
          _TabItem(
            label: "Insights",
            id: "insights",
            isActive: activeTab == "insights",
            onTap: () => onChanged("insights"),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label, id;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.id,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.o5 : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, amount;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.g4,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final BudgetMember member;
  final String amount;
  final double pct;

  const _MemberRow({
    required this.member,
    required this.amount,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: member.c,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            member.i,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
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
                  Text(
                    member.n,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.e8,
                    ),
                  ),
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.e8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppColors.g1,
                  valueColor: AlwaysStoppedAnimation<Color>(member.c),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryDetailCard extends StatelessWidget {
  final BudgetCategory cat;
  final String Function(double) fmt;

  const _CategoryDetailCard({required this.cat, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final double left = cat.limite - cat.gastado;
    final double pct = min(
      cat.gastado / (cat.limite > 0 ? cat.limite : 1),
      1.0,
    );
    final bool over = cat.gastado > cat.limite;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: over ? AppColors.r5.withValues(alpha: 0.3) : AppColors.g2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(cat.icono, size: 20, color: cat.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.e8,
                      ),
                    ),
                    Text(
                      "Límite: ${fmt(cat.limite)}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.g4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (over)
                MenudoChip.custom(
                  label: "EXCEDIDO",
                  color: AppColors.r5,
                  bgColor: AppColors.r1,
                  isSmall: true,
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.g1,
              valueColor: AlwaysStoppedAnimation<Color>(
                over ? AppColors.r5 : cat.color,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Gastado: ${fmt(cat.gastado)}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.g5,
                ),
              ),
              Text(
                over
                    ? "Faltan ${fmt(cat.gastado - cat.limite)}"
                    : "Quedan ${fmt(left)}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: over ? AppColors.r5 : AppColors.e6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanSummaryHeader extends StatelessWidget {
  final String total, savings;

  const _PlanSummaryHeader({required this.total, required this.savings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.e8,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "INGRESOS PLANEADOS",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "META AHORRO",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  savings,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6EE7B7),
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

class _PlanCategoryRow extends StatelessWidget {
  final BudgetCategory cat;
  final double budgetTotal;
  final String Function(double) fmt;

  const _PlanCategoryRow({
    required this.cat,
    required this.budgetTotal,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (cat.limite / (budgetTotal > 0 ? budgetTotal : 1) * 100)
        .round();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.g2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cat.icono, size: 18, color: cat.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.e8,
                  ),
                ),
                Text(
                  "$pct% del presupuesto",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.g4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            fmt(cat.limite),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, body;

  const _InsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.g2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.e8,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.g5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
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

class _SmallActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SmallActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.g1,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.g5,
          ),
        ),
      ),
    );
  }
}
