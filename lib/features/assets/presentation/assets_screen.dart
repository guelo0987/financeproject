import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/data/models.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_text_field.dart';
import '../../../shared/widgets/menudo_chip.dart';
import '../../../shared/widgets/menudo_tap_target.dart';

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
      backgroundColor: context.menudo.background,
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
                        MenudoIconButton(
                          icon: Icon(
                            MenudoCupertinoIcons.add_circle,
                            color: context.menudo.primary,
                            size: (28),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: (16)),
                    MenudoTextField(
                      label: '',
                      hint: 'Buscar activo...',
                      prefixIcon: Icon(
                        MenudoCupertinoIcons.search,
                        color: context.menudo.textSecondary,
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
                      SizedBox(height: (24)),
                      SizedBox(
                        height: (200),
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 60,
                                sections: [
                                  PieChartSectionData(
                                    color: context.menudo.success,
                                    value: 40,
                                    title: '',
                                    radius: 24,
                                  ),
                                  PieChartSectionData(
                                    color: context.menudo.primary,
                                    value: 30,
                                    title: '',
                                    radius: 24,
                                  ),
                                  PieChartSectionData(
                                    color: context.menudo.warning,
                                    value: 20,
                                    title: '',
                                    radius: 24,
                                  ),
                                  PieChartSectionData(
                                    color: context.menudo.danger,
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
                                      color: context.menudo.textMuted,
                                    ),
                                  ),
                                  Text('RD\$1.2M', style: MenudoTextStyles.h2),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: (16)),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildLegend(
                            'Efectivo',
                            context.menudo.success,
                            '40%',
                          ),
                          _buildLegend(
                            'Inversiones',
                            context.menudo.primary,
                            '30%',
                          ),
                          _buildLegend('Bienes', context.menudo.warning, '20%'),
                          _buildLegend('Otros', context.menudo.danger, '10%'),
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
                          color: context.menudo.textMuted,
                        ),
                      ),
                      SizedBox(height: (12)),
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
                                    color: context.menudo.primaryLight
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    MenudoCupertinoIcons.account_balance,
                                    color: context.menudo.primary,
                                  ),
                                ),
                                SizedBox(width: (16)),
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
                                              color: context.menudo.textMuted,
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
                                    SizedBox(height: 4),
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
            const SliverToBoxAdapter(child: SizedBox(height: (100))),
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
          width: (10),
          height: (10),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text('$label $percent', style: MenudoTextStyles.bodySmall),
      ],
    );
  }
}
