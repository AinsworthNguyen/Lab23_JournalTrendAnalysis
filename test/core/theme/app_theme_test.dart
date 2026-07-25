import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journal_trend_analysis/core/theme/app_theme.dart';
import 'package:journal_trend_analysis/core/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppTheme Tests', () {
    testWidgets('darkTheme has dark brightness and custom primary color', (
      tester,
    ) async {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, AppColors.background);
      expect(darkTheme.colorScheme.primary, AppColors.primary);
    });

    testWidgets('lightTheme has light brightness and custom primary color', (
      tester,
    ) async {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, AppColors.backgroundLight);
      expect(lightTheme.colorScheme.primary, AppColors.primaryLight);
    });
  });
}
