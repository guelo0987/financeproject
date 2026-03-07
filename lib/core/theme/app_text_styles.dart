import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class MenudoTextStyles {
  // Hero amount
  static final TextStyle heroAmount = GoogleFonts.plusJakartaSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    color: MenudoColors.textOnDark,
  );

  // Headlines
  static final TextStyle h1 = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: MenudoColors.textMain,
  );
  static final TextStyle h2 = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: MenudoColors.textMain,
  );
  static final TextStyle h3 = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: MenudoColors.textMain,
  );

  // Body
  static final TextStyle bodyLarge  = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: MenudoColors.textMain,
  );
  static final TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: MenudoColors.textMain,
  );
  static final TextStyle bodySmall  = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: MenudoColors.textMain,
  );

  // Labels
  static final TextStyle labelCaps = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
  static final TextStyle labelBold = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  
  // Amounts
  static final TextStyle amountMedium = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static final TextStyle amountSmall  = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

// --- LEGACY SHIMS FOR UNREFACTORED SCREENS ---
abstract class AppTextStyles {
  static TextStyle get displayLarge => MenudoTextStyles.h1.copyWith(fontSize: 32);
  static TextStyle get displayMedium => MenudoTextStyles.h1;
  static TextStyle get displaySmall => MenudoTextStyles.h2;
  
  static TextStyle get headlineLarge => MenudoTextStyles.h3;
  static TextStyle get headlineMedium => MenudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold);
  static TextStyle get headlineSmall => MenudoTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold);
  
  static TextStyle get titleLarge => MenudoTextStyles.h3;
  static TextStyle get titleMedium => MenudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get titleSmall => MenudoTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600);
  
  static TextStyle get bodyLarge => MenudoTextStyles.bodyLarge;
  static TextStyle get bodyMedium => MenudoTextStyles.bodyMedium;
  static TextStyle get bodySmall => MenudoTextStyles.bodySmall;
  
  static TextStyle get labelLarge => MenudoTextStyles.labelBold;
  static TextStyle get labelMedium => MenudoTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get labelSmall => MenudoTextStyles.labelCaps;
  
  static TextStyle get sectionTitle => MenudoTextStyles.labelCaps;
  static TextStyle get amountLarge => MenudoTextStyles.heroAmount;
  static TextStyle get amountMedium => MenudoTextStyles.amountSmall.copyWith(fontSize: 24);
  static TextStyle get cardValue => MenudoTextStyles.amountSmall;
  static TextStyle get numpadKey => MenudoTextStyles.h2;
  static TextStyle get variationPositive => MenudoTextStyles.labelBold.copyWith(color: AppColors.positive);
  static TextStyle get variationNegative => MenudoTextStyles.labelBold.copyWith(color: AppColors.negative);
}
