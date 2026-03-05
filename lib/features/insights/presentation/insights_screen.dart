import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/data/models.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_counter.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final totalIncome = MockData.recentTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpenses = MockData.expenseCategories.fold(0.0, (s, c) => s + c.amount);
    final savingsRate =
        totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0.0;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Análisis', style: AppTextStyles.displaySmall),
                    const SizedBox(height: 4),
                    Text(
                      'Evolución y métricas de tu patrimonio',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            // ── Key Indicators ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _IndicatorCard(
                        label: 'Tasa de Ahorro',
                        value: '${savingsRate.toStringAsFixed(1)}%',
                        icon: Icons.savings_outlined,
                        color: AppColors.positive,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _IndicatorCard(
                        label: 'ROI Total',
                        value: '+8.5%',
                        icon: Icons.trending_up,
                        color: AppColors.accentBright,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _IndicatorCard(
                        label: 'Deuda/Activos',
                        value: '12%',
                        icon: Icons.balance,
                        color: AppColors.categoryBankAccounts,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            ),

            // ── Net Worth Evolution ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EVOLUCIÓN DEL PATRIMONIO',
                          style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: _NetWorthChart(),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
            ),

            // ── Expense Distribution ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DISTRIBUCIÓN DE GASTOS',
                          style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 4),
                      Text('Mes actual', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 16),
                      ...MockData.expenseCategories.map(
                        (cat) => _ExpenseBar(category: cat, maxAmount: totalExpenses),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total gastos', style: AppTextStyles.labelLarge),
                          AnimatedCounter(
                            value: totalExpenses,
                            style: AppTextStyles.cardValue,
                            prefix: 'RD\$ ',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.05),
            ),

            // ── Projection ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROYECCIÓN DE PATRIMONIO',
                          style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 16),
                      _ProjectionRow(
                        label: '1 año',
                        value: MockData.totalNetWorthDOP * 1.12,
                        formatter: formatter,
                      ),
                      _ProjectionRow(
                        label: '3 años',
                        value: MockData.totalNetWorthDOP * 1.40,
                        formatter: formatter,
                      ),
                      _ProjectionRow(
                        label: '5 años',
                        value: MockData.totalNetWorthDOP * 1.76,
                        formatter: formatter,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Basado en tasa de ahorro actual y rendimiento promedio del portafolio',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.05),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Indicator Card ─────────────────────────────

class _IndicatorCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _IndicatorCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.cardValue.copyWith(
            color: color, fontSize: 16,
          )),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ── Net Worth Evolution Chart ───────────────────

class _NetWorthChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final history = MockData.netWorthHistory;
    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value / 1000000))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.cardBorder,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)}M',
                  style: AppTextStyles.labelSmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= history.length) {
                  return const SizedBox.shrink();
                }
                final months = ['Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep',
                    'Oct', 'Nov', 'Dic', 'Ene', 'Feb', 'Mar'];
                if (index >= months.length) return const SizedBox.shrink();
                return Text(months[index], style: AppTextStyles.labelSmall);
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
          ),
        ),
        minY: 8,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accentBright,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                if (index == spots.length - 1) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: AppColors.accentBright,
                    strokeWidth: 2,
                    strokeColor: AppColors.background,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accent.withValues(alpha: 0.25),
                  AppColors.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expense Bar ─────────────────────────────────

class _ExpenseBar extends StatelessWidget {
  final ExpenseCategory category;
  final double maxAmount;

  const _ExpenseBar({required this.category, required this.maxAmount});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final percentage = maxAmount > 0 ? category.amount / maxAmount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Icon(category.icon, size: 16, color: category.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(category.name, style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                )),
              ),
              Text(
                'RD\$ ${formatter.format(category.amount)}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.surfaceLight,
              color: category.color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Projection Row ──────────────────────────────

class _ProjectionRow extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat formatter;

  const _ProjectionRow({
    required this.label,
    required this.value,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(label, style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.accent,
              )),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'RD\$ ${formatter.format(value)}',
              style: AppTextStyles.cardValue.copyWith(fontSize: 16),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
