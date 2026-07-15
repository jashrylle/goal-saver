import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Full-screen gradient background used on all screens.
/// Automatically switches between dark and light mode gradients.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.2, -0.6),
          end: const Alignment(0.1, 0.35),
          colors: isDark
              ? AppColors.darkBgGradient
              : AppColors.lightBgGradient,
        ),
      ),
    );
  }
}
