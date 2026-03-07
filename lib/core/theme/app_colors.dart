import 'package:flutter/material.dart';

abstract class MenudoColors {
  // Backgrounds
  static const Color appBg         = Color(0xFFFFFFFF);
  static const Color cardBg        = Color(0xFF065F46); // Emerald 800
  static const Color cardElevated  = Color(0xFF064E3B); // Emerald 900
  static const Color surfaceMuted  = Color(0xFFF0FDF4); // Emerald 50

  // Text
  static const Color textMain      = Color(0xFF022C22); // Emerald 950
  static const Color textSecondary = Color(0xFF047857); // Emerald 700
  static const Color textMuted     = Color(0xFF6EE7B7); // Emerald 300
  static const Color textOnDark    = Color(0xFFFFFFFF);
  static const Color textOnDarkSub = Color(0xFFA7F3D0); // Emerald 200

  // Primary accent
  static const Color primary       = Color(0xFFF97316); // Orange 500
  static const Color primaryLight  = Color(0xFFFED7AA); // Orange 200
  static const Color primaryDark   = Color(0xFFEA580C); // Orange 600
  static const Color primaryGlow   = Color(0x4DF97316); // Orange 500 glow

  // Semantic
  static const Color success       = Color(0xFF059669); // Emerald 600
  static const Color successLight  = Color(0xFFD1FAE5); // Emerald 100
  static const Color danger        = Color(0xFFF43F5E); // Rose 500
  static const Color dangerLight   = Color(0xFFFFE4E6); // Rose 100
  static const Color warning       = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight  = Color(0xFFFEF3C7); // Amber 100

  // Borders & dividers
  static const Color border        = Color(0xFFE5E7EB); // Gray 200
  static const Color borderActive  = Color(0xFFF97316); // Orange 500
  static const Color divider       = Color(0xFFF3F4F6); // Gray 100

  // Tab bar
  static const Color tabActive     = Color(0xFF065F46); // Emerald 800
  static const Color tabInactive   = Color(0xFF9CA3AF); // Gray 400
}

// --- LEGACY SHIMS FOR UNREFACTORED SCREENS ---
abstract class AppColors {
  static const primary = MenudoColors.primary;
  static const accent = MenudoColors.primary;
  static const accentBright = MenudoColors.primaryLight;
  static const accentSurface = MenudoColors.primaryLight;
  
  static const background = MenudoColors.appBg;
  static const surface = MenudoColors.cardBg;
  static const surfaceLight = MenudoColors.divider;
  
  static const textPrimary = MenudoColors.textMain;
  static const textSecondary = MenudoColors.textSecondary;
  static const textTertiary = MenudoColors.textMuted;
  
  static const border = MenudoColors.border;
  static const cardBorder = MenudoColors.border;
  
  static const positive = MenudoColors.success;
  static const negative = MenudoColors.danger;
  static const warning = MenudoColors.warning;
  
  static const categoryHousing = Color(0xFFFCA5A5);
  static const categoryFood = Color(0xFFFCD34D);
  static const categoryTransport = Color(0xFF93C5FD);
  static const categoryEntertainment = Color(0xFFC4B5FD);
  static const categoryShopping = Color(0xFFF9A8D4);
  static const categoryHealth = Color(0xFF6EE7B7);
  static const categoryServices = Color(0xFFD8B4FE);
  
  static const categoryBankAccounts = Color(0xFF60A5FA);
  static const categoryInvestments = Color(0xFF34D399);
  static const categoryCrypto = Color(0xFFFBBF24);
  static const categoryRealEstate = Color(0xFFA78BFA);
  static const categoryVehicles = Color(0xFFF87171);
  static const categoryCash = Color(0xFF4ADE80);
  static const positiveDim = MenudoColors.successLight;
  static const negativeDim = MenudoColors.dangerLight;
  static const glassBorder = MenudoColors.divider;
  static const glassGradient = [Colors.white24, Colors.white10];
  static const accentDim = MenudoColors.primaryLight;
}
