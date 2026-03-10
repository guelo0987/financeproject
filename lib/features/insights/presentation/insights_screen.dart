import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_chip.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Análisis', style: MenudoTextStyles.h1),
                        const MenudoChip(
                          'Marzo 2026',
                          variant: MenudoChipVariant.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: MenudoColors.divider,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _buildTab(0, 'Flujo de caja'),
                          _buildTab(1, 'Gastos'),
                          _buildTab(2, 'Rentabilidad'),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildContentForTab(_selectedTab),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? MenudoColors.textMain
                  : MenudoColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentForTab(int tab) {
    switch (tab) {
      case 0:
        return _buildCashflowTab();
      case 1:
        return _buildExpensesTab();
      case 2:
      default:
        return _buildProfitabilityTab();
    }
  }

  Widget _buildCashflowTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('tab0'),
      children: [
        MenudoCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Evolución (6 meses)', style: MenudoTextStyles.h3),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 20,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            const style = TextStyle(
                              color: MenudoColors.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            );
                            String text;
                            switch (value.toInt()) {
                              case 0:
                                text = 'Oct';
                                break;
                              case 1:
                                text = 'Nov';
                                break;
                              case 2:
                                text = 'Dic';
                                break;
                              case 3:
                                text = 'Ene';
                                break;
                              case 4:
                                text = 'Feb';
                                break;
                              case 5:
                                text = 'Mar';
                                break;
                              default:
                                text = '';
                                break;
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(text, style: style),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _makeGroupData(0, 15, 12),
                      _makeGroupData(1, 16, 14),
                      _makeGroupData(2, 19, 18),
                      _makeGroupData(3, 14, 11),
                      _makeGroupData(4, 15, 13),
                      _makeGroupData(
                        5,
                        17,
                        10,
                      ), // Current has High Income, Low Exp
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, color: MenudoColors.success),
                  const SizedBox(width: 6),
                  const Text(
                    'Ingresos',
                    style: TextStyle(
                      fontSize: 12,
                      color: MenudoColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(width: 12, height: 12, color: MenudoColors.danger),
                  const SizedBox(width: 6),
                  const Text(
                    'Gastos',
                    style: TextStyle(
                      fontSize: 12,
                      color: MenudoColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: MenudoColors.success,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: y2,
          color: MenudoColors.danger,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildExpensesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('tab1'),
      children: [
        MenudoCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gastos por categoría', style: MenudoTextStyles.h3),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        color: MenudoColors.danger,
                        value: 40,
                        title: '40%',
                        radius: 30,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: MenudoColors.warning,
                        value: 30,
                        title: '30%',
                        radius: 30,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: MenudoColors.primary,
                        value: 15,
                        title: '15%',
                        radius: 30,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: MenudoColors.success,
                        value: 15,
                        title: '15%',
                        radius: 30,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildExpenseLegend(
                'Vivienda',
                MenudoColors.danger,
                'RD\$25,000',
              ),
              const SizedBox(height: 8),
              _buildExpenseLegend('Comida', MenudoColors.warning, 'RD\$18,000'),
              const SizedBox(height: 8),
              _buildExpenseLegend(
                'Transporte',
                MenudoColors.primary,
                'RD\$9,000',
              ),
              const SizedBox(height: 8),
              _buildExpenseLegend('Ocio', MenudoColors.success, 'RD\$9,000'),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _buildExpenseLegend(String title, Color color, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: MenudoTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: MenudoTextStyles.amountSmall.copyWith(
            color: MenudoColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfitabilityTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('tab2'),
      children: [
        MenudoCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rendimiento global', style: MenudoTextStyles.h3),
              const SizedBox(height: 4),
              const Text(
                '+12.4% este año',
                style: TextStyle(
                  color: MenudoColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (val) => const FlLine(
                        color: MenudoColors.divider,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: const FlTitlesData(
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 1),
                          FlSpot(1, 1.2),
                          FlSpot(2, 1.1),
                          FlSpot(3, 1.5),
                          FlSpot(4, 1.4),
                          FlSpot(5, 1.8),
                        ],
                        isCurved: true,
                        color: MenudoColors.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: MenudoColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.05);
  }
}
