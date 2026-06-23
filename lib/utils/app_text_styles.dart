import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized text styles for Goal Saver
class AppText {
  static const TextStyle hero = TextStyle(
    color: AppColors.white,
    fontSize: 40,
    fontWeight: FontWeight.w900,
    height: 1.04,
    letterSpacing: 0,
  );

  static const TextStyle titleLarge = TextStyle(
    color: AppColors.white,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const TextStyle section = TextStyle(
    color: AppColors.white,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle title = TextStyle(
    color: AppColors.white,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle bodyMuted = TextStyle(
    color: AppColors.muted,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.muted,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle action = TextStyle(
    color: AppColors.white,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle limeLabel = TextStyle(
    color: AppColors.lime,
    fontSize: 13,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  // Light mode variants
  static final TextStyle lightHero = hero.copyWith(color: AppColors.lightText);
  static final TextStyle lightTitle = title.copyWith(color: AppColors.lightText);
  static final TextStyle lightBody = body.copyWith(color: AppColors.lightText);
  static final TextStyle lightCaption = caption.copyWith(color: AppColors.lightMuted);
  static final TextStyle lightBodyMuted = bodyMuted.copyWith(color: AppColors.lightMuted);
}
