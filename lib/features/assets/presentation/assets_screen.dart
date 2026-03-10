import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/data/models.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_text_field.dart';
import '../../../shared/widgets/menudo_chip.dart';

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Group assets by category
    final groupedAssets = <AssetCategory, List<Asset>>{};
    for (final asset in MockData.assets) {
      groupedAssets.putIfAbsent(asset.category, () => []).add(asset);
    }

    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Activos', style: MenudoTextStyles.h1),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: MenudoColors.primary,
                            size: 28,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const MenudoTextField(
                      label: '',
                      hint: 'Buscar activo...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: MenudoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            // Doughnut Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: MenudoCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Distribución del Portafolio',
                        style: MenudoTextStyles.h3,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 60,
                                sections: [
                                  PieChartSectionData(
                                    color: MenudoColors.success,
                                    value: 40,
                                    title: '',
                                    radius: 24,
                                  ),
                                  PieChartSectionData(
                                    color: MenudoColors.primary,
                                    value: 30,
                                    title: '',
                                    radius: 24,
                                  ),
                                  PieChartSectionData(
                                    color: MenudoColors.warning,
                                    value: 20,
                                    title: '',
                                    radius: 24,
                                  ),
                                  PieChartSectionData(
                                    color: MenudoColors.danger,
                                    value: 10,
                                    title: '',
                                    radius: 24,
                                  ),
                                ],
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Total',
                                    style: MenudoTextStyles.bodySmall.copyWith(
                                      color: MenudoColors.textMuted,
                                    ),
                                  ),
                                  Text('RD\$1.2M', style: MenudoTextStyles.h2),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildLegend('Efectivo', MenudoColors.success, '40%'),
                          _buildLegend(
                            'Inversiones',
                            MenudoColors.primary,
                            '30%',
                          ),
                          _buildLegend('Bienes', MenudoColors.warning, '20%'),
                          _buildLegend('Otros', MenudoColors.danger, '10%'),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ),
            ),

            // Asset List
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final entry = groupedAssets.entries.elementAt(index);
                final category = entry.key;
                final assets = entry.value;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name.toUpperCase(),
                        style: MenudoTextStyles.labelCaps.copyWith(
                          color: MenudoColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...assets.map(
                        (asset) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MenudoCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: MenudoColors.primaryLight.withValues(
                                      alpha: 0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance,
                                    color: MenudoColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        asset.name,
                                        style: MenudoTextStyles.bodyLarge
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        asset.currency,
                                        style: MenudoTextStyles.bodySmall
                                            .copyWith(
                                              color: MenudoColors.textMuted,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${asset.currentValue.toStringAsFixed(2)}',
                                      style: MenudoTextStyles.amountSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    const MenudoChip(
                                      '+1.2%',
                                      variant: MenudoChipVariant.success,
                                      isSmall: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(
                  duration: 400.ms,
                  delay: (200 + index * 100).ms,
                );
              }, childCount: groupedAssets.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color, String percent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label $percent', style: MenudoTextStyles.bodySmall),
      ],
    );
  }
}
