import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../controllers/demo_mode_controller.dart';
import '../../../core/utils/error_presenter.dart';
import '../../alerts/providers/alert_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../shared/widgets/menudo_loading_view.dart';
import '../../auth/auth_state.dart';
import '../../budgets/budget_providers.dart';
import '../../budgets/presentation/budget_detail_sheet.dart';
import '../../budgets/presentation/wizard/create_budget_wizard.dart';
import '../../quick_log/presentation/register_transaction_sheet.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
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
        content: Text(presentError(error)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    try {
      ref.invalidate(unreadAlertsCountProvider);
      await Future.wait([
        ref.read(walletNotifierProvider.notifier).refresh(),
        ref.read(budgetNotifierProvider.notifier).refresh(),
      ]);
      await ref.read(transactionNotifierProvider.notifier).refresh();
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
                    'Todavía no hay actividad.',
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
                        ? 'Esta cuenta todavía no tiene movimientos reales.'
                        : 'Crea tu primer presupuesto para empezar a ver todo aquí.',
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
                    child: const Text('Ir a ajustes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openRegisterSheet(
    BuildContext context, {
    String initialType = 'gasto',
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegisterTransactionSheet(initialType: initialType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetsState = ref.watch(budgetNotifierProvider);
    final walletsState = ref.watch(walletNotifierProvider);
    final transactionsState = ref.watch(transactionNotifierProvider);
    final budgets = ref.watch(effectiveBudgetsProvider);
    final txnsThisPeriod = ref.watch(selectedBudgetPeriodTransactionsProvider);
    final wallets = ref.watch(effectiveWalletsProvider);
    final defaultWallet = ref.watch(defaultWalletProvider);
    final demoMode = ref.watch(demoModeProvider);
    final authState = ref.watch(authProvider);
    final unreadAlerts = ref
        .watch(unreadAlertsCountProvider)
        .maybeWhen(data: (count) => count, orElse: () => 0);
    final greetingName = _firstName(authState.profile?.name);
    final isHydratingHome =
        authState.isBootstrapping ||
        (budgetsState.isLoading && budgetsState.valueOrNull == null) ||
        (walletsState.isLoading && walletsState.valueOrNull == null) ||
        (transactionsState.isLoading && transactionsState.valueOrNull == null);

    if (isHydratingHome) {
      return const Scaffold(
        backgroundColor: AppColors.g0,
        body: SafeArea(
          child: MenudoLoadingView(
            title: 'Cargando tu resumen',
            message: 'Estamos preparando tus presupuestos y movimientos.',
          ),
        ),
      );
    }

    if (budgets.isEmpty) {
      return _buildEmptyDashboard(context, demoMode);
    }

    _maybeShowWalletTour(wallets, demoMode);
    _maybeShowBudgetTour(budgets, txnsThisPeriod, wallets, demoMode);

    final budget = ref.watch(selectedBudgetProvider) ?? budgets.first;
    final hasIncomePlan = budget.ingresos > 0;
    final double spent = budget.totalSpent;
    final double plannedRemaining = budget.ingresos - spent;
    final double actualCashflow = budget.actualIncomeTotal - spent;
    final double primaryAmount = hasIncomePlan
        ? plannedRemaining
        : actualCashflow;

    final recent = txnsThisPeriod
        .where((t) => t.tipo != 'transferencia')
        .take(3)
        .toList();

    final periodoLabel =
        {
          'mensual': 'este mes',
          'quincenal': 'esta quincena',
          'semanal': 'esta semana',
          'unico': 'este periodo',
        }[budget.periodo.toLowerCase()] ??
        budget.periodo.toLowerCase();
    final hour = TimeOfDay.now().hour;
    final salutation = hour < 12
        ? 'Buenos días,'
        : hour < 18
        ? 'Buenas tardes,'
        : 'Buenas noches,';
    final avatarLabel = greetingName?.trim().isNotEmpty == true
        ? greetingName!.trim().substring(0, 1).toUpperCase()
        : 'M';

    return Scaffold(
      backgroundColor: AppColors.g0,
      body: SafeArea(
        child: RefreshIndicator.adaptive(
          onRefresh: _refreshDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.e1,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              avatarLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.e8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                salutation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.g4,
                                ),
                              ),
                              Text(
                                greetingName ?? 'Mi cuenta',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.e8,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      _HeaderCircleButton(
                        icon: LucideIcons.bell,
                        badgeCount: unreadAlerts,
                        onTap: () => context.push('/alerts'),
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.05, end: 0, curve: Curves.easeOutBack),

              const SizedBox(height: 22),
              _buildBudgetCard(
                    context,
                    budget,
                    primaryAmount: primaryAmount,
                    defaultWallet: defaultWallet,
                    hasIncomePlan: hasIncomePlan,
                    periodLabel: periodoLabel,
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 100.ms)
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    curve: Curves.easeOutBack,
                    delay: 100.ms,
                  ),

              const SizedBox(height: 20),
              _buildActionGrid(context)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 18),
              _buildSummaryCard(
                    amount: primaryAmount,
                    hasIncomePlan: hasIncomePlan,
                    periodLabel: periodoLabel,
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 28),
              _SectionHeader(
                title: "Recientes",
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
              ).animate().fadeIn(duration: 400.ms, delay: 440.ms),

              const SizedBox(height: 4),

              _buildRecentTransactions(budget, recent)
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 520.ms)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    MenudoBudget budget, {
    required double primaryAmount,
    required WalletAccount? defaultWallet,
    required bool hasIncomePlan,
    required String periodLabel,
  }) {
    final accountLabel = defaultWallet?.nombre ?? budget.nombre;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BudgetDetailSheet(budget: budget),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.e8,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.e8.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.wallet,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            accountLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BudgetDetailSheet(budget: budget),
                    );
                  },
                  child: Icon(
                    LucideIcons.moreHorizontal,
                    color: Colors.white.withValues(alpha: 0.86),
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Disponible de $periodLabel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.76),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 52,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _fmt(primaryAmount),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _BudgetMetaPill(
                    label: hasIncomePlan ? 'Presupuesto' : 'Ingresos',
                    value: _fmt(
                      hasIncomePlan
                          ? budget.ingresos
                          : budget.actualIncomeTotal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BudgetMetaPill(
                    label: 'Gastado',
                    value: _fmt(budget.totalSpent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      (
        icon: LucideIcons.arrowDownLeft,
        label: 'Ingreso',
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFEF3C7),
        onTap: () => _openRegisterSheet(context, initialType: 'ingreso'),
      ),
      (
        icon: LucideIcons.arrowUpRight,
        label: 'Gasto',
        color: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFFE4E6),
        onTap: () => _openRegisterSheet(context),
      ),
      (
        icon: LucideIcons.repeat2,
        label: 'Transferir',
        color: AppColors.b5,
        bgColor: const Color(0xFFDBEAFE),
        onTap: () => _openRegisterSheet(context, initialType: 'transferencia'),
      ),
      (
        icon: LucideIcons.layoutGrid,
        label: 'Más',
        color: AppColors.g5,
        bgColor: AppColors.g1,
        onTap: () => context.push('/tools'),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(
            child: _QuickAction(
              icon: actions[i].icon,
              label: actions[i].label,
              color: actions[i].color,
              bgColor: actions[i].bgColor,
              onTap: actions[i].onTap,
            ),
          ),
          if (i != actions.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildSummaryCard({
    required double amount,
    required bool hasIncomePlan,
    required String periodLabel,
  }) {
    final positive = amount >= 0;
    final statusColor = positive ? AppColors.e6 : AppColors.o5;
    final message = hasIncomePlan
        ? positive
              ? 'Te quedan ${_fmt(amount)} del plan.'
              : 'Vas ${_fmt(amount.abs())} por encima del plan.'
        : positive
        ? 'Cierre neto de ${_fmt(amount)} en $periodLabel.'
        : 'Balance de ${_fmt(amount.abs())} en rojo.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.g2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.clock3,
              size: 18,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen del periodo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.e8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.g5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              positive ? 'Al día' : 'Revisar',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(
    MenudoBudget budget,
    List<MenudoTransaction> recent,
  ) {
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.g2),
        ),
        child: const Text(
          'Todavía no hay movimientos en este periodo.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.g5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

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
            subtitle: _buildRecentSubtitle(t, cat?.label ?? t.catKey),
            color: color,
            isLast: i == recent.length - 1,
            onTap: (context) {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
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

  String _buildRecentSubtitle(
    MenudoTransaction transaction,
    String categoryName,
  ) {
    final normalizedCategory = categoryName.trim();
    final normalizedDesc = transaction.desc.trim();
    final date = _compactDate(transaction.dateString);
    if (normalizedCategory.isEmpty) return date;
    if (normalizedCategory.toLowerCase() == normalizedDesc.toLowerCase()) {
      return date;
    }
    return '$normalizedCategory · $date';
  }

  String _compactDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return value;
    const months = {
      '01': 'ene',
      '02': 'feb',
      '03': 'mar',
      '04': 'abr',
      '05': 'may',
      '06': 'jun',
      '07': 'jul',
      '08': 'ago',
      '09': 'sep',
      '10': 'oct',
      '11': 'nov',
      '12': 'dic',
    };
    return '${int.tryParse(parts[2]) ?? parts[2]} ${months[parts[1]] ?? parts[1]}';
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.g2, width: 1.5),
            ),
            child: Icon(icon, size: 20, color: AppColors.e8),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.o5,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 9 ? '9+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.g5,
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

class _TransactionTile extends StatelessWidget {
  final MenudoTransaction transaction;
  final String subtitle;
  final Color color;
  final bool isLast;
  final Function(BuildContext) onTap;

  const _TransactionTile({
    required this.transaction,
    required this.subtitle,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                        subtitle,
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

class _BudgetMetaPill extends StatelessWidget {
  final String label;
  final String value;

  const _BudgetMetaPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.52),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
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
              child: const Text('Agregar cuenta ahora'),
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
