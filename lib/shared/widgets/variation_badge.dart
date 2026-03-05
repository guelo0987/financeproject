import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Badge showing positive/negative variation with arrow
class VariationBadge extends StatelessWidget {
  final double percentage;
  final double? absoluteValue;
  final bool showAbsolute;
  final bool compact;

  const VariationBadge({
    super.key,
    required this.percentage,
    this.absoluteValue,
    this.showAbsolute = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percentage >= 0;
    final color = isPositive ? AppColors.positive : AppColors.negative;
    final bgColor = isPositive ? AppColors.positiveDim : AppColors.negativeDim;
    final arrow = isPositive ? '↑' : '↓';
    final sign = isPositive ? '+' : '';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$arrow $sign${percentage.toStringAsFixed(2)}%',
            style: compact
                ? AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)
                : (isPositive ? AppTextStyles.variationPositive : AppTextStyles.variationNegative),
          ),
        ],
      ),
    );
  }
}
