import 'package:flutter/material.dart';

import '../constants/color_constants.dart';

class ThemeHelper {
  ThemeHelper(this.context);

  final BuildContext context;

  static ThemeHelper of(BuildContext context) => ThemeHelper(context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get cardBackground => isDark ? const Color(0xFF1F2937) : Colors.white;
  Color get pageBackground => Theme.of(context).scaffoldBackgroundColor;
  Color get textPrimary => isDark ? Colors.white : AppColors.textPrimary;
  Color get textSecondary =>
      isDark ? const Color(0xFFD1D5DB) : AppColors.textSecondary;
}
