import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'data/hive_store.dart';
import 'state/goal_saver_controller.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

/// List of all Hive box names used by the application.
/// Pre-initializing them on startup prevents runtime errors.
const List<String> kRequiredHiveBoxes = [
  'goal_saver_auth',       // AuthStore: user accounts, sessions
  'goal_saver_local_store', // HiveGoalSaverStore: goals, settings, categories, etc.
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 1: Initialize Hive with Flutter's documents directory ──────
  // Using getApplicationDocumentsDirectory() ensures the database is
  // created inside the application's writable documents directory,
  // preventing read-only filesystem errors (errno 30) that occur with
  // hardcoded paths like Hive.init('goal_saver_hive').
  try {
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);
    debugPrint('[main] Hive initialized at: ${appDir.path}');
  } catch (e) {
    debugPrint('[main] Hive init failed: $e');
  }

  // ── Step 2: Open ALL required Hive boxes up front ──────────────────
  // This ensures every service (AuthService, HiveGoalSaverStore, etc.)
  // finds its box ready when called, eliminating "box not open" errors.
  for (final boxName in kRequiredHiveBoxes) {
    try {
      await Hive.openBox<dynamic>(boxName);
      debugPrint('[main] Opened Hive box: $boxName');
    } catch (e) {
      debugPrint('[main] Failed to open box "$boxName": $e');
    }
  }

  // ── Step 3: Initialize AuthService (backed by goal_saver_auth box) ─
  try {
    await AuthService().init();
    debugPrint('[main] AuthService initialized.');
  } catch (e) {
    debugPrint('[main] AuthService init error: $e');
  }

  // ── Step 4: Initialize the Hive-goals store ────────────────────────
  final hiveStore = HiveGoalSaverStore();
  try {
    await hiveStore.init();
    debugPrint('[main] HiveGoalSaverStore initialized.');
  } catch (e) {
    debugPrint('[main] HiveGoalSaverStore init error: $e');
  }

  // ── Step 5: Initialize notifications ───────────────────────────────
  await NotificationService().initialize(
    onTap: (payload) {
      if (payload != null && payload.isNotEmpty) {
        NotificationService.storePendingPayload(payload);
      }
    },
  );
  
  try {
    await NotificationService().requestPermissions();
  } catch (e) {
    debugPrint('[main] Notification permission error: $e');
  }

  // ── Step 6: Create controller backed by Hive store ─────────────────
  // IMPORTANT: The controller is created directly with the Hive store.
  // We DO NOT use switchStore() with a MemoryGoalSaverStore first, because
  // that would write the empty in-memory state to Hive, overwriting any
  // existing user data at global (unprefixed) keys.
  //
  // Data is loaded eagerly on app startup via _checkLogin() in GoalSaverApp.
  // For existing users, loadUserData() is called which sets the user context
  // and loads all data from Hive under user-scoped keys.
  // For new users, no data is loaded until they sign up.
  final controller = GoalSaverController(hiveStore);

  // ── Step 7: Perform initial auth check and load data ───────────────
  // If there's an active session, load user data so the dashboard is ready
  // immediately when the app renders.
  try {
    final authService = AuthService();
    final loggedIn = await authService.isLoggedIn();
    if (loggedIn) {
      final userId = await authService.getCurrentUserId();
      if (userId != null && userId.isNotEmpty) {
        await controller.loadUserData(userId);
        debugPrint('[main] Auto-loaded data for user $userId: ${controller.allActiveGoals.length} goals, ${controller.history.length} history entries');
      }
    }
  } catch (e) {
    debugPrint('[main] Auto-login data load failed (will retry in app): $e');
  }

  runApp(GoalSaverApp(controller: controller));
}