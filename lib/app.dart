import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/memory_store.dart';
import 'services/auth_service.dart';
import 'state/goal_saver_controller.dart';
import 'utils/app_colors.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/goal_saver_shell.dart';

/// Root application widget.
///
/// Authentication flow:
/// 1. On startup, checks if there's an active user session.
/// 2. If active session exists → auto-navigate to Home Dashboard.
/// 3. If no active session → show Sign In / Sign Up page.
/// 4. After successful login/signup, navigates to Home Dashboard.
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

  /// Check authentication state on startup.
  /// If an active session exists, auto-navigate to Home Dashboard.
  /// Also loads the user's scoped data from Hive when auto-login succeeds.
  /// Skips loading if the controller already has data (e.g. pre-loaded in main.dart).
  Future<void> _checkLogin() async {
    try {
      final authService = AuthService();
      await authService.init();
      final loggedIn = await authService.isLoggedIn();

      if (loggedIn && mounted) {
        // Get the current user ID and load user-specific data
        final userId = await authService.getCurrentUserId();
        if (userId != null && widget.controller != null) {
          // Only load if data isn't already populated (e.g. from main.dart pre-load)
          if (widget.controller!.allActiveGoals.isEmpty) {
            try {
              await widget.controller!.loadUserData(userId);
            } catch (e) {
              debugPrint('Failed to load user data on startup: $e');
            }
          } else {
            // Ensure userId context is set even if data was pre-loaded
            widget.controller!.store.setUserId(userId);
            debugPrint('[App] Data already loaded, skipping redundant load.');
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('══════════════════════════════════════════════');
      debugPrint('_checkLogin ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');
      debugPrint('══════════════════════════════════════════════');
      if (mounted) {
        // Make sure loading is false so the app doesn't show a spinner
        // when the login screen appears
        widget.controller?.isLoading = false;
        setState(() {
          _isLoggedIn = false;
        });
      }
    }
  }

  /// Called when the user explicitly logs out from the settings screen.
  /// Updates the auth state so the login screen is displayed.
  /// The navigation stack is fully cleared because the MaterialApp key
  /// changes, causing a complete widget tree rebuild.
  void onLogout() {
    if (widget.controller != null) {
      widget.controller!.isLoading = false;
    }
    setState(() {
      _isLoggedIn = false;
    });
  }

  /// Called on successful sign-in/sign-up to navigate to the dashboard.
  ///
  /// The login_screen already calls loadUserData() or initializeNewUser()
  /// to set the userId context and load data into the controller. This
  /// callback just transitions the auth state to show the dashboard.
  ///
  /// If the controller somehow has no data yet (defensive fallback), load
  /// as a safety net so the dashboard always shows the current user's data.
  Future<void> onLoginSuccess() async {
    if (widget.controller != null && mounted) {
      // Only re-load if data wasn't already loaded by login_screen
      if (widget.controller!.allActiveGoals.isEmpty &&
          widget.controller!.userName == 'User') {
        try {
          await widget.controller!.load();
        } catch (e) {
          debugPrint('[App] onLoginSuccess: controller.load() failed — $e');
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveController =
        widget.controller ?? GoalSaverController(MemoryGoalSaverStore());

    return ChangeNotifierProvider<GoalSaverController>.value(
      value: effectiveController,
      child: Consumer<GoalSaverController>(
        builder: (context, ctrl, _) {
          final brightness =
              ctrl.isDarkMode ? Brightness.dark : Brightness.light;
          final seedColor = ctrl.accentColor;
          return MaterialApp(
            key: ValueKey('app_$_isLoggedIn'),
            title: 'Goal Saver',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: brightness,
              scaffoldBackgroundColor:
                  ctrl.isDarkMode ? AppColors.ink : AppColors.lightInk,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
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
    // Show loading spinner while checking auth
    if (_isLoggedIn == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.lime),
        ),
      );
    }

    // Active session exists → go to dashboard
    if (_isLoggedIn == true) {
      return GoalSaverShell(
        showOnboarding: widget.showOnboarding,
        onLogout: onLogout,
      );
    }

    // No active session → show login screen
    return LoginScreen(
      onLoginSuccess: onLoginSuccess,
    );
  }
}
