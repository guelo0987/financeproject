import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
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
  String _fmt(double val, {String currency = 'DOP'}) {
    final prefix = currency == 'USD' ? 'US\$' : 'RD\$';
    final amount = val.abs().toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$prefix$amount';
  }

  String _fmtAggregate(double val, Iterable<String> currencies) {
    final unique = currencies.toSet();
    if (unique.isEmpty) {
      return _fmt(0);
    }
    if (unique.length != 1) {
      return 'Multimoneda';
    }
    final label = _fmt(val, currency: unique.first);
    return val < 0 ? '-$label' : label;
  }

  Future<void> _openAddWallet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
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
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Cuenta agregada',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.e6,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showWalletError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletNotifierProvider);
    final wallets = ref.watch(effectiveWalletsProvider);

    return Scaffold(
      backgroundColor: AppColors.g0,
      body: walletAsync.when(
        loading: () => _buildContent(context, wallets, isLoading: true),
        error: (e, _) =>
            _buildContent(context, wallets, errorMessage: e.toString()),
        data: (wallets) => _buildContent(context, wallets),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<WalletAccount> wallets, {
    bool isLoading = false,
    String? errorMessage,
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
    final allCurrencies = patrimonioWallets.map((wallet) => wallet.moneda);

    final groups = {
      "cuentas": _WalletGroup(
        icon: LucideIcons.landmark,
        label: "Cuentas",
        sub: "Donde guardas tu dinero",
        color: AppColors.e6,
      ),
      "gastos": _WalletGroup(
        icon: LucideIcons.creditCard,
        label: "Gastos",
        sub: "Tarjetas y dinero de uso diario",
        color: AppColors.b5,
      ),
      "deudas": _WalletGroup(
        icon: LucideIcons.alertCircle,
        label: "Deudas",
        sub: "Préstamos, hipotecas y otras deudas",
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
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(
              start: 20,
              bottom: 16,
            ),
            centerTitle: false,
            title: const Text(
              'Cartera',
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
                onPressed: () => _openAddWallet(context),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patrimonio Neto Card
                _buildNetWorthCard(
                      net,
                      activos,
                      deudas,
                      allCurrencies,
                      excludedCount: excludedWallets.length,
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),

                const SizedBox(height: 28),

                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: CircularProgressIndicator(),
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
                          color: AppColors.r1,
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
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.r5,
                              ),
                            ),
                            if (unauthorized) ...[
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () async {
                                  await ref
                                      .read(authProvider.notifier)
                                      .logout();
                                  if (!context.mounted) return;
                                  context.go('/login');
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.e8,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Cerrar sesión'),
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
                  const _WalletSectionLead(
                    title: 'Tus wallets',
                  ).animate().fadeIn(duration: 350.ms, delay: 150.ms),
                  const SizedBox(height: 16),
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
                      items.map((wallet) => wallet.moneda),
                    );

                    return _WalletGroupSection(
                          group: g,
                          items: items,
                          totalLabel: totalLabel,
                          isDeuda: tipoKey == 'deudas',
                          fmt: _fmt,
                          onError: (error) => _showWalletError(context, error),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 200.ms)
                        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
                  }),
                ],
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }

  Widget _buildNetWorthCard(
    double net,
    double activos,
    double deudas,
    Iterable<String> currencies, {
    int excludedCount = 0,
  }) {
    final netLabel = _fmtAggregate(net, currencies);
    final activosLabel = _fmtAggregate(activos, currencies);
    final deudaLabel = _fmtAggregate(deudas.abs(), currencies);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.e8, Color(0xFF0A7A5D)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.e8.withValues(alpha: 0.3),
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
          const SizedBox(height: 10),
          Text(
            netLabel,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.8,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: "ACTIVOS",
                  value: activosLabel,
                  color: const Color(0xFF6EE7B7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStat(
                  label: "DEUDAS",
                  value: deudaLabel,
                  color: const Color(0xFFFCA5A5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.g1,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.wallet,
              size: 32,
              color: AppColors.g3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Tu cartera está vacía",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Agrega tus cuentas bancarias, efectivo o deudas para empezar a ver tu patrimonio real.",
            style: TextStyle(fontSize: 14, color: AppColors.g5, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => _openAddWallet(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.o5,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear primera cuenta'),
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
          const SizedBox(height: 4),
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

class _WalletSectionLead extends StatelessWidget {
  final String title;

  const _WalletSectionLead({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.e8,
        letterSpacing: -0.3,
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
  final void Function(Object error) onError;

  const _WalletGroupSection({
    required this.group,
    required this.items,
    required this.totalLabel,
    required this.isDeuda,
    required this.fmt,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
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
                      child: Icon(group.icon, size: 16, color: group.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.e8,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            group.sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.g4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${items.length} wallet${items.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.g4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isDeuda && totalLabel != 'Multimoneda'
                          ? '-$totalLabel'
                          : totalLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDeuda ? AppColors.r5 : AppColors.e8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.g2),
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                final w = items[i];
                return _WalletTile(
                  wallet: w,
                  fmt: fmt,
                  isLast: i == items.length - 1,
                  onTap: () {
                    HapticFeedback.lightImpact();
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
    return GestureDetector(
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
                  child: Icon(wallet.icono, size: 20, color: wallet.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.e8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _WalletPill(
                            label: wallet.moneda,
                            fg: AppColors.g5,
                            bg: AppColors.g1,
                          ),
                          if (wallet.esDefault)
                            const _WalletPill(
                              label: 'PRINCIPAL',
                              fg: AppColors.e8,
                              bg: AppColors.e1,
                            ),
                          if (!wallet.incluirEnPatrimonio)
                            const _WalletPill(
                              label: 'FUERA PATR.',
                              fg: AppColors.g5,
                              bg: AppColors.g1,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      wallet.saldo < 0
                          ? '-${fmt(wallet.saldo, currency: wallet.moneda)}'
                          : fmt(wallet.saldo, currency: wallet.moneda),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: wallet.saldo < 0 ? AppColors.r5 : AppColors.e8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: AppColors.g3,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(height: 1, color: AppColors.g1, indent: 78, endIndent: 20),
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
  final String sub;
  final Color color;

  const _WalletGroup({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });
}
