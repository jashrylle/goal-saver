import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized text styles for Goal Saver.
/// For color-adaptive styles (dark/light mode), use [AppText.adaptive].
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

  /// Alias for [title] — used across screens as titleMedium.
  static const TextStyle titleMedium = TextStyle(
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

  // ─── Theme-adaptive helpers ───────────────────────────────────────────────

  /// Returns a text color adapted to the current brightness.
  static Color adaptiveTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.white
        : AppColors.lightText;
  }

  /// Returns a muted text color adapted to the current brightness.
  static Color adaptiveMutedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.muted
        : AppColors.lightMuted;
  }

  /// Returns [base] style with the text color adapted to the current theme.
  static TextStyle adaptive(BuildContext context, TextStyle base) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLightColored = base.color == AppColors.white;
    final isMutedColored = base.color == AppColors.muted;
    if (isDark) return base;
    if (isLightColored) return base.copyWith(color: AppColors.lightText);
    if (isMutedColored) return base.copyWith(color: AppColors.lightMuted);
    return base;
  }
  
  /// Returns a theme-aware text style based on the base style and context.
  /// This is a convenience method that applies adaptive coloring.
  static TextStyle of(BuildContext context, TextStyle style) {
    return adaptive(context, style);
  }
}