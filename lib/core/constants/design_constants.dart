import 'package:flutter/material.dart';

import 'app_font_weights.dart';

class AppDesign {
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 12;
  static const double spaceLG = 16;
  static const double spaceXL = 24;
  static const double space2XL = 32;
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 18;

  static List<BoxShadow> shadowSM = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLG = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.14),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}

class AppTextStyles {
  static const headline1 = TextStyle(
    fontSize: 34,
    fontWeight: AppFontWeights.extraBold,
  );
  static const headline2 = TextStyle(
    fontSize: 26,
    fontWeight: AppFontWeights.extraBold,
  );
  static const headline3 = TextStyle(
    fontSize: 22,
    fontWeight: AppFontWeights.bold,
  );
  static const title = TextStyle(fontSize: 18, fontWeight: AppFontWeights.bold);
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: AppFontWeights.medium,
  );
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: AppFontWeights.medium,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: AppFontWeights.medium,
  );
}
