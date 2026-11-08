import 'package:flutter/material.dart';

import '../constants/color_constants.dart';

class ThemeHelper {
  ThemeHelper(this.context);

  final BuildContext context;

  static ThemeHelper of(BuildContext context) => ThemeHelper(context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get background => pageBackground;
  Color get surface => cardBackground;
  Color get cardBackground => isDark ? const Color(0xFF1F2937) : Colors.white;
  Color get inputFill => isDark ? const Color(0xFF111827) : Colors.white;
  Color get subtleBackground =>
      isDark ? const Color(0xFF172033) : AppColors.surfaceLight;
  Color get tintBackground =>
      isDark ? const Color(0xFF263247) : AppColors.cardTint;
  Color get borderColor => isDark ? Colors.white10 : const Color(0xFFE5E7EB);
  Color get borderLight => borderColor;
  Color get glassBackground =>
      isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white24;
  Color get pageBackground => Theme.of(context).scaffoldBackgroundColor;
  Color get textPrimary => isDark ? Colors.white : AppColors.textPrimary;
  Color get textSecondary =>
      isDark ? const Color(0xFFD1D5DB) : AppColors.textSecondary;
  Color get textHint =>
      isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary;
  Color get textDisabled =>
      isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
  Color get shadowLight => Colors.black.withValues(alpha: isDark ? 0.28 : 0.08);
  Color get shadowMedium =>
      Colors.black.withValues(alpha: isDark ? 0.42 : 0.16);
}
