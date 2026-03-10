import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum MenudoChipVariant { success, danger, warning, neutral, primary, custom }

class MenudoChip extends StatelessWidget {
  final String label;
  final MenudoChipVariant variant;
  final bool isSmall;
  final Color? customColor;
  final Color? customBgColor;

  const MenudoChip(
    this.label, {
    super.key,
    this.variant = MenudoChipVariant.neutral,
    this.isSmall = false,
    this.customColor,
    this.customBgColor,
  });

  /// Mimics `<Tag label="..." color={c} bg={c+"22"} sm />`
  factory MenudoChip.custom({
    required String label,
    required Color color,
    Color? bgColor,
    bool isSmall = false,
  }) {
    return MenudoChip(
      label,
      variant: MenudoChipVariant.custom,
      customColor: color,
      customBgColor:
          bgColor ??
          color.withValues(alpha: 0.15), // roughly "22" hex in opacity (13%)
      isSmall: isSmall,
    );
  }

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
      case MenudoChipVariant.custom:
        bgColor = customBgColor ?? AppColors.g1;
        textColor = customColor ?? AppColors.e8;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 2 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100), // pill
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: isSmall ? 10 : 12,
        ),
      ),
    );
  }
}
