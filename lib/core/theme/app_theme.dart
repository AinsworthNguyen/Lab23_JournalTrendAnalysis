import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextStyle _outfit({
    required final double fontSize,
    required final FontWeight fontWeight,
    required final Color color,
    final double? height,
    final double? letterSpacing,
  }) {
    final TextStyle base = TextStyle(
      fontFamily: 'Outfit',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
    try {
      return GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    } on Exception catch (_) {
      return base;
    }
  }

  static TextStyle _inter({
    required final double fontSize,
    required final FontWeight fontWeight,
    required final Color color,
    final double? height,
    final double? letterSpacing,
  }) {
    final TextStyle base = TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
    try {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    } on Exception catch (_) {
      return base;
    }
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.highlight,
        onSurface: AppColors.textMain,
        onPrimary: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: _outfit(
          fontSize: 32.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
          letterSpacing: -1.0,
        ),
        displayMedium: _outfit(
          fontSize: 28.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
          letterSpacing: -0.8,
          height: 1.2,
        ),
        displaySmall: _outfit(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
          letterSpacing: -0.5,
        ),
        headlineMedium: _outfit(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
          height: 1.3,
        ),
        titleMedium: _outfit(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
          height: 1.4,
        ),
        bodyLarge: _inter(
          fontSize: 15.0,
          fontWeight: FontWeight.w400,
          color: AppColors.textMain,
          height: 1.6,
        ),
        bodyMedium: _inter(
          fontSize: 12.0,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMain),
        titleTextStyle: _outfit(
          color: AppColors.textMain,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12.0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        surface: AppColors.surfaceLight,
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        error: AppColors.highlightLight,
        onSurface: AppColors.textMainLight,
        onPrimary: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: _outfit(
          fontSize: 32.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textMainLight,
        ),
        displayMedium: _outfit(
          fontSize: 28.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textMainLight,
          height: 1.2,
        ),
        displaySmall: _outfit(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textMainLight,
        ),
        headlineMedium: _outfit(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textMainLight,
          height: 1.3,
        ),
        titleMedium: _outfit(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textMainLight,
          height: 1.4,
        ),
        bodyLarge: _inter(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          color: AppColors.textMainLight,
          height: 1.5,
        ),
        bodyMedium: _inter(
          fontSize: 12.0,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryLight,
          height: 1.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(
            color: AppColors.borderLight.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMainLight),
        titleTextStyle: _outfit(
          color: AppColors.textMainLight,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textSecondaryLight,
        selectedLabelStyle: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12.0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
