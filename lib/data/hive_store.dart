import 'dart:convert';
import 'dart:ui' show Color;
import 'package:hive/hive.dart';
import '../models/goal_model.dart';
import '../models/achievement_model.dart';
import '../models/savings_plan_model.dart' show PlayerLevel;
import 'goal_saver_store.dart';

/// Hive-backed persistent store for ALL Goal Saver data.
///
/// Everything lives in a single Hive box named 'goal_saver_local_store';
/// each data type is stored under its own key prefix to avoid collisions.
///
/// Unlike the previous version which only handled goals+history, this store
/// manages every feature: categories, settings, notes, calendar events,
/// achievements, player level, dashboard layout, and user profile.
class HiveGoalSaverStore implements GoalSaverStore {
  late final Box<dynamic> _box;
  String? _userId;

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>('goal_saver_local_store');
  }

  @override
  void setUserId(String? userId) {
    _userId = userId;
  }

  // ── User-scoped key helpers ───────────────────────────────────────────────

  /// Returns a user-scoped key when a user is logged in, otherwise the base key.
  /// This ensures each user's data is isolated under `{userId}_keyName`.
  String _k(String baseKey) {
    if (_userId != null && _userId!.isNotEmpty) {
      return '${_userId}_$baseKey';
    }
    return baseKey;
  }

  static const _kGoals = 'goals';
  static const _kHistory = 'history';
  static const _kCustomCategories = 'custom_categories';
  static const _kUnlockedPredefined = 'unlocked_predefined';
  static const _kIsDarkMode = 'is_dark_mode';
  static const _kRemindersEnabled = 'reminders_enabled';
  static const _kReminderHour = 'reminder_hour';
  static const _kReminderMinute = 'reminder_minute';
  static const _kShowBalance = 'show_balance';
  static const _kAnimationsEnabled = 'animations_enabled';
  static const _kCurrencyCode = 'currency_code';
  static const _kAnalyticsDisplay = 'analytics_display';
  static const _kAccentColor = 'accent_color';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';
  static const _kUserPhotoUrl = 'user_photo_url';
  static const _kNotes = 'user_notes_list';
  static const _kCalendarEvents = 'calendar_events';
  static const _kAchievementBadges = 'achievement_badges';
  static const _kCelebratedMilestones = 'celebrated_milestones';
  static const _kPlayerLevel = 'player_level';
  static const _kCardOrder = 'card_order';
  static const _kHiddenCards = 'hidden_cards';

  // ── Generic helpers ──────────────────────────────────────────────────────

  List<Map<String, dynamic>> _decodeList(String baseKey) {
    final key = _k(baseKey);
    final raw = _box.get(key);
    if (raw is! List) return [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> _encodeList(String baseKey, List<Map<String, dynamic>> data) async {
    await _box.put(_k(baseKey), data);
  }

  String? _getString(String baseKey) => _box.get(_k(baseKey)) as String?;
  Future<void> _putString(String baseKey, String? value) async {
    final key = _k(baseKey);
    if (value != null) {
      await _box.put(key, value);
    } else {
      await _box.delete(key);
    }
  }

  int _getInt(String baseKey, {int defaultValue = 0}) =>
      (_box.get(_k(baseKey)) as int?) ?? defaultValue;
  Future<void> _putInt(String baseKey, int value) async {
    await _box.put(_k(baseKey), value);
  }

  bool _getBool(String baseKey, {bool defaultValue = false}) =>
      (_box.get(_k(baseKey)) as bool?) ?? defaultValue;
  Future<void> _putBool(String baseKey, bool value) async {
    await _box.put(_k(baseKey), value);
  }

  List<String> _getStringList(String baseKey) {
    final raw = _box.get(_k(baseKey));
    if (raw is! List) return [];
    return raw.whereType<String>().toList();
  }

  Future<void> _putStringList(String baseKey, List<String> value) async {
    await _box.put(_k(baseKey), value);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Goals & History
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<SavingsGoal>> loadGoals() async {
    return _decodeList(_kGoals)
        .map((m) => SavingsGoal.fromMap(m))
        .toList();
  }

  @override
  Future<void> saveGoals(List<SavingsGoal> goals) async {
    await _encodeList(_kGoals, goals.map((g) => g.toMap()).toList());
  }

  @override
  Future<List<SavingsLog>> loadHistory() async {
    return _decodeList(_kHistory)
        .map((m) => SavingsLog.fromMap(m))
        .toList();
  }

  @override
  Future<void> saveHistory(List<SavingsLog> history) async {
    await _encodeList(_kHistory, history.map((h) => h.toMap()).toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Categories
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<GoalCategory>> loadCustomCategories() async {
    return _decodeList(_kCustomCategories)
        .map((m) => GoalCategory.fromMap(m))
        .toList();
  }

  @override
  Future<void> saveCustomCategories(List<GoalCategory> categories) async {
    await _encodeList(_kCustomCategories, categories.map((c) => c.toMap()).toList());
  }

  @override
  Future<Set<String>> loadUnlockedPredefinedCategories() async {
    return _getStringList(_kUnlockedPredefined).toSet();
  }

  @override
  Future<void> saveUnlockedPredefinedCategories(Set<String> unlocked) async {
    await _putStringList(_kUnlockedPredefined, unlocked.toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Settings
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<bool> loadIsDarkMode() async => _getBool(_kIsDarkMode, defaultValue: true);

  @override
  Future<void> saveIsDarkMode(bool value) async {
    await _putBool(_kIsDarkMode, value);
  }

  @override
  Future<bool> loadRemindersEnabled() async => _getBool(_kRemindersEnabled, defaultValue: true);

  @override
  Future<void> saveRemindersEnabled(bool value) async {
    await _putBool(_kRemindersEnabled, value);
  }

  @override
  Future<int> loadReminderHour() async => _getInt(_kReminderHour, defaultValue: 20);

  @override
  Future<void> saveReminderHour(int hour) async {
    await _putInt(_kReminderHour, hour);
  }

  @override
  Future<int> loadReminderMinute() async => _getInt(_kReminderMinute, defaultValue: 0);

  @override
  Future<void> saveReminderMinute(int minute) async {
    await _putInt(_kReminderMinute, minute);
  }

  @override
  Future<bool> loadShowBalance() async => _getBool(_kShowBalance, defaultValue: true);

  @override
  Future<void> saveShowBalance(bool value) async {
    await _putBool(_kShowBalance, value);
  }

  @override
  Future<bool> loadAnimationsEnabled() async => _getBool(_kAnimationsEnabled, defaultValue: true);

  @override
  Future<void> saveAnimationsEnabled(bool value) async {
    await _putBool(_kAnimationsEnabled, value);
  }

  @override
  Future<String> loadCurrencyCode() async => _getString(_kCurrencyCode) ?? 'PHP';

  @override
  Future<void> saveCurrencyCode(String code) async {
    await _putString(_kCurrencyCode, code);
  }

  @override
  Future<String> loadAnalyticsDisplay() async =>
      _getString(_kAnalyticsDisplay) ?? 'Balanced dashboard';

  @override
  Future<void> saveAnalyticsDisplay(String value) async {
    await _putString(_kAnalyticsDisplay, value);
  }

  @override
  Future<Color> loadAccentColor() async {
    final val = _getInt(_kAccentColor, defaultValue: 0xFFA8FF3E);
    return Color(val);
  }

  // Need to import dart:ui for Color
  // ignore: use_super_parameters

  @override
  Future<void> saveAccentColor(Color color) async {
    await _putInt(_kAccentColor, color.toARGB32());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // User Profile
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<String> loadUserName() async => _getString(_kUserName) ?? 'User';

  @override
  Future<void> saveUserName(String name) async {
    await _putString(_kUserName, name);
  }

  @override
  Future<String> loadUserEmail() async => _getString(_kUserEmail) ?? '';

  @override
  Future<void> saveUserEmail(String email) async {
    await _putString(_kUserEmail, email);
  }

  @override
  Future<String?> loadUserPhotoUrl() async => _getString(_kUserPhotoUrl);

  @override
  Future<void> saveUserPhotoUrl(String? url) async {
    if (url != null) {
      await _putString(_kUserPhotoUrl, url);
    } else {
      await _box.delete(_k(_kUserPhotoUrl));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Notes
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> loadNotes() async {
    final json = _getString(_kNotes);
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveNotes(List<Map<String, dynamic>> notes) async {
    await _putString(_kNotes, jsonEncode(notes));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Calendar Events
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<CalendarEvent>> loadCalendarEvents() async {
    return _decodeList(_kCalendarEvents)
        .map((m) => CalendarEvent.fromMap(m))
        .toList();
  }

  @override
  Future<void> saveCalendarEvents(List<CalendarEvent> events) async {
    await _encodeList(_kCalendarEvents, events.map((e) => e.toMap()).toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Achievements & Gamification
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<AchievementBadge>> loadAchievementBadges() async {
    return _decodeList(_kAchievementBadges)
        .map((m) => AchievementBadge.fromMap(m))
        .toList();
  }

  @override
  Future<void> saveAchievementBadges(List<AchievementBadge> badges) async {
    await _encodeList(_kAchievementBadges, badges.map((b) => b.toMap()).toList());
  }

  @override
  Future<Set<String>> loadCelebratedMilestones() async {
    return _getStringList(_kCelebratedMilestones).toSet();
  }

  @override
  Future<void> saveCelebratedMilestones(Set<String> milestones) async {
    await _putStringList(_kCelebratedMilestones, milestones.toList());
  }

  @override
  Future<PlayerLevel> loadPlayerLevel() async {
    final json = _getString(_kPlayerLevel);
    if (json == null || json.isEmpty) return const PlayerLevel();
    try {
      return PlayerLevel.fromMap(jsonDecode(json));
    } catch (_) {
      return const PlayerLevel();
    }
  }

  @override
  Future<void> savePlayerLevel(PlayerLevel level) async {
    await _putString(_kPlayerLevel, jsonEncode(level.toMap()));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Dashboard Layout
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<String>> loadCardOrder() async => _getStringList(_kCardOrder);

  @override
  Future<void> saveCardOrder(List<String> order) async {
    await _putStringList(_kCardOrder, order);
  }

  @override
  Future<List<String>> loadHiddenCards() async => _getStringList(_kHiddenCards);

  @override
  Future<void> saveHiddenCards(List<String> hidden) async {
    await _putStringList(_kHiddenCards, hidden);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Reset
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }
}
