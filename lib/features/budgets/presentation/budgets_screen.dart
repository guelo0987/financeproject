import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../core/utils/error_presenter.dart';
import '../../../../shared/widgets/menudo_chip.dart';
import '../budget_providers.dart';
import 'budget_detail_sheet.dart';
import 'wizard/create_budget_wizard.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  String _filtro = "Todos";
  final List<String> _filtros = [
    "Todos",
    "Mensual",
    "Quincenal",
    "Semanal",
    "Único",
  ];

  String _fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";

  void _showDetail(MenudoBudget b) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetDetailSheet(budget: b),
    );
  }

  void _showCreate() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateBudgetWizard(),
    );
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(presentError(error)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectBudget(MenudoBudget budget) async {
    HapticFeedback.mediumImpact();
    try {
      await ref
          .read(budgetNotifierProvider.notifier)
          .selectBudget(budget.id, persist: true);
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(effectiveBudgetsProvider);
    final selectedIdx = ref
        .watch(selectedBudgetIdxProvider)
        .clamp(0, budgets.isEmpty ? 0 : budgets.length - 1);

    final filteredBudgets = _filtro == "Todos"
        ? budgets
        : budgets
              .where((b) => b.periodo.toLowerCase() == _filtro.toLowerCase())
              .toList();

    return Scaffold(
      backgroundColor: AppColors.g0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 20,
                bottom: 16,
              ),
              centerTitle: false,
              title: const Text(
                'Presupuestos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.e8,
                  letterSpacing: -0.8,
                ),
              ),
              background: Container(color: Colors.white),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  onPressed: _showCreate,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.o5,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashboard callout
                  _buildDashboardCallout(budgets, selectedIdx)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0, curve: Curves.easeOutBack),

                  const SizedBox(height: 20),

                  // Filters
                  _buildFilters().animate().fadeIn(
                    duration: 400.ms,
                    delay: 100.ms,
                  ),

                  const SizedBox(height: 24),

                  if (filteredBudgets.isEmpty)
                    _buildEmptyState()
                  else
                    ...filteredBudgets.asMap().entries.map((entry) {
                      final b = entry.value;
                      final globalIdx = budgets.indexOf(b);
                      return _BudgetCard(
                            budget: b,
                            isDashboardActive: globalIdx == selectedIdx,
                            onTap: () => _showDetail(b),
                            onSetActive: () async => _selectBudget(b),
                            fmt: _fmt,
                          )
                          .animate()
                          .fadeIn(
                            duration: 500.ms,
                            delay: (200 + entry.key * 100).ms,
                          )
                          .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
                    }),

                  const SizedBox(height: 20),

                  _buildCreateNewButton().animate().fadeIn(
                    duration: 500.ms,
                    delay: 400.ms,
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCallout(List<MenudoBudget> budgets, int selectedIdx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.e1.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.e8.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.layoutDashboard,
              size: 16,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "VISUALIZACIÓN ACTIVA",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.e8,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  budgets.isNotEmpty ? budgets[selectedIdx].nombre : 'Ninguno',
                  style: const TextStyle(
                    fontSize: 14,
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

  Widget _buildFilters() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filtros.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = _filtros[i];
          final selected = p == _filtro;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filtro = p);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: selected ? AppColors.e8 : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: selected ? AppColors.e8 : AppColors.g2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                p,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.g5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Icon(
              LucideIcons.clipboardList,
              size: 48,
              color: AppColors.g3,
            ),
            const SizedBox(height: 16),
            const Text(
              "No hay presupuestos",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.e8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No se encontraron presupuestos en la categoría '$_filtro'",
              style: const TextStyle(fontSize: 14, color: AppColors.g5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateNewButton() {
    return GestureDetector(
      onTap: _showCreate,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.o5.withValues(alpha: 0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.o1,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.plus,
                size: 24,
                color: AppColors.o5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "NUEVO PRESUPUESTO",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.e8,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final MenudoBudget budget;
  final bool isDashboardActive;
  final VoidCallback onTap;
  final VoidCallback onSetActive;
  final String Function(double) fmt;

  const _BudgetCard({
    required this.budget,
    required this.isDashboardActive,
    required this.onTap,
    required this.onSetActive,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final double spent = budget.totalSpent;
    final double remaining = budget.availableToSpend;
    final double incomeBase = budget.displayIncomeBase;
    final double pct = min(spent / (incomeBase > 0 ? incomeBase : 1), 1.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDashboardActive ? AppColors.e8 : AppColors.g2,
            width: isDashboardActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDashboardActive ? AppColors.e8 : AppColors.g4)
                  .withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDashboardActive ? AppColors.e8 : AppColors.g0,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            MenudoChip.custom(
                              label: budget.periodo.toUpperCase(),
                              color: isDashboardActive
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppColors.g5,
                              bgColor: isDashboardActive
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : AppColors.g2,
                              isSmall: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          budget.nombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDashboardActive
                                ? Colors.white
                                : AppColors.e8,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildAvatars(
                    budget.miembros,
                    isShared: budget.espacioId != null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BudgetStat(
                        label: "GASTADO",
                        value: fmt(spent),
                        color: AppColors.r5,
                      ),
                      _BudgetStat(
                        label: "DISPONIBLE",
                        value: fmt(remaining),
                        color: AppColors.e6,
                        center: true,
                      ),
                      _BudgetStat(
                        label: "PLAN",
                        value: fmt(budget.ingresos),
                        color: AppColors.e8,
                        right: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProgressBar(pct: pct),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${(pct * 100).round()}% utilizado",
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.g4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _DashboardToggleButton(
                        isActive: isDashboardActive,
                        onToggle: onSetActive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatars(List<BudgetMember> miembros, {required bool isShared}) {
    if (miembros.isEmpty) {
      if (!isShared) return const SizedBox.shrink();
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.e1,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child: const Icon(LucideIcons.users, size: 14, color: AppColors.e8),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(miembros.length, (i) {
        final m = miembros[i];
        return Align(
          widthFactor: 0.7,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: m.c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              m.i,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool center, right;

  const _BudgetStat({
    required this.label,
    required this.value,
    required this.color,
    this.center = false,
    this.right = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: right
          ? CrossAxisAlignment.end
          : center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.g4,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double pct;

  const _ProgressBar({required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.g1,
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) => AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutQuart,
          width: constraints.maxWidth * pct,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: pct > 0.9
                  ? [AppColors.r5, AppColors.r5.withValues(alpha: 0.7)]
                  : [AppColors.o5, AppColors.o5.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _DashboardToggleButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const _DashboardToggleButton({
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.e8 : AppColors.g1,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? LucideIcons.checkCircle : LucideIcons.layoutDashboard,
              size: 14,
              color: isActive ? Colors.white : AppColors.g5,
            ),
            const SizedBox(width: 6),
            Text(
              isActive ? "ACTIVO" : "USAR EN DASHBOARD",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : AppColors.g5,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
