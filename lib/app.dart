import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/memory_store.dart';
import 'state/goal_saver_controller.dart';
import 'utils/app_colors.dart';
import 'screens/shell/goal_saver_shell.dart';

/// Root application widget.
///
/// Accepts an optional [controller] so that [main] can inject the
/// pre-created controller (backed by [MemoryGoalSaverStore] initially).
/// When no controller is supplied one is created internally.
class GoalSaverApp extends StatelessWidget {
  const GoalSaverApp({
    super.key,
    this.controller,
    this.showOnboarding = true,
  });

  final GoalSaverController? controller;
  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    final effectiveController =
        controller ?? (GoalSaverController(MemoryGoalSaverStore())..load());

    return ChangeNotifierProvider<GoalSaverController>.value(
      value: effectiveController,
      child: Consumer<GoalSaverController>(
        builder: (context, ctrl, _) {
          final brightness =
              ctrl.isDarkMode ? Brightness.dark : Brightness.light;
          return MaterialApp(
            title: 'Goal Saver',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: brightness,
              scaffoldBackgroundColor:
                  ctrl.isDarkMode ? AppColors.ink : AppColors.lightInk,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.lime,
                brightness: brightness,
                surface: ctrl.isDarkMode
                    ? AppColors.panel
                    : AppColors.lightPanel,
              ),
              fontFamily: 'Arial',
              textTheme: ThemeData(brightness: brightness).textTheme.apply(
                    bodyColor: ctrl.isDarkMode
                        ? AppColors.white
                        : AppColors.lightText,
                    displayColor: ctrl.isDarkMode
                        ? AppColors.white
                        : AppColors.lightText,
                  ),
            ),
            home: GoalSaverShell(showOnboarding: showOnboarding),
          );
        },
      ),
    );
  }
}
