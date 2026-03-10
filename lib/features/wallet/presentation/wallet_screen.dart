import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../providers/wallet_providers.dart';
import 'wallet_detail_sheet.dart';
import 'add_wallet_sheet.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  void _openAddWallet(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddWalletSheet(),
    ).then((result) {
      if (result is WalletAccount) {
        ref.read(walletNotifierProvider.notifier).addWallet(result);
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.g0,
      body: walletAsync.when(
        loading: () => _buildContent(context, mockWallets, isLoading: true),
        error: (e, _) => _buildContent(context, mockWallets),
        data: (wallets) => _buildContent(context, wallets),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<WalletAccount> wallets, {
    bool isLoading = false,
  }) {
    final double net = wallets.fold(0, (s, w) => s + w.saldo);
    final double activos = wallets
        .where((w) => w.saldo > 0)
        .fold(0, (s, w) => s + w.saldo);
    final double deudas = wallets
        .where((w) => w.saldo < 0)
        .fold(0, (s, w) => s + w.saldo);

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
        sub: "Efectivo y día a día",
        color: AppColors.b5,
      ),
      "deudas": _WalletGroup(
        icon: LucideIcons.alertCircle,
        label: "Deudas",
        sub: "Préstamos y créditos",
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
                _buildNetWorthCard(net, activos, deudas)
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
                else if (wallets.isEmpty)
                  _buildEmptyState()
                else
                  ...groups.entries.map((groupEntry) {
                    final tipoKey = groupEntry.key;
                    final g = groupEntry.value;
                    final items = wallets
                        .where((w) => w.tipo == tipoKey)
                        .toList();
                    if (items.isEmpty) return const SizedBox.shrink();

                    final double total = items.fold(
                      0,
                      (s, w) => s + w.saldo.abs(),
                    );

                    return _WalletGroupSection(
                          group: g,
                          items: items,
                          total: total,
                          isDeuda: tipoKey == 'deudas',
                          fmt: _fmt,
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 200.ms)
                        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
                  }),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }

  Widget _buildNetWorthCard(double net, double activos, double deudas) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.e8,
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
          Text(
            "PATRIMONIO NETO",
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.45),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fmt(net),
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
              _SummaryStat(
                label: "ACTIVOS",
                value: _fmt(activos),
                color: const Color(0xFF6EE7B7),
              ),
              const SizedBox(width: 32),
              _SummaryStat(
                label: "DEUDAS",
                value: _fmt(deudas.abs()),
                color: const Color(0xFFFCA5A5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
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
              "Agrega tus cuentas bancarias o de efectivo",
              style: TextStyle(fontSize: 14, color: AppColors.g5),
            ),
          ],
        ),
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
    return Column(
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
    );
  }
}

class _WalletGroupSection extends StatelessWidget {
  final _WalletGroup group;
  final List<WalletAccount> items;
  final double total;
  final bool isDeuda;
  final String Function(double) fmt;

  const _WalletGroupSection({
    required this.group,
    required this.items,
    required this.total,
    required this.isDeuda,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.e8,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        group.sub,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.g4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                "${isDeuda ? '-' : ''}${fmt(total)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDeuda ? AppColors.r5 : AppColors.e8,
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
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => WalletDetailSheet(wallet: w),
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
  final String Function(double) fmt;
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
                      Text(
                        wallet.tipo.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.g4,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  fmt(wallet.saldo),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: wallet.saldo < 0 ? AppColors.r5 : AppColors.e8,
                  ),
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
