import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF3568FF);
  static const Color accent = Color(0xFFFF7A59);
  static const Color surface = Color(0xFFF5F7FB);
  static const Color textPrimary = Color(0xFF1F2430);
  static const Color success = Color(0xFF3CC48D);
  static const Color warning = Color(0xFFFFB34D);
  static const Color info = Color(0xFF566CFF);
  static const Color danger = Color(0xFFE57373);
}

Color fadeColor(Color color, double alpha) {
  final normalized = alpha.clamp(0.0, 1.0);
  return color.withAlpha((normalized * 255).round());
}

Color darkenColor(Color color, [double amount = 0.2]) {
  final hsl = HSLColor.fromColor(color);
  final adjusted = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return adjusted.toColor();
}
