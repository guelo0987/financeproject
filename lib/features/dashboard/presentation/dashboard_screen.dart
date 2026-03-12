import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../controllers/demo_mode_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../shared/widgets/menudo_chip.dart';
import '../../auth/auth_state.dart';
import '../../budgets/budget_providers.dart';
import '../../budgets/presentation/budget_detail_sheet.dart';
import '../../budgets/presentation/wizard/create_budget_wizard.dart';
import '../../quick_log/presentation/register_transaction_sheet.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../transactions/presentation/spending_breakdown_sheet.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallet/presentation/add_wallet_sheet.dart';
import '../../wallet/providers/wallet_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _didShowWalletTour = false;
  bool _didShowBudgetTour = false;

  String _fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";

  String? _firstName(String? fullName) {
    final name = fullName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _activateBudget(MenudoBudget budget) async {
    try {
      await ref.read(budgetNotifierProvider.notifier).activateBudget(budget.id);
    } catch (error) {
      _showError(error);
    }
  }

  bool _needsWalletTour(List<WalletAccount> wallets, bool demoMode) {
    return !demoMode && wallets.isEmpty;
  }

  bool _needsBudgetTour(
    List<MenudoBudget> budgets,
    List<MenudoTransaction> txnsThisPeriod,
    bool demoMode,
  ) {
    if (demoMode || budgets.length != 1) return false;
    final budget = budgets.first;
    return budget.nombre.toLowerCase() == 'predeterminado' &&
        budget.ingresos == 0 &&
        budget.cats.isEmpty &&
        txnsThisPeriod.isEmpty;
  }

  void _maybeShowBudgetTour(
    List<MenudoBudget> budgets,
    List<MenudoTransaction> txnsThisPeriod,
    List<WalletAccount> wallets,
    bool demoMode,
  ) {
    if (_didShowBudgetTour ||
        wallets.isEmpty ||
        !_needsBudgetTour(budgets, txnsThisPeriod, demoMode) ||
        !mounted) {
      return;
    }

    _didShowBudgetTour = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final baseBudget = budgets.first;

      final configureNow = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _BudgetSetupTourSheet(),
      );

      if (configureNow == true && mounted) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CreateBudgetWizard(initialBudget: baseBudget),
        );
      }
    });
  }

  void _maybeShowWalletTour(List<WalletAccount> wallets, bool demoMode) {
    if (_didShowWalletTour ||
        !_needsWalletTour(wallets, demoMode) ||
        !mounted) {
      return;
    }

    _didShowWalletTour = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final configureNow = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _WalletSetupTourSheet(),
      );

      if (configureNow != true || !mounted) return;

      final wallet = await showModalBottomSheet<WalletAccount>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddWalletSheet(),
      );

      if (wallet == null || !mounted) return;

      try {
        await ref.read(walletNotifierProvider.notifier).addWallet(wallet);
      } catch (error) {
        _showError(error);
      }
    });
  }

  Widget _buildEmptyDashboard(BuildContext context, bool demoMode) {
    return Scaffold(
      backgroundColor: AppColors.g0,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.e1,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.layoutGrid,
                      color: AppColors.e8,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu cuenta todavía no tiene datos.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.e8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    demoMode
                        ? 'Estás viendo datos demo porque esa opción está activa.'
                        : 'Crea tu primer presupuesto para empezar a configurar la app.',
                    style: const TextStyle(fontSize: 13, color: AppColors.g4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => context.push('/budgets'),
                    child: const Text('Ir a presupuestos'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/settings'),
                    child: const Text('Ajustes y datos demo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(effectiveBudgetsProvider);
    final txnsThisPeriod = ref.watch(selectedBudgetPeriodTransactionsProvider);
    final wallets = ref.watch(effectiveWalletsProvider);
    final demoMode = ref.watch(demoModeProvider);
    final authState = ref.watch(authProvider);
    final greetingName = _firstName(authState.profile?.name);

    if (budgets.isEmpty) {
      return _buildEmptyDashboard(context, demoMode);
    }

    _maybeShowWalletTour(wallets, demoMode);
    _maybeShowBudgetTour(budgets, txnsThisPeriod, wallets, demoMode);

    final selectedIdx = ref
        .watch(selectedBudgetIdxProvider)
        .clamp(0, budgets.length - 1);
    final budget = ref.watch(selectedBudgetProvider) ?? budgets[selectedIdx];
    final double spent = budget.totalSpent;
    final double remaining = budget.ingresos - spent;
    final double pct = spent / (budget.ingresos > 0 ? budget.ingresos : 1);

    final double ingresos = txnsThisPeriod
        .where((t) => t.tipo == 'ingreso')
        .fold(0.0, (s, t) => s + t.monto.abs());
    final double gastos = spent;
    final recent = txnsThisPeriod
        .where((t) => t.tipo != 'transferencia')
        .take(4)
        .toList();

    final periodoLabel =
        {
          'mensual': 'este mes',
          'quincenal': 'esta quincena',
          'semanal': 'esta semana',
          'unico': 'este periodo',
        }[budget.periodo.toLowerCase()] ??
        budget.periodo.toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.g0,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            // ── Header ────────────────────────────────────────────────
            Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greetingName == null
                                ? "Hola"
                                : "Hola, $greetingName",
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
                    ),
                    const SizedBox(width: 12),
                    _HeaderCircleButton(
                      icon: LucideIcons.settings,
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.05, end: 0, curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            // ── Budget Card ────────────────────────────────────────────
            _buildBudgetCard(
                  context,
                  ref,
                  budgets,
                  budget,
                  selectedIdx,
                  remaining,
                  pct,
                  periodoLabel,
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms)
                .scale(
                  begin: const Offset(0.95, 0.95),
                  curve: Curves.easeOutBack,
                  delay: 100.ms,
                ),

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
                        onTap: () => _showBreakdown(
                          context,
                          txnsThisPeriod,
                          true,
                          periodoLabel,
                        ),
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
                        onTap: () => _showBreakdown(
                          context,
                          txnsThisPeriod,
                          false,
                          periodoLabel,
                        ),
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 20),

            // ── Action Grid ────────────────────────────────────────────
            const _SectionHeader(
              title: "Accesos rápidos",
            ).animate().fadeIn(duration: 400.ms, delay: 360.ms),

            const SizedBox(height: 12),

            _buildActionGrid(context)
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 32),

            // ── Recent Transactions ────────────────────────────────────
            _SectionHeader(
              title: "Transacciones recientes",
              trailing: TextButton(
                onPressed: () => context.push('/history'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Ver todo",
                      style: TextStyle(
                        color: AppColors.o5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: AppColors.o5,
                    ),
                  ],
                ),
              ),
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

  void _showBreakdown(
    BuildContext context,
    List<MenudoTransaction> txns,
    bool isGastos,
    String label,
  ) {
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

  Widget _buildBudgetCard(
    BuildContext context,
    WidgetRef ref,
    List<MenudoBudget> budgets,
    MenudoBudget budget,
    int selectedIdx,
    double remaining,
    double pct,
    String periodoLabel,
  ) {
    final highlightCategories = [...budget.spendingCategories]
      ..sort((a, b) => b.gastado.compareTo(a.gastado));
    final unplannedCount = budget.otherExpenses.length;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.e8, Color(0xFF0A7A5D)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.e8.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.nombre,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          MenudoChip.custom(
                            label: budget.periodo.toUpperCase(),
                            color: Colors.white,
                            bgColor: Colors.white.withValues(alpha: 0.15),
                            isSmall: true,
                          ),
                          if (unplannedCount > 0)
                            MenudoChip.custom(
                              label: '$unplannedCount fuera del plan',
                              color: Colors.white,
                              bgColor: Colors.white.withValues(alpha: 0.12),
                              isSmall: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildVerButton(context, budget),
              ],
            ),
          ),

          _buildBudgetSelector(ref, budgets, selectedIdx),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _BudgetAccentPill(
                      icon: LucideIcons.trendingDown,
                      label: 'Gastado',
                      value: _fmt(budget.totalSpent),
                    ),
                    if (budget.ahorroObjetivo > 0)
                      _BudgetAccentPill(
                        icon: LucideIcons.piggyBank,
                        label: 'Meta ahorro',
                        value: _fmt(budget.ahorroObjetivo),
                      ),
                    if (unplannedCount > 0)
                      _BudgetAccentPill(
                        icon: LucideIcons.alertCircle,
                        label: 'Fuera plan',
                        value: '$unplannedCount',
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  "SALDO DISPONIBLE",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmt(remaining),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        "/ ${_fmt(budget.ingresos)}",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w600,
                        ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (highlightCategories.isNotEmpty)
                  Text(
                    'Top gastos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ...highlightCategories
                    .take(3)
                    .map((cat) => _buildCategoryRow(cat)),
              ],
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
        child: const Text(
          "Detalles",
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetSelector(
    WidgetRef ref,
    List<MenudoBudget> budgets,
    int selectedIdx,
  ) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: budgets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final b = budgets[i];
          final isSelected = i == selectedIdx;
          return GestureDetector(
            onTap: () async {
              HapticFeedback.selectionClick();
              await _activateBudget(b);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                b.nombre,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.e8
                      : Colors.white.withValues(alpha: 0.6),
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

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      (
        icon: LucideIcons.pieChart,
        label: 'Categorías',
        color: AppColors.e6,
        bgColor: AppColors.e1,
        onTap: () => context.push('/categories'),
      ),
      (
        icon: LucideIcons.repeat2,
        label: 'Automáticas',
        color: AppColors.o5,
        bgColor: AppColors.o1,
        onTap: () => context.push('/recurring'),
      ),
      (
        icon: LucideIcons.clock,
        label: 'Historial',
        color: AppColors.e8,
        bgColor: AppColors.e0,
        onTap: () => context.push('/history'),
      ),
      (
        icon: LucideIcons.wrench,
        label: 'Herramientas',
        color: AppColors.o5,
        bgColor: AppColors.o1,
        onTap: () => context.push('/tools'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions
              .map(
                (action) => SizedBox(
                  width: itemWidth,
                  child: _QuickAction(
                    icon: action.icon,
                    label: action.label,
                    color: action.color,
                    bgColor: action.bgColor,
                    onTap: action.onTap,
                  ),
                ),
              )
              .toList(),
        );
      },
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
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _fmt(budget.ahorroObjetivo),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
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
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (_, constraints) => AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutQuart,
              width: constraints.maxWidth * min(pct, 1.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: pct > 0.9
                      ? [AppColors.r5, AppColors.r5.withValues(alpha: 0.7)]
                      : [const Color(0xFF6EE7B7), const Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  if (pct < 0.9)
                    BoxShadow(
                      color: const Color(0xFF6EE7B7).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${(pct * 100).round()}% usado",
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.4),
            fontWeight: FontWeight.w500,
          ),
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
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(cat.icono, size: 14, color: cat.color),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    cat.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(cat.gastado),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "${(p * 100).round()}%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: p,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(
                p > 0.95 ? AppColors.r5 : cat.color,
              ),
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
            BoxShadow(
              color: AppColors.o5.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plusCircle, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              "NUEVA TRANSACCIÓN",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
    MenudoBudget budget,
    List<MenudoTransaction> recent,
  ) {
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
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
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

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

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
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                Icon(LucideIcons.chevronRight, size: 14, color: AppColors.g3),
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
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
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

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 98),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.g2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.e8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.e8,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _BudgetAccentPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BudgetAccentPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.45),
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
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

  const _TransactionTile({
    required this.transaction,
    required this.categoryName,
    required this.color,
    required this.isLast,
    required this.onTap,
  });

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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(transaction.icono, size: 20, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.desc,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.e8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$categoryName · ${transaction.dateString}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.g4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  transaction.tipo == "ingreso"
                      ? "+RD\$${transaction.monto.abs().toInt()}"
                      : "-RD\$${transaction.monto.abs().toInt()}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: transaction.tipo == "ingreso"
                        ? AppColors.e6
                        : AppColors.e8,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(height: 1, color: AppColors.g1, indent: 74, endIndent: 16),
        ],
      ),
    );
  }
}

class _BudgetSetupTourSheet extends StatelessWidget {
  const _BudgetSetupTourSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.g2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Configura tu presupuesto base',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu cuenta ya tiene un presupuesto base, pero falta personalizarlo para que el dashboard y los gastos tengan sentido.',
            style: TextStyle(fontSize: 14, color: AppColors.g4),
          ),
          const SizedBox(height: 20),
          const _TourPoint(
            icon: LucideIcons.wallet,
            title: '1. Define tus ingresos',
            body:
                'Usa el monto real del periodo para que el resumen empiece correcto.',
          ),
          const SizedBox(height: 12),
          const _TourPoint(
            icon: LucideIcons.pieChart,
            title: '2. Reparte tus categorías',
            body:
                'Asigna límites por categoría para ver gastos relevantes por presupuesto.',
          ),
          const SizedBox(height: 12),
          const _TourPoint(
            icon: LucideIcons.repeat2,
            title: '3. Luego registra movimientos',
            body:
                'Las transacciones y automáticas quedarán ligadas a ese presupuesto.',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Configurar ahora'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ahora no'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletSetupTourSheet extends StatelessWidget {
  const _WalletSetupTourSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.g2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Agrega tu primera cuenta',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Antes de registrar movimientos, necesitas al menos una wallet para indicar de dónde sale o entra el dinero.',
            style: TextStyle(fontSize: 14, color: AppColors.g4),
          ),
          const SizedBox(height: 20),
          const _TourPoint(
            icon: LucideIcons.landmark,
            title: '1. Crea tu cuenta principal',
            body: 'Puede ser banco, efectivo, ahorro o tarjeta.',
          ),
          const SizedBox(height: 12),
          const _TourPoint(
            icon: LucideIcons.creditCard,
            title: '2. Define el saldo inicial',
            body:
                'Así la cartera arranca con el valor real desde el primer día.',
          ),
          const SizedBox(height: 12),
          const _TourPoint(
            icon: LucideIcons.repeat2,
            title: '3. Luego configuras el presupuesto',
            body:
                'Con la cuenta lista, ya puedes registrar gastos, ingresos y transferencias.',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Crear wallet ahora'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ahora no'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _TourPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.e1,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.e8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.e8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(fontSize: 12, color: AppColors.g4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
