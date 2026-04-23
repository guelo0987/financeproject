import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../core/utils/error_presenter.dart';
import '../../../../core/utils/formatters.dart';
import '../budget_providers.dart';
import 'budget_detail_sheet.dart';
import 'wizard/create_budget_wizard.dart';

String _budgetPeriodLabel(String periodo) {
  return switch (periodo.toLowerCase()) {
    'mensual' => 'MENSUAL',
    'quincenal' => 'QUINCENAL',
    'semanal' => 'SEMANAL',
    'unico' => 'PUNTUAL',
    _ => periodo.toUpperCase(),
  };
}

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  String _filtro = "Todos";
  final List<String> _filtros = ["Todos", "Mensual", "Quincenal", "Semanal"];

  String _fmt(double val) => formatMoney(val);

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
    final activeBudget = budgets.isEmpty ? null : budgets[selectedIdx];

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
            pinned: true,
            backgroundColor: AppColors.g0,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 82,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Presupuestos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.e8,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activeBudget == null
                      ? '${budgets.length} presupuesto${budgets.length == 1 ? '' : 's'}'
                      : 'Activo: ${activeBudget.nombre}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.g4,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: _showCreate,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: AppColors.g2),
                  ),
                  icon: const Icon(
                    LucideIcons.plus,
                    color: AppColors.e8,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters().animate().fadeIn(
                    duration: 400.ms,
                    delay: 100.ms,
                  ),
                  const SizedBox(height: 18),

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
                            delay: (120 + entry.key * 90).ms,
                          )
                          .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
                    }),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 34,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? AppColors.e8 : AppColors.g1,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: selected ? AppColors.e8 : Colors.transparent,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.clipboardList, size: 36, color: AppColors.g3),
          const SizedBox(height: 14),
          const Text(
            "Todavía no tienes presupuestos aquí",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filtro == "Todos"
                ? "Cuando crees uno, aparecerá aquí."
                : "No encontramos presupuestos en la vista '$_filtro'.",
            style: const TextStyle(fontSize: 14, color: AppColors.g5),
            textAlign: TextAlign.center,
          ),
        ],
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
    final isShared = budget.miembros.isNotEmpty || budget.espacioId != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDashboardActive
                ? AppColors.e6.withValues(alpha: 0.28)
                : AppColors.g2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _BudgetMetaTag(
                              label: _budgetPeriodLabel(budget.periodo),
                            ),
                            if (isShared)
                              _BudgetMetaTag(
                                label: budget.miembros.isEmpty
                                    ? 'Compartido'
                                    : '${budget.miembros.length} miembros',
                              ),
                            if (isDashboardActive) const _BudgetActivePill(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          budget.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.e8,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (budget.miembros.isNotEmpty ||
                      budget.espacioId != null) ...[
                    const SizedBox(width: 12),
                    _buildAvatars(
                      budget.miembros,
                      isShared: budget.espacioId != null,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Disponible',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.g4,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 40,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fmt(remaining),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: remaining < 0 ? AppColors.r5 : AppColors.e8,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Plan ${fmt(budget.ingresos)} · Gastado ${fmt(spent)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.g5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _BudgetFact(
                      label: 'Plan',
                      value: fmt(budget.ingresos),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BudgetFact(label: 'Gastado', value: fmt(spent)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.e8,
                        side: const BorderSide(color: AppColors.g2),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Ver detalle',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _DashboardToggleButton(
                    isActive: isDashboardActive,
                    onToggle: onSetActive,
                  ),
                ],
              ),
            ],
          ),
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

class _BudgetFact extends StatelessWidget {
  final String label;
  final String value;

  const _BudgetFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.g4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.e8,
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.e8 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? AppColors.e8 : AppColors.g2),
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
              isActive ? "Activo" : "Usar",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : AppColors.g5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetMetaTag extends StatelessWidget {
  final String label;

  const _BudgetMetaTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.g1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.g5,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _BudgetActivePill extends StatelessWidget {
  const _BudgetActivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.e1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Activo',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.e6,
        ),
      ),
    );
  }
}
