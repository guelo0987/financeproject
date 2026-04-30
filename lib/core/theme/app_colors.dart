import 'package:flutter/material.dart';

@immutable
class MenudoPalette extends ThemeExtension<MenudoPalette> {
  const MenudoPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.hero,
    required this.heroElevated,
    required this.textMain,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnDark,
    required this.textOnDarkSub,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryGlow,
    required this.success,
    required this.successLight,
    required this.danger,
    required this.dangerLight,
    required this.warning,
    required this.warningLight,
    required this.border,
    required this.borderActive,
    required this.divider,
    required this.tabActive,
    required this.tabInactive,
    required this.glassBorder,
    required this.glassGradient,
    required this.navBar,
    required this.navBarBorder,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color hero;
  final Color heroElevated;
  final Color textMain;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnDark;
  final Color textOnDarkSub;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryGlow;
  final Color success;
  final Color successLight;
  final Color danger;
  final Color dangerLight;
  final Color warning;
  final Color warningLight;
  final Color border;
  final Color borderActive;
  final Color divider;
  final Color tabActive;
  final Color tabInactive;
  final Color glassBorder;
  final List<Color> glassGradient;
  final Color navBar;
  final Color navBarBorder;

  static const light = MenudoPalette(
    background: AppColors.g0,
    surface: AppColors.white,
    surfaceElevated: AppColors.white,
    surfaceMuted: AppColors.e0,
    hero: AppColors.e8,
    heroElevated: AppColors.e7,
    textMain: AppColors.e8,
    textSecondary: AppColors.g5,
    textMuted: AppColors.g4,
    textOnDark: AppColors.white,
    textOnDarkSub: AppColors.g3,
    primary: AppColors.o5,
    primaryLight: AppColors.o1,
    primaryDark: Color(0xFFEA580C),
    primaryGlow: AppColors.primaryGlow,
    success: AppColors.e6,
    successLight: AppColors.e1,
    danger: AppColors.r5,
    dangerLight: AppColors.r1,
    warning: AppColors.a5,
    warningLight: AppColors.a1,
    border: AppColors.g2,
    borderActive: AppColors.o5,
    divider: AppColors.g1,
    tabActive: AppColors.e8,
    tabInactive: AppColors.g4,
    glassBorder: AppColors.g1,
    glassGradient: [Colors.white24, Colors.white10],
    navBar: Color(0xCCFFFFFF),
    navBarBorder: Color(0x80E5E7EB),
  );

  static const dark = MenudoPalette(
    background: Color(0xFF1C1C1E),
    surface: Color(0xFF2C2C2E),
    surfaceElevated: Color(0xFF3A3A3C),
    surfaceMuted: Color(0xFF183A32),
    hero: Color(0xFF0B3D32),
    heroElevated: Color(0xFF145346),
    textMain: Color(0xFFF5F5F7),
    textSecondary: Color(0xFFAEAEB2),
    textMuted: Color(0xFF8E8E93),
    textOnDark: AppColors.white,
    textOnDarkSub: Color(0xFFE5E5EA),
    primary: Color(0xFFFF9F0A),
    primaryLight: Color(0xFF3D2A14),
    primaryDark: Color(0xFFFFB340),
    primaryGlow: Color(0x40FF9F0A),
    success: Color(0xFF30D158),
    successLight: Color(0xFF13351F),
    danger: Color(0xFFFF453A),
    dangerLight: Color(0xFF3A1717),
    warning: Color(0xFFFFD60A),
    warningLight: Color(0xFF3A310C),
    border: Color(0xFF3A3A3C),
    borderActive: Color(0xFFFF9F0A),
    divider: Color(0xFF38383A),
    tabActive: Color(0xFFF5F5F7),
    tabInactive: Color(0xFF8E8E93),
    glassBorder: Color(0x40FFFFFF),
    glassGradient: [Color(0x22FFFFFF), Color(0x0FFFFFFF)],
    navBar: Color(0xBF1C1C1E),
    navBarBorder: Color(0x663A3A3C),
  );

  @override
  MenudoPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? hero,
    Color? heroElevated,
    Color? textMain,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnDark,
    Color? textOnDarkSub,
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? primaryGlow,
    Color? success,
    Color? successLight,
    Color? danger,
    Color? dangerLight,
    Color? warning,
    Color? warningLight,
    Color? border,
    Color? borderActive,
    Color? divider,
    Color? tabActive,
    Color? tabInactive,
    Color? glassBorder,
    List<Color>? glassGradient,
    Color? navBar,
    Color? navBarBorder,
  }) {
    return MenudoPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      hero: hero ?? this.hero,
      heroElevated: heroElevated ?? this.heroElevated,
      textMain: textMain ?? this.textMain,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnDark: textOnDark ?? this.textOnDark,
      textOnDarkSub: textOnDarkSub ?? this.textOnDarkSub,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryGlow: primaryGlow ?? this.primaryGlow,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      danger: danger ?? this.danger,
      dangerLight: dangerLight ?? this.dangerLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      border: border ?? this.border,
      borderActive: borderActive ?? this.borderActive,
      divider: divider ?? this.divider,
      tabActive: tabActive ?? this.tabActive,
      tabInactive: tabInactive ?? this.tabInactive,
      glassBorder: glassBorder ?? this.glassBorder,
      glassGradient: glassGradient ?? this.glassGradient,
      navBar: navBar ?? this.navBar,
      navBarBorder: navBarBorder ?? this.navBarBorder,
    );
  }

  @override
  MenudoPalette lerp(ThemeExtension<MenudoPalette>? other, double t) {
    if (other is! MenudoPalette) return this;
    return MenudoPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      hero: Color.lerp(hero, other.hero, t)!,
      heroElevated: Color.lerp(heroElevated, other.heroElevated, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnDark: Color.lerp(textOnDark, other.textOnDark, t)!,
      textOnDarkSub: Color.lerp(textOnDarkSub, other.textOnDarkSub, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerLight: Color.lerp(dangerLight, other.dangerLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderActive: Color.lerp(borderActive, other.borderActive, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      tabActive: Color.lerp(tabActive, other.tabActive, t)!,
      tabInactive: Color.lerp(tabInactive, other.tabInactive, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassGradient: [
        Color.lerp(glassGradient.first, other.glassGradient.first, t)!,
        Color.lerp(glassGradient.last, other.glassGradient.last, t)!,
      ],
      navBar: Color.lerp(navBar, other.navBar, t)!,
      navBarBorder: Color.lerp(navBarBorder, other.navBarBorder, t)!,
    );
  }
}

extension MenudoThemeColors on BuildContext {
  MenudoPalette get menudo =>
      Theme.of(this).extension<MenudoPalette>() ?? MenudoPalette.light;
}

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
  static const Color cardBg = AppColors.white;
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
