import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/data/mock_data.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/asset_category_icon.dart';
import '../../../shared/widgets/variation_badge.dart';

class AssetDetailScreen extends StatelessWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context) {
    final asset = MockData.assets.firstWhere(
      (a) => a.id == assetId,
      orElse: () => MockData.assets.first,
    );
    final formatter = NumberFormat('#,##0', 'en_US');
    final prefix = asset.currency == 'USD' ? '\$' : 'RD\$';

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Value Header ──
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AssetCategoryIcon(category: asset.category, size: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    asset.name,
                                    style: AppTextStyles.headlineLarge,
                                  ),
                                ),
                                if (asset.tickerSymbol != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.cardBorder,
                                      ),
                                    ),
                                    child: Text(
                                      asset.tickerSymbol!,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              asset.institution,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('VALOR ACTUAL', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 4),
                  Text(
                    '$prefix ${formatter.format(asset.currentValue)}',
                    style: AppTextStyles.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      VariationBadge(percentage: asset.variationPercent),
                      if (asset.lastSynced != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.sync,
                              color: AppColors.textTertiary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sincronizado hace ${DateTime.now().difference(asset.lastSynced!).inMinutes} min',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // ── History Chart ──
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HISTORIAL', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _getInterval(asset.sparklineData),
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: AppColors.cardBorder,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => AppColors.surface,
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: asset.sparklineData
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                            isCurved: true,
                            color: asset.isPositive
                                ? AppColors.positive
                                : AppColors.negative,
                            barWidth: 2,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) {
                                if (index == asset.sparklineData.length - 1) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: asset.isPositive
                                        ? AppColors.positive
                                        : AppColors.negative,
                                    strokeWidth: 0,
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
                              color:
                                  (asset.isPositive
                                          ? AppColors.positive
                                          : AppColors.negative)
                                      .withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 20),

            // ── Details ──
            GlassCard(
              child: Column(
                children: [
                  _DetailRow('Categoría', asset.category.label),
                  _DetailRow('Institución', asset.institution),
                  _DetailRow('Moneda', asset.currency),
                  _DetailRow(
                    'Valor anterior',
                    '$prefix ${formatter.format(asset.previousValue)}',
                  ),
                  _DetailRow(
                    'Variación',
                    '${asset.isPositive ? '+' : ''}$prefix ${formatter.format(asset.variation.abs())}',
                  ),
                  _DetailRow(
                    'ROI',
                    '${asset.variationPercent >= 0 ? '+' : ''}${asset.variationPercent.toStringAsFixed(2)}%',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 20),

            // ── Notes ──
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOTAS', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 8),
                  Text(
                    'Sin notas agregadas. Toca para agregar una nota sobre este activo.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  double _getInterval(List<double> data) {
    if (data.isEmpty) return 1;
    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    return (max - min) / 3;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}
