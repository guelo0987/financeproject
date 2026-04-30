import 'package:flutter/material.dart';

import 'app_colors.dart';

TextStyle _textStyle({
  required double fontSize,
  required FontWeight fontWeight,
  Color? color,
  double? letterSpacing,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

abstract class MenudoTextStyles {
  static final TextStyle heroAmount = _textStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    color: MenudoColors.textOnDark,
  );

  static final TextStyle h1 = _textStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static final TextStyle h2 = _textStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static final TextStyle h3 = _textStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );

  static final TextStyle bodyLarge = _textStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle bodyMedium = _textStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle bodySmall = _textStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle labelCaps = _textStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static final TextStyle labelBold = _textStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle amountMedium = _textStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static final TextStyle amountSmall = _textStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
}

abstract class AppTextStyles {
  static TextStyle get displayLarge =>
      MenudoTextStyles.h1.copyWith(fontSize: 32);
  static TextStyle get displayMedium => MenudoTextStyles.h1;
  static TextStyle get displaySmall => MenudoTextStyles.h2;

  static TextStyle get headlineLarge => MenudoTextStyles.h3;
  static TextStyle get headlineMedium =>
      MenudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold);
  static TextStyle get headlineSmall =>
      MenudoTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold);

  static TextStyle get titleLarge => MenudoTextStyles.h3;
  static TextStyle get titleMedium =>
      MenudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get titleSmall =>
      MenudoTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600);

  static TextStyle get bodyLarge => MenudoTextStyles.bodyLarge;
  static TextStyle get bodyMedium => MenudoTextStyles.bodyMedium;
  static TextStyle get bodySmall => MenudoTextStyles.bodySmall;

  static TextStyle get labelLarge => MenudoTextStyles.labelBold;
  static TextStyle get labelMedium =>
      MenudoTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get labelSmall => MenudoTextStyles.labelCaps;

  static TextStyle get sectionTitle => MenudoTextStyles.labelCaps;
  static TextStyle get amountLarge => MenudoTextStyles.heroAmount;
  static TextStyle get amountMedium =>
      MenudoTextStyles.amountSmall.copyWith(fontSize: 24);
  static TextStyle get cardValue => MenudoTextStyles.amountSmall;
  static TextStyle get numpadKey => MenudoTextStyles.h2;
  static TextStyle get variationPositive =>
      MenudoTextStyles.labelBold.copyWith(color: AppColors.positive);
  static TextStyle get variationNegative =>
      MenudoTextStyles.labelBold.copyWith(color: AppColors.negative);
}
