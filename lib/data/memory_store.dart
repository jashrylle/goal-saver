import 'dart:ui' show Color;
import '../models/goal_model.dart';
import '../models/achievement_model.dart';
import '../models/savings_plan_model.dart' show PlayerLevel;
import 'goal_saver_store.dart';

/// In-memory store — no disk writes, used for testing or as fallback.
/// Implements the full [GoalSaverStore] interface with empty defaults.
class MemoryGoalSaverStore implements GoalSaverStore {
  @override
  void setUserId(String? userId) {
    // Memory store doesn't persist data, so user ID is unused.
  }

  List<SavingsGoal> _goals = [];
  List<SavingsLog> _history = [];
  List<GoalCategory> _customCategories = [];
  Set<String> _unlockedPredefined = {};
  bool _isDarkMode = true;
  bool _remindersEnabled = true;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  bool _showBalance = true;
  bool _animationsEnabled = true;
  String _currencyCode = 'PHP';
  String _analyticsDisplay = 'Balanced dashboard';
  Color _accentColor = const Color(0xFFA8FF3E);
  String _userName = 'User';
  String _userEmail = '';
  String? _userPhotoUrl;
  List<Map<String, dynamic>> _notes = [];
  List<CalendarEvent> _calendarEvents = [];
  List<AchievementBadge> _achievementBadges = [];
  Set<String> _celebratedMilestones = {};
  PlayerLevel _playerLevel = const PlayerLevel();
  List<String> _cardOrder = [];
  List<String> _hiddenCards = [];

  @override
  Future<List<SavingsGoal>> loadGoals() async => List.of(_goals);

  @override
  Future<void> saveGoals(List<SavingsGoal> goals) async {
    _goals = List.of(goals);
  }

  @override
  Future<List<SavingsLog>> loadHistory() async => List.of(_history);

  @override
  Future<void> saveHistory(List<SavingsLog> history) async {
    _history = List.of(history);
  }

  @override
  Future<List<GoalCategory>> loadCustomCategories() async => List.of(_customCategories);

  @override
  Future<void> saveCustomCategories(List<GoalCategory> categories) async {
    _customCategories = List.of(categories);
  }

  @override
  Future<Set<String>> loadUnlockedPredefinedCategories() async =>
      Set.of(_unlockedPredefined);

  @override
  Future<void> saveUnlockedPredefinedCategories(Set<String> unlocked) async {
    _unlockedPredefined = Set.of(unlocked);
  }

  @override
  Future<bool> loadIsDarkMode() async => _isDarkMode;

  @override
  Future<void> saveIsDarkMode(bool value) async => _isDarkMode = value;

  @override
  Future<bool> loadRemindersEnabled() async => _remindersEnabled;

  @override
  Future<void> saveRemindersEnabled(bool value) async => _remindersEnabled = value;

  @override
  Future<int> loadReminderHour() async => _reminderHour;

  @override
  Future<void> saveReminderHour(int hour) async => _reminderHour = hour;

  @override
  Future<int> loadReminderMinute() async => _reminderMinute;

  @override
  Future<void> saveReminderMinute(int minute) async => _reminderMinute = minute;

  @override
  Future<bool> loadShowBalance() async => _showBalance;

  @override
  Future<void> saveShowBalance(bool value) async => _showBalance = value;

  @override
  Future<bool> loadAnimationsEnabled() async => _animationsEnabled;

  @override
  Future<void> saveAnimationsEnabled(bool value) async => _animationsEnabled = value;

  @override
  Future<String> loadCurrencyCode() async => _currencyCode;

  @override
  Future<void> saveCurrencyCode(String code) async => _currencyCode = code;

  @override
  Future<String> loadAnalyticsDisplay() async => _analyticsDisplay;

  @override
  Future<void> saveAnalyticsDisplay(String value) async => _analyticsDisplay = value;

  @override
  Future<Color> loadAccentColor() async => _accentColor;

  @override
  Future<void> saveAccentColor(Color color) async => _accentColor = color;

  @override
  Future<String> loadUserName() async => _userName;

  @override
  Future<void> saveUserName(String name) async => _userName = name;

  @override
  Future<String> loadUserEmail() async => _userEmail;

  @override
  Future<void> saveUserEmail(String email) async => _userEmail = email;

  @override
  Future<String?> loadUserPhotoUrl() async => _userPhotoUrl;

  @override
  Future<void> saveUserPhotoUrl(String? url) async => _userPhotoUrl = url;

  @override
  Future<List<Map<String, dynamic>>> loadNotes() async => List.of(_notes);

  @override
  Future<void> saveNotes(List<Map<String, dynamic>> notes) async {
    _notes = List.of(notes);
  }

  @override
  Future<List<CalendarEvent>> loadCalendarEvents() async =>
      List.of(_calendarEvents);

  @override
  Future<void> saveCalendarEvents(List<CalendarEvent> events) async {
    _calendarEvents = List.of(events);
  }

  @override
  Future<List<AchievementBadge>> loadAchievementBadges() async =>
      List.of(_achievementBadges);

  @override
  Future<void> saveAchievementBadges(List<AchievementBadge> badges) async {
    _achievementBadges = List.of(badges);
  }

  @override
  Future<Set<String>> loadCelebratedMilestones() async =>
      Set.of(_celebratedMilestones);

  @override
  Future<void> saveCelebratedMilestones(Set<String> milestones) async {
    _celebratedMilestones = Set.of(milestones);
  }

  @override
  Future<PlayerLevel> loadPlayerLevel() async => _playerLevel;

  @override
  Future<void> savePlayerLevel(PlayerLevel level) async {
    _playerLevel = level;
  }

  @override
  Future<List<String>> loadCardOrder() async => List.of(_cardOrder);

  @override
  Future<void> saveCardOrder(List<String> order) async {
    _cardOrder = List.of(order);
  }

  @override
  Future<List<String>> loadHiddenCards() async => List.of(_hiddenCards);

  @override
  Future<void> saveHiddenCards(List<String> hidden) async {
    _hiddenCards = List.of(hidden);
  }

  @override
  Future<void> clearAll() async {
    _goals = [];
    _history = [];
    _customCategories = [];
    _unlockedPredefined = {};
    _isDarkMode = true;
    _remindersEnabled = true;
    _reminderHour = 20;
    _reminderMinute = 0;
    _showBalance = true;
    _animationsEnabled = true;
    _currencyCode = 'PHP';
    _analyticsDisplay = 'Balanced dashboard';
    _accentColor = const Color(0xFFA8FF3E);
    _userName = 'User';
    _userEmail = '';
    _userPhotoUrl = null;
    _notes = [];
    _calendarEvents = [];
    _achievementBadges = [];
    _celebratedMilestones = {};
    _playerLevel = const PlayerLevel();
    _cardOrder = [];
    _hiddenCards = [];
  }
}
