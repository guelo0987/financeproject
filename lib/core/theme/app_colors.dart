import 'package:flutter/material.dart';

abstract class AppColors {
  // Base
  static const Color white = Color(0xFFFFFFFF); // w
  static const Color black = Color(0xFF111827); // b

  // Emerald (Primary)
  static const Color e8 = Color(0xFF065F46); // Emerald 800
  static const Color e7 = Color(0xFF047857); // Emerald 700
  static const Color e6 = Color(0xFF059669); // Emerald 600
  static const Color e1 = Color(0xFFD1FAE5); // Emerald 100
  static const Color e0 = Color(0xFFECFDF5); // Emerald 50

  // Orange (Accent)
  static const Color o5 = Color(0xFFF97316); // Orange 500
  static const Color o1 = Color(0xFFFFEDD5); // Orange 100

  // Greys (Neutral)
  static const Color g5 = Color(0xFF6B7280); // Gray 500
  static const Color g4 = Color(0xFF9CA3AF); // Gray 400
  static const Color g3 = Color(0xFFD1D5DB); // Gray 300
  static const Color g2 = Color(0xFFE5E7EB); // Gray 200
  static const Color g1 = Color(0xFFF3F4F6); // Gray 100
  static const Color g0 = Color(0xFFF9FAFB); // Gray 50

  // Semantic
  static const Color r5 = Color(0xFFEF4444); // Red 500
  static const Color r1 = Color(0xFFFEE2E2); // Red 100
  static const Color a5 = Color(0xFFF59E0B); // Amber 500
  static const Color a1 = Color(0xFFFEF3C7); // Amber 100
  static const Color b5 = Color(0xFF3B82F6); // Blue 500
  static const Color p5 = Color(0xFF8B5CF6); // Purple 500
  static const Color pk = Color(0xFFEC4899); // Pink 500

  // Semantic Backgrounds (Compatibility)
  static const Color background = g0;
  static const Color surface = white;
  static const Color surfaceLight = g0;

  // Primary Theme (Compatibility)
  static const Color primary = e8;
  static const Color accent = o5;
  static const Color accentBright = o1;
  static const Color accentSurface = o1;
  static const Color primaryGlow = Color(0x4DF97316);

  // Text Colors (Compatibility)
  static const Color textPrimary = e8;
  static const Color textSecondary = g5;
  static const Color textTertiary = g4;
  static const Color textOnDark = white;
  static const Color textMuted = g4;

  // Borders & Dividers
  static const Color border = g2;
  static const Color cardBorder = g2;
  static const Color divider = g1;

  // Status Colors (Compatibility)
  static const Color positive = e6;
  static const Color negative = r5;
  static const Color warning = a5;
  static const Color positiveDim = e1;
  static const Color negativeDim = r1;
  static const Color glassBorder = g1;
  static const List<Color> glassGradient = [Colors.white24, Colors.white10];
  static const Color accentDim = o1;

  // Categories (Legacy shims for compilation)
  static const categoryHousing = p5;
  static const categoryFood = o5;
  static const categoryTransport = b5;
  static const categoryEntertainment = pk;
  static const categoryShopping = r5;
  static const categoryHealth = e6;
  static const categoryServices = a5;

  static const categoryBankAccounts = b5;
  static const categoryInvestments = e6;
  static const categoryCrypto = a5;
  static const categoryRealEstate = p5;
  static const categoryVehicles = r5;
  static const categoryCash = e6;
}

abstract class MenudoColors {
  // Aliases for compatibility with files using MenudoColors
  static const Color appBg = AppColors.g0;
  static const Color cardBg = AppColors.e8;
  static const Color cardElevated = AppColors.e7;
  static const Color surfaceMuted = AppColors.e0;
  static const Color textMain = AppColors.e8;
  static const Color textSecondary = AppColors.g5;
  static const Color textMuted = AppColors.g4;
  static const Color textOnDark = AppColors.white;
  static const Color textOnDarkSub = AppColors.g3;
  static const Color primary = AppColors.o5;
  static const Color primaryLight = AppColors.o1;
  static const Color primaryDark = Color(0xFFEA580C);
  static const Color primaryGlow = AppColors.primaryGlow;
  static const Color success = AppColors.e6;
  static const Color successLight = AppColors.e1;
  static const Color danger = AppColors.r5;
  static const Color dangerLight = AppColors.r1;
  static const Color warning = AppColors.a5;
  static const Color warningLight = AppColors.a1;
  static const Color border = AppColors.g2;
  static const Color borderActive = AppColors.o5;
  static const Color divider = AppColors.g1;
  static const Color tabActive = AppColors.e8;
  static const Color tabInactive = AppColors.g4;

  static const Color orangeDark = Color(0xFFEA580C);
}
