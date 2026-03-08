import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  
  String fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Calendario', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.e8)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.g0,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.chevron_left, size: 16, color: AppColors.g4),
                const SizedBox(width: 8),
                const Text("Marzo 2026", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.e8)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.g4),
              ],
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.e8,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [const BoxShadow(color: Color(0x33065F46), blurRadius: 24, offset: Offset(0, 8))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TOTAL GASTADO EN MARZO", style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(fmt(totalGasto), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("DÍAS C/ GASTOS", style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(diasConGasto.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),

          const SizedBox(height: 14),
          
          // Heatmap Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                // Days header
                Row(
                  children: ["D", "L", "M", "M", "J", "V", "S"].map((d) => Expanded(
                    child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.g4)),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                // Grid cells
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, 
                    crossAxisSpacing: 3, 
                    mainAxisSpacing: 3,
                  ),
                  itemCount: 31,
                  itemBuilder: (context, index) {
                    final int dia = index + 1;
                    final double g = gastoPorDia[dia] ?? 0;
                    final double intensity = g > 0 ? min(g / maxGasto, 1.0) : 0;
                    final bool isToday = dia == 7;
                    final bool isSelected = dia == _selectedDay;
                    
                    Color bgColor = Colors.transparent;
                    if (isSelected) {
                      bgColor = AppColors.e8;
                    } else if (g > 0) {
                      bgColor = AppColors.o5.withValues(alpha: 0.08 + (intensity * 0.72));
                    }
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = dia),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday && !isSelected ? AppColors.e8 : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dia.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: (isToday || isSelected) ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected ? Colors.white : g > 0 ? AppColors.o5 : AppColors.g5,
                                height: 1.2,
                              ),
                            ),
                            if (g > 0)
                              Text(
                                g >= 1000 ? "${(g / 1000).round()}K" : g.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white.withValues(alpha: 0.7) : AppColors.o5,
                                  height: 1,
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 150.ms),

          const SizedBox(height: 14),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Text("Menos", style: TextStyle(fontSize: 11, color: AppColors.g4)),
                const SizedBox(width: 8),
                ...[0.08, 0.25, 0.45, 0.65, 0.85].map((op) => Container(
                  width: 18, height: 18, margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(color: AppColors.o5.withValues(alpha: op), borderRadius: BorderRadius.circular(5)),
                )),
                const SizedBox(width: 5),
                const Text("Más gasto", style: TextStyle(fontSize: 11, color: AppColors.g4)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Day Details Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("$_selectedDay de Marzo", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
              if (dayTotal > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text("· ${fmt(dayTotal)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.g4)),
                )
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Day Details List
          if (dayTxns.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Text("😌", style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  const Text("Sin movimientos este día", style: TextStyle(fontSize: 14, color: AppColors.g4)),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(22)),
              child: Column(
                children: List.generate(dayTxns.length, (i) {
                  final t = dayTxns[i];
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
                              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.g4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(13)), alignment: Alignment.center, child: Icon(t.icono, size: 19, color: AppColors.g5)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.desc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text("${t.catKey} · BHD León", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t.tipo == "ingreso" ? "+ ${fmt(t.monto.abs())}" : "- ${fmt(t.monto.abs())}",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: t.tipo == "ingreso" ? AppColors.e6 : AppColors.e8),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
