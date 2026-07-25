import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journal_trend_analysis/core/theme/app_theme.dart';
import 'package:journal_trend_analysis/core/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  group('AppTheme Tests', () {
    test('darkTheme has dark brightness and custom primary color', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, AppColors.background);
      expect(darkTheme.colorScheme.primary, AppColors.primary);
    });

    test('lightTheme has light brightness and custom primary color', () {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, AppColors.backgroundLight);
      expect(lightTheme.colorScheme.primary, AppColors.primaryLight);
    });
  });
}
