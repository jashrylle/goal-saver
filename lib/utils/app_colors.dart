import 'package:flutter/material.dart';

/// Central color palette for Goal Saver
class AppColors {
  // Core brand
  static const Color ink = Color(0xFF07100E);
  static const Color panel = Color(0xFF111A1D);
  static const Color lime = Color(0xFFA8FF3E);
  static const Color white = Color(0xFFF3F7F1);
  static const Color muted = Color(0xFF98A49D);
  static const Color glass = Color(0x551B292C);

  // Light mode — softened palette for reduced eye strain
  // Soft off-white/warm-gray surfaces replace pure white
  static const Color lightInk = Color(0xFFF0F5EE);
  static const Color lightPanel = Color(0xFFFCFDFA);
  static const Color lightText = Color(0xFF1C2E28);
  static const Color lightMuted = Color(0xFF8A9B94);
  static const Color lightCardBg = Color(0xFFFFFEFC);
  static const Color lightSurface = Color(0xFFF5F9F5);
  static const Color lightBorder = Color(0xFFDDE6E0);
  static const Color lightSubtle = Color(0xFFB8C9C1);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);

  // Dark background gradient
  static const List<Color> darkBgGradient = [
    Color(0xFF07100E),
    Color(0xFF0F1F1B),
    Color(0xFF0A1714),
  ];

  // Light background gradient — softer, warmer tones
  static const List<Color> lightBgGradient = [
    Color(0xFFF0F5EE),
    Color(0xFFEAF2EA),
    Color(0xFFF0F5EE),
  ];
}
