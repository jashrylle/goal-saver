import 'dart:ui' show Color;
import '../models/goal_model.dart';
import '../models/achievement_model.dart';
import '../models/savings_plan_model.dart' show PlayerLevel;

/// Abstract persistence interface for ALL Goal Saver data.
///
/// Every read/write operation goes through this interface so the app can
/// swap between Hive (production) and MemoryStore (testing) transparently.
abstract class GoalSaverStore {
  // ── User Context ───────────────────────────────────────────────────────────

  /// Set the current user ID for user-scoped data isolation.
  /// When set, all subsequent load/save operations use `{userId}_` prefixed keys.
  /// Set to `null` for shared/global keys (only used for initial state).
  void setUserId(String? userId);

  // ── Goals & History ────────────────────────────────────────────────────────

  Future<List<SavingsGoal>> loadGoals();
  Future<void> saveGoals(List<SavingsGoal> goals);
  Future<List<SavingsLog>> loadHistory();
  Future<void> saveHistory(List<SavingsLog> history);

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<List<GoalCategory>> loadCustomCategories();
  Future<void> saveCustomCategories(List<GoalCategory> categories);
  Future<Set<String>> loadUnlockedPredefinedCategories();
  Future<void> saveUnlockedPredefinedCategories(Set<String> unlocked);

  // ── Settings ───────────────────────────────────────────────────────────────

  Future<bool> loadIsDarkMode();
  Future<void> saveIsDarkMode(bool value);
  Future<bool> loadRemindersEnabled();
  Future<void> saveRemindersEnabled(bool value);
  Future<int> loadReminderHour();
  Future<void> saveReminderHour(int hour);
  Future<int> loadReminderMinute();
  Future<void> saveReminderMinute(int minute);
  Future<bool> loadShowBalance();
  Future<void> saveShowBalance(bool value);
  Future<bool> loadAnimationsEnabled();
  Future<void> saveAnimationsEnabled(bool value);
  Future<String> loadCurrencyCode();
  Future<void> saveCurrencyCode(String code);
  Future<String> loadAnalyticsDisplay();
  Future<void> saveAnalyticsDisplay(String value);
  Future<Color> loadAccentColor();
  Future<void> saveAccentColor(Color color);

  // ── User Profile ───────────────────────────────────────────────────────────

  Future<String> loadUserName();
  Future<void> saveUserName(String name);
  Future<String> loadUserEmail();
  Future<void> saveUserEmail(String email);
  Future<String?> loadUserPhotoUrl();
  Future<void> saveUserPhotoUrl(String? url);

  // ── Notes ──────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> loadNotes();
  Future<void> saveNotes(List<Map<String, dynamic>> notes);

  // ── Calendar Events ────────────────────────────────────────────────────────

  Future<List<CalendarEvent>> loadCalendarEvents();
  Future<void> saveCalendarEvents(List<CalendarEvent> events);

  // ── Achievements & Gamification ────────────────────────────────────────────

  Future<List<AchievementBadge>> loadAchievementBadges();
  Future<void> saveAchievementBadges(List<AchievementBadge> badges);
  Future<Set<String>> loadCelebratedMilestones();
  Future<void> saveCelebratedMilestones(Set<String> milestones);
  Future<PlayerLevel> loadPlayerLevel();
  Future<void> savePlayerLevel(PlayerLevel level);

  // ── Dashboard Layout ───────────────────────────────────────────────────────

  Future<List<String>> loadCardOrder();
  Future<void> saveCardOrder(List<String> order);
  Future<List<String>> loadHiddenCards();
  Future<void> saveHiddenCards(List<String> hidden);

  // ── Reset ──────────────────────────────────────────────────────────────────

  /// Delete ALL data from the store, returning to factory-fresh state.
  Future<void> clearAll();
}
