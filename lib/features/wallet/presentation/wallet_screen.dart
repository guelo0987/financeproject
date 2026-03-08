import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import 'wallet_detail_sheet.dart';
import 'add_wallet_sheet.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late List<WalletAccount> _wallets;

  @override
  void initState() {
    super.initState();
    _wallets = List.from(mockWallets);
  }

  void _openAddWallet() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddWalletSheet(),
    ).then((result) {
      if (result is WalletAccount) {
        setState(() => _wallets.add(result));
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Cuenta agregada', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.e6,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  String fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  @override
  Widget build(BuildContext context) {
    // Calculos Patrimonio
    final double net = _wallets.fold(0, (s, w) => s + w.saldo);
    final double activos = _wallets.where((w) => w.saldo > 0).fold(0, (s, w) => s + w.saldo);
    final double deudas = _wallets.where((w) => w.saldo < 0).fold(0, (s, w) => s + w.saldo);

    const groups = {
      "gasto":  _WalletGroup(icon: LucideIcons.creditCard,   label: "Gastos",  sub: "De donde sale tu dinero", color: AppColors.b5),
      "ahorro": _WalletGroup(icon: LucideIcons.piggyBank,    label: "Ahorros", sub: "Donde guardas tu dinero",  color: AppColors.e6),
      "deuda":  _WalletGroup(icon: LucideIcons.alertCircle,  label: "Deudas",  sub: "Préstamos y créditos",     color: AppColors.r5),
    };

    return Scaffold(
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Wallet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.e8)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
        actions: [
          GestureDetector(
            onTap: _openAddWallet,
            child: Container(
              margin: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.o5,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [const BoxShadow(color: Color(0x44F97316), blurRadius: 16, offset: Offset(0, 6))],
              ),
              alignment: Alignment.center,
              child: const Text("+ Agregar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          // Patrimonio Neto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.e8,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [const BoxShadow(color: Color(0x44065F46), blurRadius: 40, offset: Offset(0, 12))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PATRIMONIO NETO", style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(fmt(net), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ACTIVOS", style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(fmt(activos), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7))),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("DEUDAS", style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(fmt(deudas.abs()), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFFCA5A5))),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),

          const SizedBox(height: 14),

          // Groups
          ...groups.entries.toList().asMap().entries.map((groupEntry) {
            final int groupIdx = groupEntry.key;
            final tipo = groupEntry.value.key;
            final g = groupEntry.value.value;
            final items = _wallets.where((w) => w.tipo == tipo).toList();

            if (items.isEmpty) return const SizedBox.shrink();

            final double tot = items.fold(0, (s, w) => s + w.saldo.abs());

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: g.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(g.icon, size: 14, color: g.color),
                                ),
                                const SizedBox(width: 8),
                                Text(g.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Padding(
                              padding: const EdgeInsets.only(left: 30),
                              child: Text(g.sub, style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                            ),
                          ],
                        ),
                        Text(
                          "${tipo == 'deuda' ? '-' : ''}${fmt(tot)}",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: tipo == 'deuda' ? AppColors.r5 : AppColors.e8),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: List.generate(items.length, (i) {
                        final w = items[i];
                        return Column(
                          children: [
                            if (i > 0) const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 76, endIndent: 16),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => WalletDetailSheet(wallet: w),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(width: 44, height: 44, decoration: BoxDecoration(color: w.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(14)), alignment: Alignment.center, child: Icon(w.icono, size: 20, color: w.color)),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(w.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 2),
                                          Text(w.tipo[0].toUpperCase() + w.tipo.substring(1), style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(fmt(w.saldo), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: w.saldo < 0 ? AppColors.r5 : AppColors.e8)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        );
                      }),
                    ),
                  )
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (150 + groupIdx * 120).ms).slideY(begin: 0.05, end: 0, duration: 400.ms, delay: (150 + groupIdx * 120).ms);
          }),
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

  const _WalletGroup({required this.icon, required this.label, required this.sub, required this.color});
}
