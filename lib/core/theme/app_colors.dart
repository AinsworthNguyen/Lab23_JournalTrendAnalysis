import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Premium Slate Dark Color Palette
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF1E293B);
  static const Color primary = Color(0xFF6366F1); // Indigo Violet
  static const Color secondary = Color(0xFF10B981); // Emerald Green
  static const Color highlight = Color(0xFFF43F5E); // Rose Accent
  
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color border = Color(0xFF334155);

  // Light Theme Equivalents for Accessibility/Toggle support
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color primaryLight = Color(0xFF4F46E5);
  static const Color secondaryLight = Color(0xFF059669);
  static const Color highlightLight = Color(0xFFE11D48);
  
  static const Color textMainLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Glow / Gradients Accents
  static const Color glowIndigo = Color(0x336366F1); // 20% opacity primary
  static const Color glowEmerald = Color(0x3310B981);
  static const Color glowRose = Color(0x33F43F5E);
}
