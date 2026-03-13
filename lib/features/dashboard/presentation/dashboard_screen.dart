import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../controllers/demo_mode_controller.dart';
import '../../alerts/providers/alert_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../shared/widgets/menudo_chip.dart';
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
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    final unreadAlerts = ref
        .watch(unreadAlertsCountProvider)
        .maybeWhen(data: (count) => count, orElse: () => 0);
    final greetingName = _firstName(authState.profile?.name);

    if (budgets.isEmpty) {
      return _buildEmptyDashboard(context, demoMode);
    }

    _maybeShowWalletTour(wallets, demoMode);
    _maybeShowBudgetTour(budgets, txnsThisPeriod, wallets, demoMode);

    final budget = ref.watch(selectedBudgetProvider) ?? budgets.first;
    final double spent = budget.totalSpent;
    final double remaining = budget.availableToSpend;
    final double pct = budget.displayIncomeBase > 0
        ? spent / budget.displayIncomeBase
        : 0;

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
                    Row(
                      children: [
                        _HeaderCircleButton(
                          icon: LucideIcons.bell,
                          badgeCount: unreadAlerts,
                          onTap: () => context.push('/alerts'),
                        ),
                        const SizedBox(width: 10),
                        _HeaderCircleButton(
                          icon: LucideIcons.settings,
                          onTap: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.05, end: 0, curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            // ── Budget Card ────────────────────────────────────────────
            _buildBudgetCard(context, budget, remaining, pct)
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

            // ── Action Grid ────────────────────────────────────────────
            const _SectionHeader(
              title: "Accesos rápidos",
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

            const SizedBox(height: 12),

            _buildActionGrid(context)
                .animate()
                .fadeIn(duration: 400.ms, delay: 360.ms)
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
            ).animate().fadeIn(duration: 400.ms, delay: 440.ms),

            const SizedBox(height: 4),

            _buildRecentTransactions(budget, recent)
                .animate()
                .fadeIn(duration: 500.ms, delay: 520.ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    MenudoBudget budget,
    double remaining,
    double pct,
  ) {
    final highlightCategories = [...budget.spendingCategories]
      ..sort((a, b) => b.gastado.compareTo(a.gastado));
    final isShared = budget.miembros.length > 1 || budget.espacioId != null;
    BudgetCategory? topCategory;
    for (final category in highlightCategories) {
      if (category.gastado > 0) {
        topCategory = category;
        break;
      }
    }
    final progress = pct.clamp(0.0, 1.0);
    final incomePlanLabel = budget.ingresos > 0
        ? 'Plan ${_fmt(budget.ingresos)}'
        : 'Sin plan';

    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                          if (isShared)
                            MenudoChip.custom(
                              label: 'COMPARTIDO',
                              color: AppColors.e1,
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

          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DISPONIBLE",
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
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _BudgetMetaPill(
                      label: incomePlanLabel,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    if (budget.actualIncomeTotal > 0)
                      _BudgetMetaPill(
                        label: 'Ingresos ${_fmt(budget.actualIncomeTotal)}',
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildMainProgressBar(progress),
                if (topCategory != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.o5,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mayor gasto: ${topCategory.label} · ${_fmt(topCategory.gastado)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Gastado ${_fmt(budget.totalSpent)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.76),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}% del periodo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.52),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BudgetDetailSheet(budget: budget),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: const Text(
          "Detalles",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      (
        icon: LucideIcons.layoutGrid,
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

  Widget _buildMainProgressBar(double pct) {
    return Container(
      height: 7,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) => AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutQuart,
          width: constraints.maxWidth * pct,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: pct > 0.9
                  ? [AppColors.o5, const Color(0xFFF59E0B)]
                  : [const Color(0xFF6EE7B7), const Color(0xFF34D399)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLogButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const RegisterTransactionSheet(),
        );
      },
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.o5,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.o5.withValues(alpha: 0.2),
              blurRadius: 14,
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
              "Nueva transacción",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.1,
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
      child: Container(
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.g2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
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
  final Color backgroundColor;

  const _BudgetMetaPill({required this.label, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
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
