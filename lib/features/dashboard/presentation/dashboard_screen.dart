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

  String _fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";

  String? _displayName(String? fullName) {
    final name = fullName?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
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
      await Future.wait([ref.read(walletNotifierProvider.notifier).refresh()]);
      await ref.read(transactionNotifierProvider.notifier).refresh();
    } catch (error) {
      _showError(error);
    }
  }

  bool _needsWalletTour(List<WalletAccount> wallets, bool demoMode) {
    return !demoMode && wallets.isEmpty;
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
                        : 'Agrega una cuenta y registra tu primer movimiento para ver el resumen aquí.',
                    style: const TextStyle(fontSize: 13, color: AppColors.g4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => context.push('/wallet'),
                    child: const Text('Ir a cuentas'),
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
    final walletsState = ref.watch(walletNotifierProvider);
    final transactionsState = ref.watch(transactionNotifierProvider);
    final allTransactions = ref.watch(effectiveTransactionsProvider);
    final monthlyIncome = ref.watch(generalMonthlyIncomeProvider);
    final monthlySpent = ref.watch(generalMonthlySpentProvider);
    final monthlyBalance = ref.watch(generalMonthlyBalanceProvider);
    final totalAvailable = ref.watch(totalBalanceProvider);
    final wallets = ref.watch(effectiveWalletsProvider);
    final defaultWallet = ref.watch(defaultWalletProvider);
    final demoMode = ref.watch(demoModeProvider);
    final authState = ref.watch(authProvider);
    final unreadAlerts = ref
        .watch(unreadAlertsCountProvider)
        .maybeWhen(data: (count) => count, orElse: () => 0);
    final displayName = _displayName(authState.profile?.name);
    final avatarEmoji = authState.profile?.avatarEmoji?.trim();
    final isHydratingHome =
        authState.isBootstrapping ||
        (walletsState.isLoading && walletsState.valueOrNull == null) ||
        (transactionsState.isLoading && transactionsState.valueOrNull == null);

    if (isHydratingHome) {
      return const Scaffold(
        backgroundColor: AppColors.g0,
        body: SafeArea(
          child: MenudoLoadingView(
            title: 'Cargando tu resumen',
            message: 'Estamos preparando tus cuentas y movimientos.',
          ),
        ),
      );
    }

    if (wallets.isEmpty && allTransactions.isEmpty) {
      return _buildEmptyDashboard(context, demoMode);
    }

    _maybeShowWalletTour(wallets, demoMode);

    final recent = allTransactions
        .where((t) => t.tipo != 'transferencia')
        .take(3)
        .toList();
    final avatarLabel = displayName?.trim().isNotEmpty == true
        ? displayName!.trim().substring(0, 1).toUpperCase()
        : 'M';
    final headerTitle = displayName?.isNotEmpty == true
        ? displayName!
        : 'Mi perfil';

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
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/settings'),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.e1,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.e6.withValues(alpha: 0.12),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child:
                                    avatarEmoji != null &&
                                        avatarEmoji.isNotEmpty
                                    ? Text(
                                        avatarEmoji,
                                        style: const TextStyle(fontSize: 24),
                                      )
                                    : Text(
                                        avatarLabel,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.e8,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  headerTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.e8,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

              const SizedBox(height: 22),
              _buildOverviewCard(
                    context,
                    accountLabel: wallets.length == 1
                        ? (defaultWallet?.nombre ?? 'Mi cuenta')
                        : '${wallets.length} cuentas',
                    availableNow: totalAvailable,
                    monthBalance: monthlyBalance,
                    incomeThisMonth: monthlyIncome,
                    spentThisMonth: monthlySpent,
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

              _buildRecentTransactions(recent)
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 520.ms)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required String accountLabel,
    required double availableNow,
    required double monthBalance,
    required double incomeThisMonth,
    required double spentThisMonth,
  }) {
    final monthPositive = monthBalance >= 0;
    final monthLabel = monthPositive
        ? 'Balance del mes +${_fmt(monthBalance.abs())}'
        : 'Balance del mes -${_fmt(monthBalance.abs())}';

    return Container(
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
                  context.push('/wallet');
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
            'Disponible ahora',
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
                _fmt(availableNow),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            monthLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: monthPositive
                  ? Colors.white.withValues(alpha: 0.84)
                  : const Color(0xFFFFD8AE),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BudgetMetaPill(
                  label: 'Ingresos del mes',
                  value: _fmt(incomeThisMonth),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BudgetMetaPill(
                  label: 'Gastos del mes',
                  value: _fmt(spentThisMonth),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      (
        icon: LucideIcons.arrowDownLeft,
        label: 'Ingreso',
        color: AppColors.e6,
        bgColor: AppColors.e1,
        onTap: () => _openRegisterSheet(context, initialType: 'ingreso'),
      ),
      (
        icon: LucideIcons.arrowUpRight,
        label: 'Gasto',
        color: AppColors.o5,
        bgColor: AppColors.o1,
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

  Widget _buildRecentTransactions(List<MenudoTransaction> recent) {
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.g2),
        ),
        child: const Text(
          'Todavía no hay movimientos recientes.',
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
          final color = _transactionColor(t);
          return _TransactionTile(
            transaction: t,
            subtitle: _buildRecentSubtitle(t, _transactionCategoryLabel(t)),
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

  Color _transactionColor(MenudoTransaction transaction) {
    return switch (transaction.tipo) {
      'ingreso' => AppColors.e6,
      'transferencia' => AppColors.b5,
      _ => AppColors.e8,
    };
  }

  String _transactionCategoryLabel(MenudoTransaction transaction) {
    if (transaction.tipo == 'transferencia') return 'Transferencia';
    if (transaction.catKey.trim().isEmpty) return 'Movimiento';

    return transaction.catKey
        .split(RegExp(r'[_-]+'))
        .where((segment) => segment.isNotEmpty)
        .map(
          (segment) =>
              '${segment.substring(0, 1).toUpperCase()}${segment.substring(1)}',
        )
        .join(' ');
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

  String _fmt(double value) {
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

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
                      ? "+RD\$${_fmt(transaction.monto.abs())}"
                      : "-RD\$${_fmt(transaction.monto.abs())}",
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
            title: '3. Luego registras movimientos',
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
