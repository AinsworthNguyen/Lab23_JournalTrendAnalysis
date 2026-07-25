import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/core/theme/app_colors.dart';

void main() {
  testWidgets('Core theme colors definition check', (
    WidgetTester tester,
  ) async {
    // Verifies theme colors match design tokens defined in design.md
    expect(AppColors.primary, const Color(0xFF6366F1));
    expect(AppColors.background, const Color(0xFF0B0F19));
    expect(AppColors.surface, const Color(0xFF1E293B));
  });
}
