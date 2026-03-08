import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _filter = "Todos"; // "Todos", "Gastos", "Ingresos", "Transferencias"
  final _filters = ["Todos", "Gastos", "Ingresos", "Transferencias"];

  String fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  List<MenudoTransaction> get _filtered {
    switch (_filter) {
      case 'Gastos': return mockTxns.where((t) => t.tipo == 'gasto').toList();
      case 'Ingresos': return mockTxns.where((t) => t.tipo == 'ingreso').toList();
      case 'Transferencias': return mockTxns.where((t) => t.tipo == 'transferencia').toList();
      default: return mockTxns;
    }
  }

  Map<String, List<MenudoTransaction>> get _grouped {
    final months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final Map<String, List<MenudoTransaction>> groups = {};
    for (final t in _filtered) {
      final parts = t.dateString.split('-');
      final day = int.parse(parts[2]);
      final monthLabel = months[int.tryParse(parts[1]) ?? 0];
      final key = "$day $monthLabel ${parts[0]}";
      groups.putIfAbsent(key, () => []).add(t);
    }
    return groups;
  }

  double get _totalIngresos => mockTxns.where((t) => t.tipo == 'ingreso').fold(0.0, (s, t) => s + t.monto.abs());
  double get _totalGastos => mockTxns.where((t) => t.tipo == 'gasto').fold(0.0, (s, t) => s + t.monto.abs());

  @override
  Widget build(BuildContext context) {
    final activeBudget = mockBudgets.firstWhere((b) => b.activo, orElse: () => mockBudgets.first);
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.e8, size: 22),
          ),
        ),
        title: const Text('Historial', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.e8)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Summary row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.e8,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [const BoxShadow(color: Color(0x33065F46), blurRadius: 16, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("INGRESOS", style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        const SizedBox(height: 3),
                        Text(fmt(_totalIngresos), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7), letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("GASTOS", style: TextStyle(fontSize: 9, color: AppColors.g4, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        const SizedBox(height: 3),
                        Text(fmt(_totalGastos), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.r5, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final isSel = _filter == f;
                  return GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _filter = f); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.e8 : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: isSel ? AppColors.e8 : const Color(0xFFE5E7EB), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(f, style: TextStyle(color: isSel ? Colors.white : AppColors.g5, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          ),

          const SizedBox(height: 12),

          // List
          Expanded(
            child: grouped.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(20)),
                          alignment: Alignment.center,
                          child: const Icon(LucideIcons.inbox, size: 30, color: AppColors.g3),
                        ),
                        const SizedBox(height: 12),
                        const Text("Sin transacciones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.e8)),
                        const SizedBox(height: 4),
                        const Text("No hay movimientos en esta categoría", style: TextStyle(fontSize: 13, color: AppColors.g4)),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final dateKey = grouped.keys.elementAt(index);
                      final txns = grouped[dateKey]!;
                      final dayTotal = txns.where((t) => t.tipo == 'gasto').fold(0.0, (s, t) => s + t.monto.abs());

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, left: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dateKey, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.e8)),
                                  if (dayTotal > 0)
                                    Text("- ${fmt(dayTotal)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.g4)),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                children: List.generate(txns.length, (i) {
                                  final t = txns[i];
                                  final ci = activeBudget.cats[t.catKey];
                                  final isTransfer = t.tipo == 'transferencia';
                                  final fromW = t.fromAccountId != null ? mockWallets.firstWhere((w) => w.id == t.fromAccountId, orElse: () => mockWallets.first) : null;
                                  final toW = t.toAccountId != null ? mockWallets.firstWhere((w) => w.id == t.toAccountId, orElse: () => mockWallets.last) : null;

                                  return Column(
                                    children: [
                                      if (i > 0) const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 68, endIndent: 16),
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => TransactionDetailSheet(transaction: t),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40, height: 40,
                                                decoration: BoxDecoration(
                                                  color: (isTransfer ? AppColors.b5 : (ci?.color ?? AppColors.g4)).withValues(alpha: 0.13),
                                                  borderRadius: BorderRadius.circular(13),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(t.icono, size: 19, color: isTransfer ? AppColors.b5 : (ci?.color ?? AppColors.g4)),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(t.desc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                    const SizedBox(height: 2),
                                                    if (isTransfer && fromW != null && toW != null)
                                                      Text("${fromW.nombre.split('—').first.trim()} → ${toW.nombre.split('—').first.trim()}", style: const TextStyle(fontSize: 11, color: AppColors.g4), maxLines: 1, overflow: TextOverflow.ellipsis)
                                                    else
                                                      Text(ci?.label ?? t.catKey, style: const TextStyle(fontSize: 11, color: AppColors.g4)),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isTransfer
                                                    ? fmt(t.monto.abs())
                                                    : (t.tipo == "ingreso" ? "+ ${fmt(t.monto.abs())}" : "- ${fmt(t.monto.abs())}"),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: isTransfer ? AppColors.b5 : (t.tipo == "ingreso" ? AppColors.e6 : AppColors.e8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 350.ms, delay: (100 + index * 50).ms).slideY(begin: 0.04, end: 0, duration: 350.ms, delay: (100 + index * 50).ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
