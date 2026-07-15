import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/memory_store.dart';
import 'models/user_model.dart';
import 'state/goal_saver_controller.dart';
import 'utils/app_colors.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/goal_saver_shell.dart';

/// Root application widget.
/// Uses a StatefulWidget to query login state once at startup, preventing
/// rebuilds of MaterialApp/FutureBuilder from resetting the tab index to the home tab.
class GoalSaverApp extends StatefulWidget {
  const GoalSaverApp({
    super.key,
    this.controller,
    this.showOnboarding = true,
  });

  final GoalSaverController? controller;
  final bool showOnboarding;

  @override
  State<GoalSaverApp> createState() => _GoalSaverAppState();
}

class _GoalSaverAppState extends State<GoalSaverApp> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      final loggedIn = await AuthService().isLoggedIn();
      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveController =
        widget.controller ?? (GoalSaverController(MemoryGoalSaverStore())..load());

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
            home: _buildHome(ctrl),
          );
        },
      ),
    );
  }

  Widget _buildHome(GoalSaverController ctrl) {
    if (_isLoggedIn == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.lime),
        ),
      );
    }
    if (_isLoggedIn == true) {
      return GoalSaverShell(showOnboarding: widget.showOnboarding);
    } else {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {
            _isLoggedIn = true;
          });
        },
      );
    }
  }
}