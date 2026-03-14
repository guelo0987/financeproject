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
  List<BudgetHistorySnapshot> _history = const [];
  bool _isLoadingHistory = false;
  bool _isLoadingMoreHistory = false;
  bool _historyLoaded = false;
  bool _historyHasMore = false;
  int _historyPage = 0;
  String? _historyError;

  String _fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  bool get _shouldLoadMembers {
    return widget.budget.espacioId != null || widget.budget.miembros.isNotEmpty;
  }

  bool get _supportsHistory {
    return widget.budget.periodo != 'unico';
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
      _resetHistoryState();
      _loadMembers();
      if (_tab == 'insights') {
        _ensureHistoryLoaded();
      }
    }
  }

  Future<void> _openBudgetEditor() async {
    HapticFeedback.lightImpact();
    final navigator = Navigator.of(context);
    MenudoBudget latestBudget = widget.budget;
    for (final budget in ref.read(effectiveBudgetsProvider)) {
      if (budget.id == widget.budget.id) {
        latestBudget = budget;
        break;
      }
    }
    final updated = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CreateBudgetWizard(initialBudget: latestBudget, initialStep: 2),
    );
    if (updated == true && mounted) {
      navigator.pop();
    }
  }

  Future<void> _deleteBudget() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar presupuesto'),
          content: const Text(
            'Esta acción eliminará el presupuesto y ya no podrás recuperarlo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: AppColors.r5),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(budgetControllerProvider.notifier)
          .deleteBudget(widget.budget.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(presentError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openBudgetActions() async {
    HapticFeedback.lightImpact();
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.g0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.g3,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                _BudgetActionOption(
                  icon: LucideIcons.pencil,
                  label: 'Editar presupuesto',
                  onTap: () => Navigator.pop(sheetContext, 'edit'),
                ),
                const SizedBox(height: 10),
                _BudgetActionOption(
                  icon: LucideIcons.trash2,
                  label: 'Eliminar presupuesto',
                  color: AppColors.r5,
                  onTap: () => Navigator.pop(sheetContext, 'delete'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'edit') {
      await _openBudgetEditor();
    } else if (action == 'delete') {
      await _deleteBudget();
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
        _membersError = presentError(error);
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _openMembersManager() async {
    HapticFeedback.lightImpact();
    final updatedMembers = await showModalBottomSheet<List<BudgetMember>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetMembersSheet(
        budgetId: widget.budget.id,
        initialMembers: _members,
        allowInviteWhenEmpty: widget.budget.espacioId == null,
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

  void _resetHistoryState() {
    _history = const [];
    _isLoadingHistory = false;
    _isLoadingMoreHistory = false;
    _historyLoaded = false;
    _historyHasMore = false;
    _historyPage = 0;
    _historyError = null;
  }

  void _ensureHistoryLoaded() {
    if (!_supportsHistory || _historyLoaded || _isLoadingHistory) return;
    _loadHistory();
  }

  Future<void> _loadHistory({bool loadMore = false}) async {
    if (!_supportsHistory) return;
    if (loadMore) {
      if (_isLoadingMoreHistory || !_historyHasMore) return;
    } else if (_isLoadingHistory) {
      return;
    }

    final nextPage = loadMore ? _historyPage + 1 : 1;

    setState(() {
      if (loadMore) {
        _isLoadingMoreHistory = true;
      } else {
        _isLoadingHistory = true;
        _historyError = null;
      }
    });

    try {
      final result = await ref
          .read(budgetControllerProvider.notifier)
          .fetchBudgetHistory(widget.budget.id, page: nextPage, limit: 12);
      if (!mounted) return;
      setState(() {
        _history = loadMore ? [..._history, ...result.items] : result.items;
        _historyPage = result.page;
        _historyHasMore = result.hasMore;
        _historyLoaded = true;
        _historyError = null;
        _isLoadingHistory = false;
        _isLoadingMoreHistory = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _historyError = presentError(error);
        _historyLoaded = true;
        _isLoadingHistory = false;
        _isLoadingMoreHistory = false;
      });
    }
  }

  void _onTabChanged(String value) {
    HapticFeedback.selectionClick();
    setState(() => _tab = value);
    if (value == 'insights') {
      _ensureHistoryLoaded();
    }
  }

  String _fmtAmount(
    double value, {
    String currency = 'DOP',
    bool signed = false,
  }) {
    final prefix = currency == 'USD' ? 'US\$' : 'RD\$';
    final formatted = value.abs().toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final base = '$prefix$formatted';
    if (signed) {
      return value >= 0 ? '+$base' : '-$base';
    }
    return value < 0 ? '-$base' : base;
  }

  String _historyRangeLabel(BudgetHistorySnapshot snapshot) {
    final from = snapshot.desde;
    final to = snapshot.hasta;
    if (from == null || to == null) return 'Período anterior';
    return '${_historyDateLabel(from)} - ${_historyDateLabel(to)}';
  }

  String _historyDateLabel(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _historyEmptyMessage(String periodo) {
    switch (periodo) {
      case 'semanal':
        return 'Todavía no hay semanas cerradas para mostrar. Cuando termine la primera, aparecerá aquí.';
      case 'quincenal':
        return 'Todavía no hay quincenas cerradas para mostrar. Aquí aparecerán cuando se complete la primera.';
      default:
        return 'Todavía no hay períodos cerrados para mostrar. Cuando cierre el primero, lo verás aquí.';
    }
  }

  @override
  Widget build(BuildContext context) {
    var displayBudget = widget.budget;
    for (final budget in ref.watch(effectiveBudgetsProvider)) {
      if (budget.id == widget.budget.id) {
        displayBudget = budget;
        break;
      }
    }

    final categories = ref.watch(effectiveCategoriesProvider);
    final categoriesById = <int, MenudoCategory>{
      for (final category in categories) category.id: category,
    };
    final extraExpenseCategories = [...displayBudget.otherExpenses]
      ..sort((a, b) {
        final parentCompare = _parentLabelForExpense(
          a,
          categoriesById,
        ).compareTo(_parentLabelForExpense(b, categoriesById));
        if (parentCompare != 0) return parentCompare;
        return a.label.compareTo(b.label);
      });
    final double spent = displayBudget.totalSpent;
    final double left = displayBudget.availableToSpend;
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
                      icon: LucideIcons.moreHorizontal,
                      onTap: _openBudgetActions,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            displayBudget.nombre,
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
                        ref
                            .read(budgetControllerProvider.notifier)
                            .selectBudgetLocally(displayBudget.id);
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
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
                _TabSwitcher(activeTab: _tab, onChanged: _onTabChanged),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              children: [
                if (_tab == "resumen") ...[
                  _buildSummaryMetrics(
                    spent,
                    left,
                    displayBudget.actualIncomeTotal,
                  ),
                  _buildSharedBudgetSection(isShared: isShared),
                  _buildCategoriesSection(
                    displayBudget,
                    categoriesById,
                    extraExpenseCategories,
                  ),
                ],
                if (_tab == "plan")
                  _buildPlanTab(
                    context,
                    displayBudget,
                    categoriesById,
                    extraExpenseCategories,
                  ),
                if (_tab == "insights") _buildInsightsTab(displayBudget),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics(double spent, double left, double incomeActual) {
    return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: "GASTADO",
                    amount: _fmt(spent),
                    color: AppColors.o5,
                    icon: LucideIcons.trendingDown,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: "DISPONIBLE",
                    amount: _fmt(left),
                    color: AppColors.e6,
                    icon: LucideIcons.wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricCard(
              label: "INGRESOS RECIBIDOS",
              amount: _fmt(incomeActual),
              color: AppColors.e8,
              icon: LucideIcons.trendingUp,
              isWide: true,
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildSharedBudgetSection({required bool isShared}) {
    final previewMembers = _members.take(3).toList();
    final extraMembers = _members.length - previewMembers.length;
    final title = isShared
        ? 'Presupuesto compartido'
        : 'Comparte este presupuesto';
    final subtitle = _isLoadingMembers
        ? 'Cargando miembros...'
        : isShared
        ? '${_members.length} miembro${_members.length == 1 ? '' : 's'} con acceso'
        : 'Invita hasta 3 personas por email';
    final actionLabel = isShared ? 'Gestionar' : 'Invitar';

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
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.e8,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        subtitle,
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
                label: actionLabel,
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
            _InlineInfoCard(
              text: isShared
                  ? 'Todavía no hay colaboradores aceptados en este presupuesto.'
                  : 'Solo tú tienes acceso por ahora. Puedes enviar invitaciones cuando quieras.',
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
          child: _BudgetSectionTitle(title: 'Categorías del presupuesto'),
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
            child: _BudgetSectionTitle(title: 'Otros gastos fuera del plan'),
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
    BuildContext context,
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
    final otherIncomeSources = [...budget.otherIncomeSources]
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (incomeSources.isNotEmpty) ...[
          const _BudgetSectionTitle(title: 'Ingresos planificados'),
          const SizedBox(height: 10),
          _buildPlanGrid(
            context,
            incomeSources
                .map(
                  (source) => _IncomePlanRow(
                    source: source,
                    parentLabel: _parentLabelForIncome(source, categoriesById),
                    fmt: _fmt,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
        ],
        if (otherIncomeSources.isNotEmpty) ...[
          const _BudgetSectionTitle(title: 'Ingresos extra'),
          const SizedBox(height: 10),
          _buildPlanGrid(
            context,
            otherIncomeSources
                .map(
                  (source) => _IncomePlanRow(
                    source: source,
                    parentLabel: _parentLabelForIncome(source, categoriesById),
                    fmt: _fmt,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
        ],
        const _BudgetSectionTitle(title: 'Categorías con límite'),
        const SizedBox(height: 10),
        _buildPlanGrid(
          context,
          expenseCategories
              .map(
                (cat) => _PlanCategoryRow(
                  cat: cat,
                  parentLabel: _parentLabelForExpense(cat, categoriesById),
                  budgetTotal: budget.displayIncomeBase,
                  fmt: _fmt,
                ),
              )
              .toList(),
        ),
        if (extraExpenseCategories.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _BudgetSectionTitle(title: 'Gastos sin tope'),
          const SizedBox(height: 10),
          _buildPlanGrid(
            context,
            extraExpenseCategories
                .map(
                  (cat) => _UnplannedExpenseCard(
                    cat: cat,
                    parentLabel: _parentLabelForExpense(cat, categoriesById),
                    fmt: _fmt,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPlanGrid(BuildContext context, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
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

  Widget _buildInsightsTab(MenudoBudget budget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_supportsHistory)
          const _InlineInfoCard(
            text:
                'Este presupuesto es puntual, así que no genera cierres automáticos.',
          )
        else if (_isLoadingHistory && _history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          )
        else if (_historyError != null && _history.isEmpty)
          _InlineInfoCard(
            text: _historyError!,
            tone: _InfoCardTone.error,
            actionLabel: 'Reintentar',
            onTap: _loadHistory,
          )
        else if (_history.isEmpty)
          _InlineInfoCard(text: _historyEmptyMessage(budget.periodo))
        else ...[
          ..._history.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == _history.length - 1 ? 0 : 14,
              ),
              child: _HistorySnapshotCard(
                snapshot: entry.value,
                rangeLabel: _historyRangeLabel(entry.value),
                fmt: _fmtAmount,
              ),
            ),
          ),
          if (_historyHasMore) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoadingMoreHistory
                    ? null
                    : () => _loadHistory(loadMore: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.e8,
                  side: const BorderSide(color: AppColors.g2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _isLoadingMoreHistory ? 'Cargando...' : 'Cargar más cierres',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ],
    ).animate().fadeIn(duration: 350.ms);
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

class _BudgetActionOption extends StatelessWidget {
  const _BudgetActionOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.e8,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.g2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? AppColors.e8
                  : Colors.white.withValues(alpha: 0.65),
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              fontSize: 12,
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
  final bool isWide;

  const _MetricCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.isWide = false,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
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
              fontSize: isWide ? 22 : 18,
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
  final bool allowInviteWhenEmpty;

  const _BudgetMembersSheet({
    required this.budgetId,
    required this.initialMembers,
    this.allowInviteWhenEmpty = false,
  });

  @override
  ConsumerState<_BudgetMembersSheet> createState() =>
      _BudgetMembersSheetState();
}

class _BudgetMembersSheetState extends ConsumerState<_BudgetMembersSheet> {
  final TextEditingController _inviteController = TextEditingController();
  List<BudgetMember> _members = const [];
  bool _isLoading = false;
  bool _isInviting = false;
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
        _error = presentError(error);
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
      ).showSnackBar(SnackBar(content: Text(presentError(error))));
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
    return widget.allowInviteWhenEmpty && _members.isEmpty;
  }

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _inviteMember() async {
    final email = _inviteController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un correo antes de enviar la invitación.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isInviting = true);
    try {
      await ref
          .read(budgetControllerProvider.notifier)
          .inviteBudgetMember(widget.budgetId, email);
      if (!mounted) return;
      _inviteController.clear();
      await _loadMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitación enviada a $email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(presentError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isInviting = false);
      }
    }
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
                    if (_canManageMembers) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.g2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Invitar por correo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.e8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Envía acceso a este presupuesto sin volver al wizard.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.g4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _inviteController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: _isInviting
                                        ? null
                                        : (_) => _inviteMember(),
                                    decoration: InputDecoration(
                                      hintText: 'correo@ejemplo.com',
                                      filled: true,
                                      fillColor: AppColors.g1,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: AppColors.e6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    onPressed: _isInviting
                                        ? null
                                        : _inviteMember,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.e6,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isInviting
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            LucideIcons.send,
                                            size: 18,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: _InlineInfoCard(
                          text: _canManageMembers
                              ? 'Todavía no hay miembros aceptados. Las invitaciones nuevas aparecerán aquí cuando la persona se una.'
                              : 'Este presupuesto todavía no tiene miembros adicionales.',
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
                    _InlineInfoCard(
                      text: _canManageMembers
                          ? 'Puedes invitar nuevos colaboradores o quitar acceso a los miembros actuales.'
                          : 'Aquí puedes revisar quién tiene acceso a este presupuesto.',
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
          color: over ? AppColors.o5.withValues(alpha: 0.3) : AppColors.g2,
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
                  color: AppColors.o5,
                  bgColor: AppColors.o1,
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
                over ? AppColors.o5 : cat.color,
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
                  color: over ? AppColors.o5 : AppColors.e6,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.o1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BudgetPlanIcon(color: AppColors.o5, icon: cat.icono),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.e8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parentLabel.isEmpty
                      ? 'Sin tope definido'
                      : '$parentLabel · Sin tope definido',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.g4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt(cat.gastado),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.o5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.o1,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Sin tope',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.o5,
                  ),
                ),
              ),
            ],
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
    final usage = cat.limite > 0 ? (cat.gastado / cat.limite) : 0.0;
    final over = usage > 1;
    final statusColor = over ? AppColors.o5 : AppColors.e6;
    final balance = cat.limite - cat.gastado;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: over ? AppColors.o5.withValues(alpha: 0.24) : AppColors.g2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BudgetPlanIcon(color: cat.color, icon: cat.icono),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.e8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      parentLabel.isEmpty
                          ? 'Límite ${fmt(cat.limite)}'
                          : '$parentLabel · Límite ${fmt(cat.limite)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.g4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt(cat.gastado),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    over
                        ? 'Se pasó ${fmt(cat.gastado - cat.limite)}'
                        : 'Quedan ${fmt(balance)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: usage.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.g1,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Gastado ${fmt(cat.gastado)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.g5,
                ),
              ),
              const Spacer(),
              Text(
                '$pct% del ingreso disponible',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.g4,
                ),
              ),
            ],
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
    final accent = isPositive ? AppColors.e6 : AppColors.o5;
    final plannedBase = source.planned > 0 ? source.planned : source.actual;
    final progress = plannedBase > 0 ? (source.actual / plannedBase) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: source.color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BudgetPlanIcon(color: source.color, icon: source.icono),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.e8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      parentLabel.isEmpty
                          ? (source.planned > 0
                                ? 'Plan ${fmt(source.planned)}'
                                : 'Sin plan configurado')
                          : source.planned > 0
                          ? '$parentLabel · Plan ${fmt(source.planned)}'
                          : '$parentLabel · Sin plan configurado',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.g4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt(source.actual),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    source.difference == 0
                        ? 'En línea'
                        : isPositive
                        ? '+${fmt(source.difference)}'
                        : '-${fmt(source.difference.abs())}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (source.planned > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: AppColors.g1,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 10),
          Text(
            source.planned <= 0
                ? 'Este ingreso no tenía monto previsto en tu presupuesto.'
                : source.difference == 0
                ? 'Va exactamente como lo planeado.'
                : isPositive
                ? 'Recibiste ${fmt(source.difference)} por encima del plan.'
                : 'Faltan ${fmt(source.difference.abs())} para llegar al objetivo.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetPlanIcon extends StatelessWidget {
  const _BudgetPlanIcon({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: color),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySnapshotCard extends StatelessWidget {
  const _HistorySnapshotCard({
    required this.snapshot,
    required this.rangeLabel,
    required this.fmt,
  });

  final BudgetHistorySnapshot snapshot;
  final String rangeLabel;
  final String Function(double value, {String currency, bool signed}) fmt;

  @override
  Widget build(BuildContext context) {
    final topCategory = snapshot.categoriaMasAlta;
    final usesPlannedIncome = snapshot.ingresosPresupuestados > 0;
    final headlineValue = usesPlannedIncome
        ? snapshot.sobroPresupuesto
        : snapshot.balance;
    final headlineColor = headlineValue >= 0 ? AppColors.e6 : AppColors.r5;
    final headline = usesPlannedIncome
        ? (headlineValue > 0
              ? 'Te quedaron ${fmt(headlineValue)} del plan'
              : headlineValue < 0
              ? 'Te pasaste por ${fmt(headlineValue.abs())}'
              : 'Cerraste justo con tu plan')
        : (headlineValue >= 0
              ? 'Cerraste con ${fmt(headlineValue)} disponibles'
              : 'Cerraste con ${fmt(headlineValue.abs())} en rojo');
    final subtitle =
        '${_periodLabel(snapshot.periodo)} · ${snapshot.totalTransacciones} movimiento${snapshot.totalTransacciones == 1 ? '' : 's'}';

    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.e1,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _periodLabel(snapshot.periodo).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.e6,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                rangeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.g4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            headline,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: headlineColor,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.g5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HistoryValue(
                  label: 'Ingresó',
                  value: fmt(snapshot.ingresosReales),
                  color: AppColors.e6,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HistoryValue(
                  label: 'Gastó',
                  value: fmt(snapshot.totalGastos),
                  color: AppColors.o5,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HistoryValue(
                  label: 'Balance',
                  value: fmt(snapshot.balance),
                  color: snapshot.balance >= 0 ? AppColors.e8 : AppColors.r5,
                ),
              ),
            ],
          ),
          if (topCategory != null ||
              snapshot.totalOtrosGastos > 0 ||
              snapshot.totalOtrosIngresos > 0) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (topCategory != null && topCategory.label.trim().isNotEmpty)
                  _HistoryTag(
                    icon: topCategory.icono,
                    label: 'Más gasto: ${topCategory.label}',
                  ),
                if (snapshot.totalOtrosGastos > 0)
                  _HistoryTag(
                    icon: LucideIcons.alertCircle,
                    label: 'Fuera del plan ${fmt(snapshot.totalOtrosGastos)}',
                    color: AppColors.o5,
                  ),
                if (snapshot.totalOtrosIngresos > 0)
                  _HistoryTag(
                    icon: LucideIcons.sparkles,
                    label: 'Ingresos extra ${fmt(snapshot.totalOtrosIngresos)}',
                    color: AppColors.e6,
                  ),
              ],
            ),
          ],
          if (snapshot.transacciones.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.g2),
            const SizedBox(height: 14),
            const Text(
              'Últimos movimientos de ese cierre',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.g5,
              ),
            ),
            const SizedBox(height: 10),
            ...snapshot.transacciones
                .take(3)
                .toList()
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(bottom: entry.key == 2 ? 0 : 10),
                    child: _HistoryTransactionRow(
                      transaction: entry.value,
                      fmt: fmt,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  static String _periodLabel(String periodo) {
    switch (periodo) {
      case 'semanal':
        return 'Cierre semanal';
      case 'quincenal':
        return 'Cierre quincenal';
      case 'mensual':
        return 'Cierre mensual';
      default:
        return 'Cierre';
    }
  }
}

class _HistoryValue extends StatelessWidget {
  const _HistoryValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.g4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTag extends StatelessWidget {
  const _HistoryTag({
    required this.icon,
    required this.label,
    this.color = AppColors.e8,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTransactionRow extends StatelessWidget {
  const _HistoryTransactionRow({required this.transaction, required this.fmt});

  final BudgetHistoryTransaction transaction;
  final String Function(double value, {String currency, bool signed}) fmt;

  @override
  Widget build(BuildContext context) {
    final amount = transaction.signedAmount;
    final amountColor = amount >= 0 ? AppColors.e6 : AppColors.o5;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: amountColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(transaction.categoriaIcono, size: 16, color: amountColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.descripcion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.e8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if ((transaction.categoriaNombre ?? '').isNotEmpty)
                    transaction.categoriaNombre!,
                  if ((transaction.usuarioNombre ?? '').isNotEmpty)
                    transaction.usuarioNombre!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.g4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          fmt(amount, currency: transaction.moneda, signed: true),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SmallActionButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.g1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.g2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.g5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
