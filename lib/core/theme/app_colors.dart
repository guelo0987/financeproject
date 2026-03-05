import 'package:flutter/material.dart';

/// Patrimonium — Blue fintech color palette (based on logo)
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF0F1526);
  static const Color surfaceLight = Color(0xFF172035);
  static const Color cardBorder = Color(0x0FFFFFFF); // 6%

  // ── Blue Accent (from logo) ──────────────────
  static const Color accent = Color(0xFF2B6CB0);       // navy blue
  static const Color accentBright = Color(0xFF38BDF8);  // sky/cyan
  static const Color accentDim = Color(0xFF1A4B8A);     // deep navy
  static const Color accentSurface = Color(0x1A2B6CB0); // 10% opacity

  // ── White ────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteDim = Color(0xB3FFFFFF);      // 70%

  // ── Semantic ──────────────────────────────────
  static const Color positive = Color(0xFF00E5A0);
  static const Color positiveDim = Color(0xFF0A3D2E);
  static const Color negative = Color(0xFFFF4D6A);
  static const Color negativeDim = Color(0xFF3D0A18);

  // ── Text ──────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF48484A);

  // ── Asset Category Colors ─────────────────────
  static const Color categoryCash = Color(0xFF00E5A0);
  static const Color categoryInvestments = Color(0xFF5E8BFF);
  static const Color categoryCrypto = Color(0xFFF7931A);
  static const Color categoryRealEstate = Color(0xFFE5A84C);
  static const Color categoryVehicles = Color(0xFFAF52DE);
  static const Color categoryBankAccounts = Color(0xFF30D5C8);

  // ── Chart palette ─────────────────────────────
  static const List<Color> chartPalette = [
    categoryCash,
    categoryInvestments,
    categoryCrypto,
    categoryRealEstate,
    categoryVehicles,
    categoryBankAccounts,
  ];

  // ── Glassmorphism ─────────────────────────────
  static const Color glassBackground = Color(0x14FFFFFF); // 8%
  static const Color glassBorder = Color(0x0FFFFFFF);      // 6%
  static final List<Color> glassGradient = [
    const Color(0x14FFFFFF),
    const Color(0x05FFFFFF),
  ];
}
