import 'dart:ui';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/data/models.dart';
import '../../transactions/presentation/transaction_presentation_utils.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = dateOnly(DateTime.now());

  String _fmt(double val) => formatMoney(val);

  String _monthName(int month) {
    const months = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month.clamp(0, 12)];
  }

  String _transactionSubtitle(MenudoTransaction transaction) {
    final userName = transaction.userName?.trim();
    if (userName != null && userName.isNotEmpty) {
      return userName;
    }
    return transaction.catKey.replaceAll('-', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final now = dateOnly(ref.watch(transactionsReferenceDateProvider));
    final txns = ref.watch(currentMonthTransactionsProvider);

    if (_selectedDate.year != now.year || _selectedDate.month != now.month) {
      _selectedDate = DateTime(
        now.year,
        now.month,
        _selectedDate.day.clamp(
          1,
          DateUtils.getDaysInMonth(now.year, now.month),
        ),
      );
    }

    final Map<int, double> gastoPorDia = {};
    for (final t in txns) {
      if (t.tipo != "gasto") continue;
      final date = parseDateOnly(t.dateString);
      if (date == null) continue;
      final d = date.day;
      gastoPorDia[d] = (gastoPorDia[d] ?? 0) + (t.monto).abs();
    }

    final double maxGasto = gastoPorDia.isNotEmpty
        ? gastoPorDia.values.reduce(max)
        : 1;
    final int diasConGasto = gastoPorDia.keys.length;
    final double totalGasto = gastoPorDia.values.fold(0, (s, v) => s + v);

    // Day txns
    final List<MenudoTransaction> dayTxns = txns.where((t) {
      final date = parseDateOnly(t.dateString);
      if (date == null) return false;
      return date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
    }).toList();
    final double dayTotal = dayTxns
        .where((t) => t.tipo == "gasto")
        .fold(0, (s, t) => s + (t.monto).abs());

    return Scaffold(
      backgroundColor: context.menudo.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: context.menudo.navBar,
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 20,
                    bottom: 16,
                  ),
                  centerTitle: false,
                  title: Text(
                    'Calendario',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: context.menudo.textMain,
                      letterSpacing: -0.8,
                    ),
                  ),
                  background: ColoredBox(color: context.menudo.navBar),
                ),
              ),
            ),
            actions: [
              _MonthPill(label: '${_monthName(now.month)} ${now.year}'),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  _CalendarSummary(
                        totalGasto: totalGasto,
                        diasConGasto: diasConGasto,
                        fmt: _fmt,
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: MenudoMotion.springBack),

                  SizedBox(height: (20)),

                  // Heatmap Card
                  _HeatmapCard(
                    gastoPorDia: gastoPorDia,
                    maxGasto: maxGasto,
                    selectedDay: _selectedDate.day,
                    onDaySelected: (day) {
                      MenudoHaptics.selection();
                      setState(() {
                        _selectedDate = DateTime(now.year, now.month, day);
                      });
                    },
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                  SizedBox(height: (32)),

                  // Day Details
                  _DayHeader(
                    selectedDay: _selectedDate.day,
                    dayTotal: dayTotal,
                    monthLabel: _monthName(now.month),
                    fmt: _fmt,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                  SizedBox(height: (12)),

                  _DayTransactionsList(
                        dayTxns: dayTxns,
                        fmt: _fmt,
                        subtitleFormatter: _transactionSubtitle,
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: 0.05, end: 0, curve: MenudoMotion.spring),

                  SizedBox(height: (120)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthPill extends StatelessWidget {
  final String label;

  const _MonthPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: context.menudo.textMain,
          ),
        ),
      ),
    );
  }
}

class _CalendarSummary extends StatelessWidget {
  final double totalGasto;
  final int diasConGasto;
  final String Function(double) fmt;

  const _CalendarSummary({
    required this.totalGasto,
    required this.diasConGasto,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.menudo.hero,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: context.menudo.hero.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
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
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                fmt(totalGasto),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.2,
                ),
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
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  diasConGasto.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
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

  const _HeatmapCard({
    required this.gastoPorDia,
    required this.maxGasto,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.menudo.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["D", "L", "M", "M", "J", "V", "S"]
                .map(
                  (d) => Text(
                    d,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.menudo.textMuted,
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: (12)),
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
              final bool isToday = dia == DateTime.now().day;
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
          SizedBox(height: (20)),
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

  const _DayCell({
    required this.day,
    required this.amount,
    required this.intensity,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = context.menudo.primary;
    } else if (amount > 0) {
      bgColor = context.menudo.primary.withValues(
        alpha: 0.1 + (intensity * 0.8),
      );
    } else if (isToday) {
      bgColor = context.menudo.surfaceElevated;
    }

    return MenudoGestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday && !isSelected
                ? context.menudo.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          day.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: (isToday || isSelected)
                ? FontWeight.w900
                : FontWeight.w600,
            color: isSelected
                ? context.menudo.surface
                : amount > 0
                ? (intensity > 0.5
                      ? context.menudo.surface
                      : context.menudo.primary)
                : context.menudo.textSecondary,
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
        Text(
          "Menos",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.menudo.textMuted,
          ),
        ),
        SizedBox(width: 8),
        ...[0.1, 0.3, 0.5, 0.7, 0.9].map(
          (op) => Container(
            width: (14),
            height: (14),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: context.menudo.primary.withValues(alpha: op),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(width: 4),
        Text(
          "Más",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.menudo.textMuted,
          ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final int selectedDay;
  final double dayTotal;
  final String monthLabel;
  final String Function(double) fmt;

  const _DayHeader({
    required this.selectedDay,
    required this.dayTotal,
    required this.monthLabel,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$selectedDay de $monthLabel",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: context.menudo.textMain,
            letterSpacing: -0.4,
          ),
        ),
        if (dayTotal > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.menudo.dangerLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              fmt(dayTotal),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: context.menudo.danger,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayTransactionsList extends StatelessWidget {
  final List<MenudoTransaction> dayTxns;
  final String Function(double) fmt;
  final String Function(MenudoTransaction) subtitleFormatter;

  const _DayTransactionsList({
    required this.dayTxns,
    required this.fmt,
    this.subtitleFormatter = _defaultSubtitle,
  });

  static String _defaultSubtitle(MenudoTransaction transaction) =>
      transaction.catKey.replaceAll('-', ' ');

  @override
  Widget build(BuildContext context) {
    if (dayTxns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(
              MenudoCupertinoIcons.calendarSearch,
              size: (24),
              color: context.menudo.textMuted,
            ),
            SizedBox(height: (10)),
            Text(
              "Sin movimientos este día",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.menudo.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.menudo.border),
      ),
      child: Column(
        children: List.generate(dayTxns.length, (i) {
          final t = dayTxns[i];
          return _DayTransactionTile(
            transaction: t,
            fmt: fmt,
            subtitle: subtitleFormatter(t),
            isLast: i == dayTxns.length - 1,
            onTap: () {
              MenudoHaptics.light();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
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
  final String subtitle;
  final bool isLast;
  final VoidCallback onTap;

  const _DayTransactionTile({
    required this.transaction,
    required this.fmt,
    required this.subtitle,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: context.menudo.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    transaction.icono,
                    size: (20),
                    color: context.menudo.textSecondary,
                  ),
                ),
                SizedBox(width: (14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.desc,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.menudo.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.menudo.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  formatTransactionAmountLabel(transaction),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: transaction.tipo == "ingreso"
                        ? context.menudo.success
                        : context.menudo.textMain,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 0.5,
              color: context.menudo.divider,
              indent: 78,
              endIndent: 20,
            ),
        ],
      ),
    );
  }
}
