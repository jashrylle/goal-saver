import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Full-screen animated dark gradient background used on all screens.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.2, -0.6),
          end: Alignment(0.1, 0.35),
          colors: AppColors.darkBgGradient,
        ),
      ),
    );
  }
}
