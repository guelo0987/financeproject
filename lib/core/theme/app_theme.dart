import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: MenudoColors.appBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MenudoColors.cardBg, // Emerald 800
          primary: MenudoColors.primary,
          secondary: MenudoColors.success,
          surface: MenudoColors.appBg,
          error: MenudoColors.danger,
        ),
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: MenudoColors.tabActive,
          unselectedItemColor: MenudoColors.tabInactive,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: MenudoColors.divider,
          thickness: 1,
          space: 0,
        ),
        splashColor: MenudoColors.primary.withValues(alpha: 0.1),
        highlightColor: MenudoColors.primary.withValues(alpha: 0.05),
      );
}
