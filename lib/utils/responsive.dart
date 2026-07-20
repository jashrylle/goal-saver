import 'package:flutter/material.dart';

/// Responsive design metrics and breakpoints
class ResponsiveMetrics {
  const ResponsiveMetrics({
    required this.pagePadding,
    required this.heroFont,
    required this.titleFont,
    required this.bodyFont,
    required this.cardRadius,
    required this.isTablet,
    required this.isLandscape,
  });

  final double pagePadding;
  final double heroFont;
  final double titleFont;
  final double bodyFont;
  final double cardRadius;
  final bool isTablet;
  final bool isLandscape;

  /// Get metrics based on device screen size and orientation
  static ResponsiveMetrics of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final width = size.width;
    final isLandscape =
        mediaQuery.orientation == Orientation.landscape;
    final isTablet = width >= 600;
    final scale = mediaQuery.textScaler.scale(1);

    return ResponsiveMetrics(
      pagePadding: width < 360
          ? 16
          : width > 700
          ? 32
          : 20,
      heroFont: _scaledFont(width < 360 ? 33 : 40, scale, 1.25),
      titleFont: _scaledFont(width < 360 ? 21 : 24, scale, 1.2),
      bodyFont: _scaledFont(width < 360 ? 13 : 14, scale, 1.15),
      cardRadius: width < 360 ? 16 : 20,
      isTablet: isTablet,
      isLandscape: isLandscape,
    );
  }

  static double _scaledFont(double base, double scale, double maxScale) {
    return base / scale.clamp(1, maxScale);
  }

  /// Get padding based on screen size
  static EdgeInsets pagePaddingInsets(BuildContext context) {
    final metrics = of(context);
    return EdgeInsets.symmetric(horizontal: metrics.pagePadding);
  }

  /// Get columns for grid layouts
  static int getGridColumns(BuildContext context, double maxWidth) {
    final width = MediaQuery.of(context).size.width;
    return (width / maxWidth).floor().clamp(1, 4);
  }

  /// Determine if showing compact layout
  static bool isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Get safe area padding with keyboard
  static EdgeInsets keyboardSafeArea(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom);
  }
}

/// Screen size breakpoints
class ScreenBreakpoints {
  static const double mobile = 360;
  static const double tablet = 600;
  static const double desktop = 1200;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= tablet && width < desktop;
  static bool isDesktop(double width) => width >= desktop;

  /// Get max content width for different screen sizes
  static double maxContentWidth(double screenWidth) {
    if (isDesktop(screenWidth)) return 1200;
    if (isTablet(screenWidth)) return screenWidth * 0.9;
    return screenWidth;
  }
}

/// Safe area helper
class SafeAreaMetrics {
  final EdgeInsets padding;
  final EdgeInsets viewInsets;
  final bool hasNotch;

  SafeAreaMetrics({
    required this.padding,
    required this.viewInsets,
    this.hasNotch = false,
  });

  factory SafeAreaMetrics.of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return SafeAreaMetrics(
      padding: mediaQuery.padding,
      viewInsets: mediaQuery.viewInsets,
      hasNotch: mediaQuery.padding.top > 24,
    );
  }

  double get topPadding => padding.top;
  double get bottomPadding => padding.bottom + viewInsets.bottom;
  double get keyboardHeight => viewInsets.bottom;
  bool get isKeyboardOpen => keyboardHeight > 0;
}

/// Animation duration helper
class AnimationDurations {
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration faster = Duration(milliseconds: 200);
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration slower = Duration(milliseconds: 800);
  static const Duration slowest = Duration(milliseconds: 1200);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve quickCurve = Curves.easeOutQuad;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve bouncyCurve = Curves.easeOutBack;
}

/// Spacing constants
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double huge = 32;

  // Common combinations
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
}

/// Screen size helper widget
class ScreenSizeBuilder extends StatelessWidget {
  final Widget Function(BuildContext, ScreenSize) builder;

  const ScreenSizeBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final size = switch (width) {
      < 360 => ScreenSize.compact,
      < 600 => ScreenSize.small,
      < 1200 => ScreenSize.tablet,
      _ => ScreenSize.desktop,
    };
    return builder(context, size);
  }
}

/// Screen size enum
enum ScreenSize {
  compact,
  small,
  tablet,
  desktop,
}

/// Orientation helper
class OrientationBuilder extends StatelessWidget {
  final Widget Function(BuildContext, Orientation) builder;

  const OrientationBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, MediaQuery.of(context).orientation);
  }
}
