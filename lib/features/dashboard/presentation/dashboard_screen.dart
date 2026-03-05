import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import '../../../core/data/mock_data.dart';
import '../../../core/data/models.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../../shared/widgets/mini_sparkline.dart';
import '../../../shared/widgets/asset_category_icon.dart';
import '../../../shared/widgets/variation_badge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bienvenido', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 2),
                        Text('Patrimonium', style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.accent,
                        )),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.settings_outlined,
                            color: AppColors.textSecondary, size: 22),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
            ),

            // ── Net Worth Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PATRIMONIO NETO', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 8),
                      AnimatedCounter(
                        value: MockData.totalNetWorthDOP,
                        style: AppTextStyles.netWorthLarge,
                        prefix: 'RD\$ ',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          VariationBadge(
                            percentage: ((MockData.totalNetWorthDOP - MockData.previousNetWorthDOP) /
                                    MockData.previousNetWorthDOP) *
                                100,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'hoy',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.05),
            ),

            // ── Donut Chart ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DISTRIBUCIÓN DE ACTIVOS', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            Expanded(
                              child: _DonutChart(),
                            ),
                            const SizedBox(width: 16),
                            _DonutLegend(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
            ),

            // ── Asset Mini Cards ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('MIS ACTIVOS', style: AppTextStyles.sectionTitle),
                          GestureDetector(
                            onTap: () => context.go('/history'),
                            child: Text('Ver todos', style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.accent,
                            )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: MockData.assets.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        padding: const EdgeInsets.only(right: 20),
                        itemBuilder: (context, index) {
                          final asset = MockData.assets[index];
                          return _AssetMiniCard(asset: asset);
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.05),
            ),

            // ── Recent Transactions ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ÚLTIMOS MOVIMIENTOS', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    ...MockData.recentTransactions.map(
                      (tx) => _TransactionItem(transaction: tx),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.05),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/quick-log'),
        child: const Icon(Icons.add_rounded, size: 28),
      ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }
}

// ── Donut Chart ───────────────────────────────────

class _DonutChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categoryTotals = <AssetCategory, double>{};
    for (final asset in MockData.assets) {
      final value = asset.currency == 'USD'
          ? asset.currentValue * MockData.usdToDop
          : asset.currentValue;
      categoryTotals[asset.category] =
          (categoryTotals[asset.category] ?? 0) + value;
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: categoryTotals.entries.map((entry) {
          return PieChartSectionData(
            value: entry.value,
            color: entry.key.color,
            radius: 35,
            showTitle: false,
          );
        }).toList(),
      ),
    );
  }
}

class _DonutLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categoryTotals = <AssetCategory, double>{};
    for (final asset in MockData.assets) {
      final value = asset.currency == 'USD'
          ? asset.currentValue * MockData.usdToDop
          : asset.currentValue;
      categoryTotals[asset.category] =
          (categoryTotals[asset.category] ?? 0) + value;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryTotals.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: entry.key.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                entry.key.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Asset Mini Card ───────────────────────────────

class _AssetMiniCard extends StatelessWidget {
  final Asset asset;

  const _AssetMiniCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final prefix = asset.currency == 'USD' ? '\$' : 'RD\$';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AssetCategoryIcon(category: asset.category, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    asset.name,
                    style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '$prefix ${formatter.format(asset.currentValue)}',
              style: AppTextStyles.cardValue,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VariationBadge(
                  percentage: asset.variationPercent,
                  compact: true,
                ),
                MiniSparkline(
                  data: asset.sparklineData,
                  width: 45,
                  height: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction Item ──────────────────────────────

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final isIncome = transaction.type == TransactionType.income;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isIncome ? AppColors.positive : AppColors.negative)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transaction.icon,
                color: isIncome ? AppColors.positive : AppColors.negative,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.description,
                      style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(transaction.category,
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'} RD\$ ${formatter.format(transaction.amount)}',
              style: AppTextStyles.cardValue.copyWith(
                color: isIncome ? AppColors.positive : AppColors.negative,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
