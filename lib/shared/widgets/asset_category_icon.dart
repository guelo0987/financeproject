import 'package:flutter/material.dart';
import '../../core/data/models.dart';

/// Circular icon badge for asset categories
class AssetCategoryIcon extends StatelessWidget {
  final AssetCategory category;
  final double size;

  const AssetCategoryIcon({
    super.key,
    required this.category,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          category.icon,
          color: category.color,
          size: size * 0.5,
        ),
      ),
    );
  }
}
