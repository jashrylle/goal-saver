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

  // Light mode
  static const Color lightInk = Color(0xFFF5FAF1);
  static const Color lightPanel = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF15201C);
  static const Color lightMuted = Color(0xFF999999);

  // Semantic
  static const Color success = lime;
  static const Color warning = Color(0xFFFFD93D);
  static const Color error = Color(0xFFFF6B6B);

  // Dark background gradient
  static const List<Color> darkBgGradient = [
    Color(0xFF07100E),
    Color(0xFF0F1F1B),
    Color(0xFF0A1714),
  ];

  // Light background gradient
  static const List<Color> lightBgGradient = [
    Color(0xFFF0FAF4),
    Color(0xFFE8F5ED),
    Color(0xFFF5FAF1),
  ];
}
