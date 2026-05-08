import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E40AF);

  // Secondary Colors
  static const Color secondaryColor = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color secondaryDark = Color(0xFF5B21B6);

  // Accent Colors
  static const Color accentColor = Color(0xFF06B6D4);
  static const Color accentLight = Color(0xFF22D3EE);
  static const Color accentDark = Color(0xFF0891B2);

  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);

  // Neutral Colors - Light Theme
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF9FAFB);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF3F4F6);
  static const Color greyExtraLight = Color(0xFFF3F4F6);
  static const Color greyLight = Color(0xFFE5E7EB);
  static const Color greyMedium = Color(0xFFD1D5DB);
  static const Color greyDark = Color(0xFF4B5563);
  static const Color shadowLight = Color(0x1F000000);
  static const Color dividerLight = Color(0xFFE5E7EB);

  // Neutral Colors - Dark Theme
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextHint = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF475569);
  static const Color darkDivider = Color(0xFF334155);
  static const Color darkInputBackground = Color(0xFF1E293B);
  static const Color shadowDark = Color(0x3F000000);

  // Status Badges
  static const Color statusActive = Color(0xFF10B981);
  static const Color statusInactive = Color(0xFF6B7280);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusError = Color(0xFFEF4444);
}

class AppTextStyles {
  // Display Styles
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
    letterSpacing: -0.2,
  );

  static const TextStyle headline4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle headline5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle headline6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.15,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.1,
  );

  // Button Styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.1,
  );
}

class AppDesign {
  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 24.0;
  static const double space2XL = 32.0;
  static const double space3XL = 48.0;

  // Border Radius
  static const double radiusSM = 4.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;
  static const double radius2XL = 24.0;
  static const double radius3XL = 32.0;

  // Icon Sizes
  static const double iconSM = 16.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // Button Heights
  static const double buttonHeightSM = 36.0;
  static const double buttonHeightMD = 48.0;
  static const double buttonHeightLG = 56.0;

  // Shadow
  static const shadowSM = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 2,
    spreadRadius: 0,
    offset: Offset(0, 1),
  );

  static const shadowMD = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 6,
    spreadRadius: 0,
    offset: Offset(0, 2),
  );

  static const shadowLG = BoxShadow(
    color: Color(0x3F000000),
    blurRadius: 12,
    spreadRadius: 0,
    offset: Offset(0, 4),
  );
}
