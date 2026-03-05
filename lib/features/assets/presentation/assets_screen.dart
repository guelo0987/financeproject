import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/data/models.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/asset_category_icon.dart';
import '../../../shared/widgets/mini_sparkline.dart';
import '../../../shared/widgets/variation_badge.dart';

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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Portafolio', style: AppTextStyles.displaySmall),
                    const SizedBox(height: 4),
                    Text(
                      '${MockData.assets.length} activos registrados',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            // ── Category Groups ──
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = groupedAssets.entries.elementAt(index);
                  final category = entry.key;
                  final assets = entry.value;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _CategoryGroup(
                      category: category,
                      assets: assets,
                    ),
                  ).animate()
                      .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                      .slideX(begin: 0.05);
                },
                childCount: groupedAssets.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Category Group (Expandable) ─────────────────

class _CategoryGroup extends StatefulWidget {
  final AssetCategory category;
  final List<Asset> assets;

  const _CategoryGroup({required this.category, required this.assets});

  @override
  State<_CategoryGroup> createState() => _CategoryGroupState();
}

class _CategoryGroupState extends State<_CategoryGroup> {
  bool _expanded = true;

  double get _totalValue {
    return widget.assets.fold(0.0, (sum, a) {
      return sum +
          (a.currency == 'USD' ? a.currentValue * MockData.usdToDop : a.currentValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AssetCategoryIcon(category: widget.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.category.label,
                            style: AppTextStyles.headlineSmall),
                        Text(
                          '${widget.assets.length} ${widget.assets.length == 1 ? 'activo' : 'activos'}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'RD\$ ${formatter.format(_totalValue)}',
                    style: AppTextStyles.cardValue.copyWith(fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textTertiary, size: 20),
                  ),
                ],
              ),
            ),
          ),
          // Asset Items
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                const Divider(indent: 16, endIndent: 16),
                ...widget.assets.map((asset) => _AssetListItem(asset: asset)),
                const SizedBox(height: 8),
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState:
                _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ── Asset List Item ─────────────────────────────

class _AssetListItem extends StatelessWidget {
  final Asset asset;

  const _AssetListItem({required this.asset});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final prefix = asset.currency == 'USD' ? '\$' : 'RD\$';

    return InkWell(
      onTap: () => context.push('/assets/detail/${asset.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(asset.institution, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            MiniSparkline(data: asset.sparklineData, width: 50, height: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$prefix ${formatter.format(asset.currentValue)}',
                  style: AppTextStyles.cardValue.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                VariationBadge(
                  percentage: asset.variationPercent,
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
