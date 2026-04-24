import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/demo_mode_controller.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/preferences/app_preferences_controller.dart';
import '../../../core/utils/display_utils.dart';
import '../../../core/utils/error_presenter.dart';
import '../../alerts/providers/alert_providers.dart';
import '../../../../core/data/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/menudo_loading_view.dart';
import '../../auth/auth_state.dart';
import '../../quick_log/presentation/register_transaction_sheet.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallet/presentation/add_wallet_sheet.dart';
import '../../wallet/providers/wallet_providers.dart';
import 'widgets/dashboard_action_grid.dart';
import 'widgets/dashboard_empty_state.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_overview_card.dart';
import 'widgets/dashboard_recent_transactions.dart';
import 'widgets/wallet_setup_suggestion_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _dismissedWalletSuggestion = false;

  String? _displayName(String? fullName) {
    final name = shortDisplayName(fullName);
    if (name.isEmpty) return null;
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

  Future<void> _openAddWallet() async {
    final wallet = await showModalBottomSheet<WalletAccount>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddWalletSheet(),
    );

    if (wallet == null || !mounted) return;

    try {
      await ref.read(walletNotifierProvider.notifier).addWallet(wallet);
      MenudoHaptics.success();
    } catch (error) {
      _showError(error);
    }
  }

  void _openRegisterSheet(
    BuildContext context, {
    String initialType = 'gasto',
  }) {
    MenudoHaptics.medium();
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
    final preferences = ref.watch(appPreferencesProvider).valueOrNull;
    final activeCurrency =
        preferences?.currencyCode ?? AppFormattingPreferences.currencyCode;
    final displayName = _displayName(authState.profile?.name);
    final avatarEmoji = authState.profile?.avatarEmoji?.trim();
    final isHydratingHome =
        authState.isBootstrapping ||
        (walletsState.isLoading && walletsState.valueOrNull == null) ||
        (transactionsState.isLoading && transactionsState.valueOrNull == null);

    if (isHydratingHome) {
      return Scaffold(
        backgroundColor: context.menudo.background,
        body: SafeArea(
          child: MenudoLoadingView(
            title: 'Cargando tu resumen',
            message: 'Estamos preparando tus cuentas y movimientos.',
          ),
        ),
      );
    }

    if (wallets.isEmpty && allTransactions.isEmpty) {
      return DashboardEmptyState(demoMode: demoMode);
    }

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
    final colors = context.menudo;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator.adaptive(
          onRefresh: _refreshDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              DashboardHeader(
                    avatarEmoji: avatarEmoji,
                    avatarLabel: avatarLabel,
                    title: headerTitle,
                    unreadAlerts: unreadAlerts,
                    onProfileTap: () => context.push('/settings'),
                    onAlertsTap: () => context.push('/alerts'),
                    onSettingsTap: () => context.push('/settings'),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.05, end: 0, curve: Curves.easeOutBack),

              SizedBox(height: (22)),
              DashboardOverviewCard(
                    accountLabel: wallets.length == 1
                        ? (defaultWallet?.nombre ?? 'Mi cuenta')
                        : '${wallets.length} cuentas',
                    availableNow: totalAvailable,
                    monthBalance: monthlyBalance,
                    incomeThisMonth: monthlyIncome,
                    spentThisMonth: monthlySpent,
                    currencyCode: activeCurrency,
                    onWalletTap: () {
                      MenudoHaptics.light();
                      context.push('/wallet');
                    },
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 100.ms)
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    curve: Curves.easeOutBack,
                    delay: 100.ms,
                  ),

              SizedBox(height: (20)),
              if (_needsWalletTour(wallets, demoMode) &&
                  !_dismissedWalletSuggestion) ...[
                WalletSetupSuggestionCard(
                  onConfigure: _openAddWallet,
                  onDismiss: () {
                    MenudoHaptics.selection();
                    setState(() => _dismissedWalletSuggestion = true);
                  },
                ).animate().fadeIn(duration: 320.ms, delay: 160.ms),
                SizedBox(height: (20)),
              ],
              DashboardActionGrid(
                    onIncomeTap: () =>
                        _openRegisterSheet(context, initialType: 'ingreso'),
                    onExpenseTap: () => _openRegisterSheet(context),
                    onTransferTap: () => _openRegisterSheet(
                      context,
                      initialType: 'transferencia',
                    ),
                    onMoreTap: () => context.push('/tools'),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

              SizedBox(height: (28)),
              DashboardSectionHeader(
                title: "Recientes",
                trailing: TextButton(
                  onPressed: () => context.push('/history'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Ver todo",
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: (14),
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 440.ms),

              SizedBox(height: 4),

              DashboardRecentTransactions(
                    recent: recent,
                    currencyCode: activeCurrency,
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 520.ms)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }
}
