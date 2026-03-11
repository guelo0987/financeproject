import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../shared/widgets/menudo_chip.dart';
import '../../../../shared/widgets/menudo_gauge.dart';
import '../../auth/auth_state.dart';
import '../budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import 'wizard/create_budget_wizard.dart';
import '../../quick_log/presentation/register_transaction_sheet.dart';

class BudgetDetailSheet extends ConsumerStatefulWidget {
  final MenudoBudget budget;

  const BudgetDetailSheet({super.key, required this.budget});

  @override
  ConsumerState<BudgetDetailSheet> createState() => _BudgetDetailSheetState();
}

class _BudgetDetailSheetState extends ConsumerState<BudgetDetailSheet> {
  String _tab = "resumen"; // plan, resumen, insights
  List<BudgetMember> _members = const [];
  bool _isLoadingMembers = false;
  String? _membersError;

  String _fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  bool get _shouldLoadMembers {
    return widget.budget.espacioId != null || widget.budget.miembros.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _members = widget.budget.miembros;
    _loadMembers();
  }

  @override
  void didUpdateWidget(covariant BudgetDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budget.id != widget.budget.id ||
        oldWidget.budget.espacioId != widget.budget.espacioId) {
      _members = widget.budget.miembros;
      _loadMembers();
    }
  }

  Future<void> _openBudgetEditor() async {
    HapticFeedback.lightImpact();
    final navigator = Navigator.of(context);
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateBudgetWizard(initialBudget: widget.budget),
    );
    if (updated == true && mounted) {
      navigator.pop();
    }
  }

  Future<void> _loadMembers() async {
    if (!_shouldLoadMembers) {
      if (mounted) {
        setState(() => _membersError = null);
      }
      return;
    }

    setState(() {
      _isLoadingMembers = true;
      _membersError = null;
    });

    try {
      final members = await ref
          .read(budgetControllerProvider.notifier)
          .fetchBudgetMembers(widget.budget.id);
      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoadingMembers = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _membersError = error.toString();
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _openMembersManager() async {
    HapticFeedback.lightImpact();
    final updatedMembers = await showModalBottomSheet<List<BudgetMember>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetMembersSheet(
        budgetId: widget.budget.id,
        initialMembers: _members,
      ),
    );

    if (!mounted) return;
    if (updatedMembers != null) {
      setState(() {
        _members = updatedMembers;
        _membersError = null;
      });
    } else {
      await _loadMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(effectiveCategoriesProvider);
    final categoriesById = <int, MenudoCategory>{
      for (final category in categories) category.id: category,
    };
    final extraExpenseCategories = [...widget.budget.otherExpenses]
      ..sort((a, b) {
        final parentCompare = _parentLabelForExpense(
          a,
          categoriesById,
        ).compareTo(_parentLabelForExpense(b, categoriesById));
        if (parentCompare != 0) return parentCompare;
        return a.label.compareTo(b.label);
      });
    final displayBudget = widget.budget;
    final double spent = displayBudget.totalSpent;
    final double left = displayBudget.ingresos - spent;
    final bool isShared =
        _members.length > 1 || displayBudget.espacioId != null;

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
                      onTap: _openBudgetEditor,
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
                                label: displayBudget.periodo.toUpperCase(),
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
                  budget: displayBudget,
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
                _buildEditBudgetButton(),
                if (_tab == "resumen") ...[
                  _buildSummaryMetrics(spent, left),
                  if (extraExpenseCategories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _InlineInfoCard(
                        text:
                            'Incluye ${_fmt(extraExpenseCategories.fold<double>(0, (sum, category) => sum + category.gastado))} en gastos fuera del plan. Si luego agregas esa categoría al presupuesto, se moverá automáticamente a su límite.',
                      ),
                    ),
                  if (isShared) _buildSharedBudgetSection(),
                  _buildCategoriesSection(
                    displayBudget,
                    categoriesById,
                    extraExpenseCategories,
                  ),
                ],
                if (_tab == "plan")
                  _buildPlanTab(
                    displayBudget,
                    categoriesById,
                    extraExpenseCategories,
                  ),
                if (_tab == "insights") _buildInsightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditBudgetButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _SmallActionButton(
        label: 'Editar presupuesto',
        onTap: _openBudgetEditor,
      ),
    ).animate().fadeIn(duration: 300.ms);
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

  Widget _buildSharedBudgetSection() {
    final previewMembers = _members.take(3).toList();
    final extraMembers = _members.length - previewMembers.length;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Presupuesto compartido",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.e8,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        _isLoadingMembers
                            ? "Cargando miembros..."
                            : "${_members.length} miembro${_members.length == 1 ? '' : 's'} con acceso",
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
                onTap: _openMembersManager,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoadingMembers && previewMembers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            )
          else if (_membersError != null && previewMembers.isEmpty)
            _InlineInfoCard(
              text: _membersError!,
              tone: _InfoCardTone.error,
              actionLabel: 'Reintentar',
              onTap: _loadMembers,
            )
          else if (previewMembers.isEmpty)
            const _InlineInfoCard(
              text:
                  'Todavía no hay colaboradores aceptados en este presupuesto.',
            )
          else ...[
            ...previewMembers.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MemberRow(member: member),
              ),
            ),
            if (extraMembers > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+$extraMembers miembro${extraMembers == 1 ? '' : 's'} más',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.g4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ],
      ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildCategoriesSection(
    MenudoBudget budget,
    Map<int, MenudoCategory> categoriesById,
    List<BudgetCategory> extraExpenseCategories,
  ) {
    final plannedCategories = budget.cats.values
        .where((category) => category.limite > 0)
        .toList();

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
        ...plannedCategories.asMap().entries.map((entry) {
          return _CategoryDetailCard(
                cat: entry.value,
                parentLabel: _parentLabelForExpense(
                  entry.value,
                  categoriesById,
                ),
                fmt: _fmt,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: (entry.key * 50).ms)
              .slideX(begin: 0.05, end: 0);
        }),
        if (extraExpenseCategories.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 20, 0, 12),
            child: Text(
              "Otros gastos fuera del plan",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.e8,
                letterSpacing: -0.3,
              ),
            ),
          ),
          ...extraExpenseCategories.map(
            (category) => _UnplannedExpenseCard(
              cat: category,
              parentLabel: _parentLabelForExpense(category, categoriesById),
              fmt: _fmt,
            ),
          ),
        ],
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openBudgetEditor,
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

  Widget _buildPlanTab(
    MenudoBudget budget,
    Map<int, MenudoCategory> categoriesById,
    List<BudgetCategory> extraExpenseCategories,
  ) {
    final incomeSources = [...budget.incomeSources]
      ..sort((a, b) {
        final parentCompare = _parentLabelForIncome(
          a,
          categoriesById,
        ).compareTo(_parentLabelForIncome(b, categoriesById));
        if (parentCompare != 0) return parentCompare;
        return a.label.compareTo(b.label);
      });
    final expenseCategories =
        [...budget.cats.values.where((category) => category.limite > 0)]
          ..sort((a, b) {
            final parentCompare = _parentLabelForExpense(
              a,
              categoriesById,
            ).compareTo(_parentLabelForExpense(b, categoriesById));
            if (parentCompare != 0) return parentCompare;
            return a.label.compareTo(b.label);
          });
    final actualIncomeTotal = incomeSources.fold<double>(
      0,
      (sum, source) => sum + source.actual,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlanSummaryHeader(
          plannedTotal: _fmt(budget.ingresos),
          actualTotal: _fmt(actualIncomeTotal),
          savings: _fmt(budget.ahorroObjetivo),
        ),
        const SizedBox(height: 20),
        if (incomeSources.isNotEmpty) ...[
          const _BudgetSectionTitle(title: 'Ingresos planeados vs reales'),
          const SizedBox(height: 10),
          ...incomeSources.map(
            (source) => _IncomePlanRow(
              source: source,
              parentLabel: _parentLabelForIncome(source, categoriesById),
              fmt: _fmt,
            ),
          ),
          const SizedBox(height: 18),
        ],
        const _BudgetSectionTitle(title: 'Limites por categoria'),
        const SizedBox(height: 10),
        ...expenseCategories.map(
          (cat) => _PlanCategoryRow(
            cat: cat,
            parentLabel: _parentLabelForExpense(cat, categoriesById),
            budgetTotal: budget.ingresos,
            fmt: _fmt,
          ),
        ),
        if (extraExpenseCategories.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _BudgetSectionTitle(title: 'Gastos sin límite configurado'),
          const SizedBox(height: 10),
          ...extraExpenseCategories.map(
            (cat) => _UnplannedExpenseCard(
              cat: cat,
              parentLabel: _parentLabelForExpense(cat, categoriesById),
              fmt: _fmt,
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  String _parentLabelForExpense(
    BudgetCategory category,
    Map<int, MenudoCategory> categoriesById,
  ) {
    final parentId = category.parentCategoryId;
    if (parentId == null) return '';
    return categoriesById[parentId]?.nombre ?? '';
  }

  String _parentLabelForIncome(
    BudgetIncomeSource source,
    Map<int, MenudoCategory> categoriesById,
  ) {
    final parentId = source.parentCategoryId;
    if (parentId == null) return '';
    return categoriesById[parentId]?.nombre ?? '';
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

  const _MemberRow({required this.member});

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
                children: [
                  Expanded(
                    child: Text(
                      member.n,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.e8,
                      ),
                    ),
                  ),
                  MenudoChip.custom(
                    label: member.isOwner
                        ? 'DUEÑO'
                        : (member.role ?? 'MIEMBRO').toUpperCase(),
                    color: member.isOwner ? AppColors.e8 : AppColors.o5,
                    bgColor: member.isOwner ? AppColors.e1 : AppColors.o1,
                    isSmall: true,
                  ),
                ],
              ),
              if ((member.email ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  member.email!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.g4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  final String text;
  final _InfoCardTone tone;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _InlineInfoCard({
    required this.text,
    this.tone = _InfoCardTone.neutral,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isError = tone == _InfoCardTone.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? AppColors.r1 : AppColors.g1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: isError ? AppColors.r5 : AppColors.g5,
              ),
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onTap,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isError ? AppColors.r5 : AppColors.e8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _InfoCardTone { neutral, error }

class _BudgetMembersSheet extends ConsumerStatefulWidget {
  final int budgetId;
  final List<BudgetMember> initialMembers;

  const _BudgetMembersSheet({
    required this.budgetId,
    required this.initialMembers,
  });

  @override
  ConsumerState<_BudgetMembersSheet> createState() =>
      _BudgetMembersSheetState();
}

class _BudgetMembersSheetState extends ConsumerState<_BudgetMembersSheet> {
  List<BudgetMember> _members = const [];
  bool _isLoading = false;
  String? _error;
  int? _removingUserId;

  @override
  void initState() {
    super.initState();
    _members = widget.initialMembers;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await ref
          .read(budgetControllerProvider.notifier)
          .fetchBudgetMembers(widget.budgetId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeMember(BudgetMember member) async {
    final targetUserId = member.userId;
    if (targetUserId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitar miembro'),
        content: Text('Se removerá a ${member.n} de este presupuesto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _removingUserId = targetUserId);
    try {
      await ref
          .read(budgetControllerProvider.notifier)
          .removeBudgetMember(widget.budgetId, targetUserId);
      if (!mounted) return;
      await _loadMembers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _removingUserId = null);
      }
    }
  }

  void _closeSheet() {
    Navigator.pop(context, _members);
  }

  bool get _canManageMembers {
    final currentUserId = int.tryParse(ref.read(authProvider).userId ?? '');
    if (currentUserId == null) return false;

    for (final member in _members) {
      if (member.userId == currentUserId) {
        return member.isOwner || member.role == 'admin';
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.g3,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Miembros',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.e8,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Acceso real a este presupuesto',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.g4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _closeSheet,
                    icon: const Icon(LucideIcons.x, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadMembers,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    if (_isLoading && _members.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      )
                    else if (_error != null && _members.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _InlineInfoCard(
                          text: _error!,
                          tone: _InfoCardTone.error,
                          actionLabel: 'Reintentar',
                          onTap: _loadMembers,
                        ),
                      )
                    else if (_members.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: _InlineInfoCard(
                          text:
                              'Este presupuesto todavía no tiene miembros adicionales.',
                        ),
                      )
                    else
                      ..._members.map((member) {
                        final isRemoving = _removingUserId == member.userId;
                        final canRemove =
                            _canManageMembers &&
                            !member.isOwner &&
                            member.userId != null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.g2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: member.c,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  member.i,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            member.n,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.e8,
                                            ),
                                          ),
                                        ),
                                        MenudoChip.custom(
                                          label: member.isOwner
                                              ? 'DUEÑO'
                                              : (member.role ?? 'MIEMBRO')
                                                    .toUpperCase(),
                                          color: member.isOwner
                                              ? AppColors.e8
                                              : AppColors.o5,
                                          bgColor: member.isOwner
                                              ? AppColors.e1
                                              : AppColors.o1,
                                          isSmall: true,
                                        ),
                                      ],
                                    ),
                                    if ((member.email ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        member.email!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.g4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (canRemove) ...[
                                const SizedBox(width: 10),
                                TextButton(
                                  onPressed: isRemoving
                                      ? null
                                      : () => _removeMember(member),
                                  child: isRemoving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Quitar'),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                    const _InlineInfoCard(
                      text:
                          'Los colaboradores nuevos se envían al crear el presupuesto. Desde aquí puedes revisar o remover miembros existentes.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDetailCard extends StatelessWidget {
  final BudgetCategory cat;
  final String parentLabel;
  final String Function(double) fmt;

  const _CategoryDetailCard({
    required this.cat,
    required this.parentLabel,
    required this.fmt,
  });

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
                    if (parentLabel.isNotEmpty)
                      Text(
                        parentLabel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.g4,
                          letterSpacing: 0.5,
                        ),
                      ),
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

class _UnplannedExpenseCard extends StatelessWidget {
  final BudgetCategory cat;
  final String parentLabel;
  final String Function(double) fmt;

  const _UnplannedExpenseCard({
    required this.cat,
    required this.parentLabel,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.a1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(cat.icono, size: 20, color: cat.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (parentLabel.isNotEmpty)
                            Text(
                              parentLabel.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.g4,
                                letterSpacing: 0.5,
                              ),
                            ),
                          Text(
                            cat.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.e8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MenudoChip.custom(
                      label: 'SIN LIMITE',
                      color: AppColors.o5,
                      bgColor: AppColors.o1,
                      isSmall: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Gastado ${fmt(cat.gastado)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.r5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Este gasto cuenta dentro del presupuesto, pero todavía no tiene un límite configurado.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.g5,
                    fontWeight: FontWeight.w600,
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

class _PlanSummaryHeader extends StatelessWidget {
  final String plannedTotal, actualTotal, savings;

  const _PlanSummaryHeader({
    required this.plannedTotal,
    required this.actualTotal,
    required this.savings,
  });

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
                  plannedTotal,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
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
                  "INGRESO ACTUAL",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  actualTotal,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6EE7B7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
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
  final String parentLabel;
  final double budgetTotal;
  final String Function(double) fmt;

  const _PlanCategoryRow({
    required this.cat,
    required this.parentLabel,
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
                if (parentLabel.isNotEmpty)
                  Text(
                    parentLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.g4,
                      letterSpacing: 0.5,
                    ),
                  ),
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
                const SizedBox(height: 2),
                Text(
                  'Planeado ${fmt(cat.limite)} · Actual ${fmt(cat.gastado)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cat.gastado > cat.limite
                        ? AppColors.r5
                        : AppColors.e6,
                    fontWeight: FontWeight.w700,
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

class _IncomePlanRow extends StatelessWidget {
  const _IncomePlanRow({
    required this.source,
    required this.parentLabel,
    required this.fmt,
  });

  final BudgetIncomeSource source;
  final String parentLabel;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    final isPositive = source.difference >= 0;
    final accent = isPositive ? AppColors.e6 : AppColors.r5;

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
              color: source.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(source.icono, size: 18, color: source.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (parentLabel.isNotEmpty)
                  Text(
                    parentLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.g4,
                      letterSpacing: 0.5,
                    ),
                  ),
                Text(
                  source.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.e8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Planeado ${fmt(source.planned)} · Actual ${fmt(source.actual)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.g4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isPositive
                  ? '+${fmt(source.difference.abs())}'
                  : '-${fmt(source.difference.abs())}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSectionTitle extends StatelessWidget {
  const _BudgetSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: AppColors.e8,
          letterSpacing: -0.3,
        ),
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
