import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum MenudoChipVariant { success, danger, warning, neutral, primary }

class MenudoChip extends StatelessWidget {
  final String label;
  final MenudoChipVariant variant;
  final bool isSmall;

  const MenudoChip(
    this.label, {
    super.key,
    this.variant = MenudoChipVariant.neutral,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (variant) {
      case MenudoChipVariant.success:
        bgColor = MenudoColors.successLight;
        textColor = MenudoColors.success;
        break;
      case MenudoChipVariant.danger:
        bgColor = MenudoColors.dangerLight;
        textColor = MenudoColors.danger;
        break;
      case MenudoChipVariant.warning:
        bgColor = MenudoColors.warningLight;
        textColor = MenudoColors.warning;
        break;
      case MenudoChipVariant.primary:
        bgColor = MenudoColors.primaryLight.withValues(alpha: 0.3);
        textColor = MenudoColors.primaryDark;
        break;
      case MenudoChipVariant.neutral:
        bgColor = MenudoColors.divider;
        textColor = MenudoColors.textSecondary;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100), // pill
      ),
      child: Text(
        label,
        style: MenudoTextStyles.labelBold.copyWith(
          color: textColor,
          fontSize: isSmall ? 10 : 12,
        ),
      ),
    );
  }
}
