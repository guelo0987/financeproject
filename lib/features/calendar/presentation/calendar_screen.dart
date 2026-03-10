import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedDay = 7; // Assuming 7 is "today" for the mockup
  
  String _fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  @override
  Widget build(BuildContext context) {
    // Process mock data
    final Map<int, double> gastoPorDia = {};
    for (var t in mockTxns) {
      if (t.tipo != "gasto") continue;
      final int d = int.parse(t.dateString.split("-")[2]);
      gastoPorDia[d] = (gastoPorDia[d] ?? 0) + (t.monto).abs();
    }
    
    final double maxGasto = gastoPorDia.isNotEmpty ? gastoPorDia.values.reduce(max) : 1;
    final int diasConGasto = gastoPorDia.keys.length;
    final double totalGasto = gastoPorDia.values.fold(0, (s, v) => s + v);
    
    // Day txns
    final List<MenudoTransaction> dayTxns = mockTxns.where((t) => int.parse(t.dateString.split("-")[2]) == _selectedDay).toList();
    final double dayTotal = dayTxns.where((t) => t.tipo == "gasto").fold(0, (s, t) => s + (t.monto).abs());

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
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              centerTitle: false,
              title: const Text(
                'Calendario',
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
              _MonthSelector()
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  _CalendarSummary(totalGasto: totalGasto, diasConGasto: diasConGasto, fmt: _fmt)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),

                  const SizedBox(height: 20),

                  // Heatmap Card
                  _HeatmapCard(
                    gastoPorDia: gastoPorDia,
                    maxGasto: maxGasto,
                    selectedDay: _selectedDay,
                    onDaySelected: (day) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDay = day);
                    },
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                  const SizedBox(height: 32),

                  // Day Details
                  _DayHeader(selectedDay: _selectedDay, dayTotal: dayTotal, fmt: _fmt)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),

                  const SizedBox(height: 12),

                  _DayTransactionsList(dayTxns: dayTxns, fmt: _fmt)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
                      
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.g1,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.chevronLeft, size: 14, color: AppColors.g4),
          const SizedBox(width: 8),
          const Text("Marzo 2026", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.e8)),
          const SizedBox(width: 8),
          Icon(LucideIcons.chevronRight, size: 14, color: AppColors.g4),
        ],
      ),
    );
  }
}

class _CalendarSummary extends StatelessWidget {
  final double totalGasto;
  final int diasConGasto;
  final String Function(double) fmt;

  const _CalendarSummary({required this.totalGasto, required this.diasConGasto, required this.fmt});

  @override
  Widget build(BuildContext context) {
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
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GASTADO ESTE MES",
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.45), fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                fmt(totalGasto),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.2),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  "DÍAS",
                  style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.45), fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                Text(
                  diasConGasto.toString(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  final Map<int, double> gastoPorDia;
  final double maxGasto;
  final int selectedDay;
  final Function(int) onDaySelected;

  const _HeatmapCard({required this.gastoPorDia, required this.maxGasto, required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["D", "L", "M", "M", "J", "V", "S"].map((d) => Text(
              d,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.g4),
            )).toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, 
              crossAxisSpacing: 6, 
              mainAxisSpacing: 6,
            ),
            itemCount: 31,
            itemBuilder: (context, index) {
              final int dia = index + 1;
              final double g = gastoPorDia[dia] ?? 0;
              final double intensity = g > 0 ? min(g / maxGasto, 1.0) : 0;
              final bool isToday = dia == 7;
              final bool isSelected = dia == selectedDay;
              
              return _DayCell(
                day: dia,
                amount: g,
                intensity: intensity,
                isToday: isToday,
                isSelected: isSelected,
                onTap: () => onDaySelected(dia),
              );
            },
          ),
          const SizedBox(height: 20),
          _HeatmapLegend(),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final double amount;
  final double intensity;
  final bool isToday, isSelected;
  final VoidCallback onTap;

  const _DayCell({required this.day, required this.amount, required this.intensity, required this.isToday, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = AppColors.e8;
    } else if (amount > 0) {
      bgColor = AppColors.o5.withValues(alpha: 0.1 + (intensity * 0.8));
    } else if (isToday) {
      bgColor = AppColors.g1;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday && !isSelected ? AppColors.e8 : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          day.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: (isToday || isSelected) ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? Colors.white : amount > 0 ? (intensity > 0.5 ? Colors.white : AppColors.o5) : AppColors.g5,
          ),
        ),
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Menos", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.g4)),
        const SizedBox(width: 8),
        ...[0.1, 0.3, 0.5, 0.7, 0.9].map((op) => Container(
          width: 14, height: 14, margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(color: AppColors.o5.withValues(alpha: op), borderRadius: BorderRadius.circular(4)),
        )),
        const SizedBox(width: 4),
        const Text("Más", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.g4)),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final int selectedDay;
  final double dayTotal;
  final String Function(double) fmt;

  const _DayHeader({required this.selectedDay, required this.dayTotal, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$selectedDay de Marzo",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.e8, letterSpacing: -0.4),
        ),
        if (dayTotal > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.r1, borderRadius: BorderRadius.circular(10)),
            child: Text(fmt(dayTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.r5)),
          )
      ],
    );
  }
}

class _DayTransactionsList extends StatelessWidget {
  final List<MenudoTransaction> dayTxns;
  final String Function(double) fmt;

  const _DayTransactionsList({required this.dayTxns, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (dayTxns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.g2),
        ),
        child: Column(
          children: [
            const Text("😌", style: TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            const Text(
              "Sin movimientos este día",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.g4),
            ),
          ],
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
        children: List.generate(dayTxns.length, (i) {
          final t = dayTxns[i];
          return _DayTransactionTile(
            transaction: t,
            fmt: fmt,
            isLast: i == dayTxns.length - 1,
            onTap: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
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
}

class _DayTransactionTile extends StatelessWidget {
  final MenudoTransaction transaction;
  final String Function(double) fmt;
  final bool isLast;
  final VoidCallback onTap;

  const _DayTransactionTile({required this.transaction, required this.fmt, required this.isLast, required this.onTap});

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
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(14)),
                  child: Icon(transaction.icono, size: 20, color: AppColors.g5),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(transaction.desc, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.e8), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(transaction.catKey.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.g4, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Text(
                  transaction.tipo == "ingreso" ? "+${fmt(transaction.monto.abs().toInt().toDouble())}" : "-${fmt(transaction.monto.abs().toInt().toDouble())}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: transaction.tipo == "ingreso" ? AppColors.e6 : AppColors.e8,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) Divider(height: 1, color: AppColors.g1, indent: 78, endIndent: 20),
        ],
      ),
    );
  }
}

