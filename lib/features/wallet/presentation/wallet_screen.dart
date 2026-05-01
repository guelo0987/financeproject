import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/preferences/app_preferences_controller.dart';
import '../../../../core/utils/error_presenter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/menudo_loading_view.dart';
import '../../../../shared/widgets/menudo_toast.dart';
import '../../auth/auth_state.dart';
import '../providers/wallet_providers.dart';
import 'wallet_detail_sheet.dart';
import 'add_wallet_sheet.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _effectiveCurrency(String? currency) {
    final fallback = AppFormattingPreferences.currencyCode;
    final normalized = currency?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return fallback;
    if (normalized == 'DOP' && fallback != 'DOP') return fallback;
    return normalized;
  }

  String _fmt(double val, {String? currency}) {
    return formatMoney(val, currency: _effectiveCurrency(currency));
  }

  String _fmtAggregate(double val, {required String currencyCode}) {
    final label = _fmt(val.abs(), currency: currencyCode);
    return val < 0 ? '-$label' : label;
  }

  Future<void> _openAddWallet(BuildContext context) async {
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final result = await showModalBottomSheet<WalletAccount>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddWalletSheet(),
    );

    if (result is! WalletAccount) return;

    try {
      await ref.read(walletNotifierProvider.notifier).addWallet(result);
      if (!rootContext.mounted) return;
      MenudoHaptics.success();
      MenudoToast.success(
        rootContext,
        title: 'Cuenta creada',
        message: result.nombre,
      );
    } catch (error) {
      if (!rootContext.mounted) return;
      MenudoToast.error(
        rootContext,
        title: 'No se pudo crear',
        message: presentError(error),
      );
    }
  }

  void _showWalletError(BuildContext context, Object error) {
    MenudoToast.error(
      context,
      title: 'No se pudo completar',
      message: presentError(error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletNotifierProvider);
    final wallets = ref.watch(effectiveWalletsProvider);
    final preferences = ref.watch(appPreferencesProvider).valueOrNull;
    final activeCurrency =
        preferences?.currencyCode ?? AppFormattingPreferences.currencyCode;

    if (walletAsync.isLoading && wallets.isEmpty) {
      return Scaffold(
        backgroundColor: context.menudo.background,
        body: MenudoLoadingView(
          title: 'Cargando tu cartera',
          message: 'Estamos organizando tus cuentas y balances.',
          logoSize: 88,
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.menudo.background,
      body: walletAsync.when(
        loading: () => _buildContent(
          context,
          wallets,
          isLoading: true,
          currencyCode: activeCurrency,
        ),
        error: (e, _) => _buildContent(
          context,
          wallets,
          errorMessage: presentError(e),
          currencyCode: activeCurrency,
        ),
        data: (wallets) =>
            _buildContent(context, wallets, currencyCode: activeCurrency),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<WalletAccount> wallets, {
    bool isLoading = false,
    String? errorMessage,
    required String currencyCode,
  }) {
    final patrimonioWallets = wallets
        .where((wallet) => wallet.incluirEnPatrimonio)
        .toList(growable: false);
    final excludedWallets = wallets
        .where((wallet) => !wallet.incluirEnPatrimonio)
        .toList(growable: false);

    final double net = patrimonioWallets.fold(0, (s, w) => s + w.saldo);
    final double activos = patrimonioWallets
        .where((w) => w.saldo > 0)
        .fold(0, (s, w) => s + w.saldo);
    final double deudas = patrimonioWallets
        .where((w) => w.saldo < 0)
        .fold(0, (s, w) => s + w.saldo);
    final groups = {
      "cuentas": _WalletGroup(
        icon: MenudoCupertinoIcons.landmark,
        label: "Cuentas",
        color: AppColors.e6,
      ),
      "gastos": _WalletGroup(
        icon: MenudoCupertinoIcons.creditCard,
        label: "Gastos",
        color: AppColors.b5,
      ),
      "deudas": _WalletGroup(
        icon: MenudoCupertinoIcons.alertCircle,
        label: "Deudas",
        color: AppColors.r5,
      ),
    };

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 120.0,
          floating: false,
          pinned: true,
          backgroundColor: context.menudo.surface,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(
              start: 28,
              bottom: 16,
            ),
            centerTitle: false,
            title: Text(
              'Cartera',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: context.menudo.textMain,
                letterSpacing: -0.8,
              ),
            ),
            background: Container(color: context.menudo.surface),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: MenudoIconButton(
                onPressed: () => _openAddWallet(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.o5,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    MenudoCupertinoIcons.plus,
                    color: context.menudo.surface,
                    size: (18),
                  ),
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patrimonio Neto Card
                _buildNetWorthCard(
                      net,
                      activos,
                      deudas,
                      currencyCode,
                      excludedCount: excludedWallets.length,
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.1, end: 0, curve: MenudoMotion.springBack),

                SizedBox(height: (28)),

                if (isLoading)
                  Padding(
                    padding: EdgeInsets.only(top: 28),
                    child: MenudoInlineLoadingCard(
                      label: 'Actualizando cartera',
                    ),
                  )
                else if (errorMessage != null)
                  Builder(
                    builder: (context) {
                      final unauthorized =
                          errorMessage.contains('[401]') ||
                          errorMessage.contains('[403]');
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.menudo.dangerLight,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.r5.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              errorMessage,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.r5,
                              ),
                            ),
                            if (unauthorized) ...[
                              SizedBox(height: (12)),
                              FilledButton(
                                onPressed: () async {
                                  await ref
                                      .read(authProvider.notifier)
                                      .logout();
                                  if (!context.mounted) return;
                                  context.go('/login');
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: context.menudo.textMain,
                                  foregroundColor: context.menudo.surface,
                                ),
                                child: Text('Cerrar sesión'),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  )
                else if (wallets.isEmpty)
                  _buildEmptyState(context)
                else ...[
                  ...groups.entries.map((groupEntry) {
                    final tipoKey = groupEntry.key;
                    final g = groupEntry.value;
                    final items =
                        wallets.where((w) => w.tipo == tipoKey).toList()
                          ..sort((a, b) {
                            if (a.esDefault != b.esDefault) {
                              return a.esDefault ? -1 : 1;
                            }
                            return a.nombre.toLowerCase().compareTo(
                              b.nombre.toLowerCase(),
                            );
                          });
                    if (items.isEmpty) return const SizedBox.shrink();

                    final double total = items.fold(
                      0,
                      (s, w) => s + w.saldo.abs(),
                    );
                    final totalLabel = _fmtAggregate(
                      total,
                      currencyCode: currencyCode,
                    );

                    return _WalletGroupSection(
                          group: g,
                          items: items,
                          totalLabel: totalLabel,
                          isDeuda: tipoKey == 'deudas',
                          fmt: _fmt,
                          currencyCode: currencyCode,
                          onError: (error) => _showWalletError(context, error),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 200.ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          curve: MenudoMotion.spring,
                        );
                  }),
                ],
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 40),
        ),
      ],
    );
  }

  Widget _buildNetWorthCard(
    double net,
    double activos,
    double deudas,
    String currencyCode, {
    int excludedCount = 0,
  }) {
    final netLabel = _fmtAggregate(net, currencyCode: currencyCode);
    final activosLabel = _fmtAggregate(activos, currencyCode: currencyCode);
    final deudaLabel = _fmtAggregate(deudas.abs(), currencyCode: currencyCode);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.menudo.hero, context.menudo.heroElevated],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: context.menudo.hero.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "PATRIMONIO NETO",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (excludedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    excludedCount == 1 ? '1 fuera' : '$excludedCount fuera',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: (10)),
          Text(
            netLabel,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.8,
            ),
          ),
          SizedBox(height: (24)),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: "ACTIVOS",
                  value: activosLabel,
                  color: context.menudo.success,
                ),
              ),
              SizedBox(width: (12)),
              Expanded(
                child: _SummaryStat(
                  label: "DEUDAS",
                  value: deudaLabel,
                  color: context.menudo.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.menudo;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.menudo.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              MenudoCupertinoIcons.wallet,
              size: (32),
              color: context.menudo.textMuted,
            ),
          ),
          SizedBox(height: (20)),
          Text(
            "Aún no has agregado cuentas",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textMain,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Agrega efectivo, cuentas o deudas para ver todo tu dinero en un solo lugar.",
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: (20)),
          FilledButton(
            onPressed: () => _openAddWallet(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.o5,
              foregroundColor: context.menudo.surface,
            ),
            child: Text('Agregar primera cuenta'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _SummaryStat extends StatelessWidget {
  final String label, value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.35),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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

class _WalletGroupSection extends StatelessWidget {
  final _WalletGroup group;
  final List<WalletAccount> items;
  final String totalLabel;
  final bool isDeuda;
  final String Function(double, {String currency}) fmt;
  final String currencyCode;
  final void Function(Object error) onError;

  const _WalletGroupSection({
    required this.group,
    required this.items,
    required this.totalLabel,
    required this.isDeuda,
    required this.fmt,
    required this.currencyCode,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: group.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(group.icon, size: (16), color: group.color),
                    ),
                    SizedBox(width: (12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: colors.textMain,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: (12)),
              Flexible(
                child: Text(
                  isDeuda && totalLabel != 'Multimoneda'
                      ? '-$totalLabel'
                      : totalLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDeuda ? AppColors.r5 : colors.textMain,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: (14)),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                final w = items[i];
                return _WalletTile(
                  wallet: w,
                  fmt: fmt,
                  isLast: i == items.length - 1,
                  onTap: () {
                    MenudoHaptics.light();
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          WalletDetailSheet(wallet: w, onError: onError),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  final WalletAccount wallet;
  final String Function(double, {String currency}) fmt;
  final bool isLast;
  final VoidCallback onTap;

  const _WalletTile({
    required this.wallet,
    required this.fmt,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return MenudoGestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: wallet.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(wallet.icono, size: (20), color: wallet.color),
                ),
                SizedBox(width: (14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.nombre,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (wallet.esDefault)
                            _WalletPill(
                              label: 'PRINCIPAL',
                              fg: context.menudo.textMain,
                              bg: context.menudo.successLight,
                            ),
                          if (!wallet.incluirEnPatrimonio)
                            _WalletPill(
                              label: 'EXCLUIDA',
                              fg: context.menudo.textSecondary,
                              bg: context.menudo.surfaceElevated,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: (12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      wallet.saldo < 0
                          ? '-${fmt(wallet.saldo.abs(), currency: wallet.moneda)}'
                          : fmt(wallet.saldo.abs(), currency: wallet.moneda),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: wallet.saldo < 0
                            ? AppColors.r5
                            : colors.textMain,
                      ),
                    ),
                    SizedBox(height: 3),
                    Icon(
                      MenudoCupertinoIcons.chevronRight,
                      size: (14),
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 0.5,
              color: context.menudo.surface,
              indent: 78,
              endIndent: 20,
            ),
        ],
      ),
    );
  }
}

class _WalletPill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _WalletPill({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _WalletGroup {
  final IconData icon;
  final String label;
  final Color color;

  const _WalletGroup({
    required this.icon,
    required this.label,
    required this.color,
  });
}
