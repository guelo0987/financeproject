import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import '../../budgets/budget_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  String _filter = "Todos";
  final _filters = ["Todos", "Gastos", "Ingresos", "Transferencias"];

  String _fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  List<MenudoTransaction> _filtered(List<MenudoTransaction> txns) {
    switch (_filter) {
      case 'Gastos':
        return txns.where((t) => t.tipo == 'gasto').toList();
      case 'Ingresos':
        return txns.where((t) => t.tipo == 'ingreso').toList();
      case 'Transferencias':
        return txns.where((t) => t.tipo == 'transferencia').toList();
      default:
        return txns;
    }
  }

  Map<String, List<MenudoTransaction>> _grouped(List<MenudoTransaction> txns) {
    final months = [
      '',
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
    final Map<String, List<MenudoTransaction>> groups = {};
    for (final t in txns) {
      final parts = t.dateString.split('-');
      if (parts.length < 3) continue;
      final day = int.parse(parts[2]);
      final monthLabel = months[int.tryParse(parts[1]) ?? 0];
      final key = "$day $monthLabel ${parts[0]}";
      groups.putIfAbsent(key, () => []).add(t);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final txns = ref.watch(transactionNotifierProvider).valueOrNull ?? mockTxns;
    final wallets =
        ref.watch(walletNotifierProvider).valueOrNull ?? mockWallets;
    final budgets =
        ref.watch(budgetNotifierProvider).valueOrNull ?? mockBudgets;
    final selectedIdx = ref
        .watch(selectedBudgetIdxProvider)
        .clamp(0, budgets.isEmpty ? 0 : budgets.length - 1);
    final activeBudget = budgets.isNotEmpty
        ? budgets[selectedIdx]
        : mockBudgets.first;

    final filtered = _filtered(txns);
    final grouped = _grouped(filtered);

    final totalIngresos = txns
        .where((t) => t.tipo == 'ingreso')
        .fold(0.0, (s, t) => s + t.monto.abs());
    final totalGastos = txns
        .where((t) => t.tipo == 'gasto')
        .fold(0.0, (s, t) => s + t.monto.abs());

    return Scaffold(
      backgroundColor: AppColors.g0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppColors.e8),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                bottom: 16,
              ),
              centerTitle: false,
              title: const Text(
                'Historial',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.e8,
                  letterSpacing: -0.8,
                ),
              ),
              background: Container(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  LucideIcons.search,
                  color: AppColors.e8,
                  size: 20,
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  _HistorySummary(
                        totalIngresos: totalIngresos,
                        totalGastos: totalGastos,
                        fmt: _fmt,
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),

                  const SizedBox(height: 20),

                  // Filter Chips
                  _HistoryFilters(
                    filters: _filters,
                    selectedFilter: _filter,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _filter = val);
                    },
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (grouped.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final dateKey = grouped.keys.elementAt(index);
                  final dayTxns = grouped[dateKey]!;
                  final dayTotal = dayTxns
                      .where((t) => t.tipo == 'gasto')
                      .fold(0.0, (s, t) => s + t.monto.abs());

                  return _DayGroupSection(
                        dateKey: dateKey,
                        dayTotal: dayTotal,
                        dayTxns: dayTxns,
                        activeBudget: activeBudget,
                        wallets: wallets,
                        fmt: _fmt,
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                      .slideY(begin: 0.05, end: 0);
                }, childCount: grouped.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.g1,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.inbox, size: 30, color: AppColors.g3),
          ),
          const SizedBox(height: 16),
          const Text(
            "Sin transacciones",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "No hay movimientos en esta categoría",
            style: TextStyle(fontSize: 14, color: AppColors.g5),
          ),
        ],
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  final double totalIngresos, totalGastos;
  final String Function(double) fmt;

  const _HistorySummary({
    required this.totalIngresos,
    required this.totalGastos,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.e8,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.e8.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: "INGRESOS",
              amount: fmt(totalIngresos),
              color: const Color(0xFF6EE7B7),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          Expanded(
            child: _SummaryItem(
              label: "GASTOS",
              amount: fmt(totalGastos),
              color: const Color(0xFFFCA5A5),
              isRight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, amount;
  final Color color;
  final bool isRight;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isRight ? 20 : 0, right: isRight ? 0 : 20),
      child: Column(
        crossAxisAlignment: isRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 17,
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

class _HistoryFilters extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final Function(String) onChanged;

  const _HistoryFilters({
    required this.filters,
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSel = selectedFilter == f;
          return GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSel ? AppColors.e8 : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: isSel ? AppColors.e8 : AppColors.g2),
              ),
              alignment: Alignment.center,
              child: Text(
                f,
                style: TextStyle(
                  color: isSel ? Colors.white : AppColors.g5,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayGroupSection extends StatelessWidget {
  final String dateKey;
  final double dayTotal;
  final List<MenudoTransaction> dayTxns;
  final MenudoBudget activeBudget;
  final List<WalletAccount> wallets;
  final String Function(double) fmt;

  const _DayGroupSection({
    required this.dateKey,
    required this.dayTotal,
    required this.dayTxns,
    required this.activeBudget,
    required this.wallets,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateKey,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.e8,
                    letterSpacing: -0.3,
                  ),
                ),
                if (dayTotal > 0)
                  Text(
                    "- ${fmt(dayTotal)}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.g4,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.g2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: List.generate(dayTxns.length, (i) {
                final t = dayTxns[i];
                final ci = activeBudget.cats[t.catKey];
                final isTransfer = t.tipo == 'transferencia';
                final fromW = t.fromAccountId != null
                    ? wallets.where((w) => w.id == t.fromAccountId).firstOrNull
                    : null;
                final toW = t.toAccountId != null
                    ? wallets.where((w) => w.id == t.toAccountId).firstOrNull
                    : null;

                return _HistoryTile(
                  transaction: t,
                  category: ci,
                  isTransfer: isTransfer,
                  fromWallet: fromW,
                  toWallet: toW,
                  isLast: i == dayTxns.length - 1,
                  fmt: fmt,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final MenudoTransaction transaction;
  final BudgetCategory? category;
  final bool isTransfer;
  final WalletAccount? fromWallet, toWallet;
  final bool isLast;
  final String Function(double) fmt;

  const _HistoryTile({
    required this.transaction,
    this.category,
    required this.isTransfer,
    this.fromWallet,
    this.toWallet,
    required this.isLast,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final color = isTransfer ? AppColors.b5 : (category?.color ?? AppColors.g4);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => TransactionDetailSheet(transaction: transaction),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                      if (isTransfer && fromWallet != null && toWallet != null)
                        Text(
                          "${fromWallet!.nombre.split('—').first.trim()} → ${toWallet!.nombre.split('—').first.trim()}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.g4,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          category?.label ?? transaction.catKey.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.g4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isTransfer
                      ? fmt(transaction.monto.abs())
                      : (transaction.tipo == "ingreso"
                            ? "+${fmt(transaction.monto.abs())}"
                            : "-${fmt(transaction.monto.abs())}"),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isTransfer
                        ? AppColors.b5
                        : (transaction.tipo == "ingreso"
                              ? AppColors.e6
                              : AppColors.e8),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(height: 1, color: AppColors.g1, indent: 76, endIndent: 18),
        ],
      ),
    );
  }
}
