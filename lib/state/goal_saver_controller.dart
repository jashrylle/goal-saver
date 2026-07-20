import 'dart:async';
import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../models/savings_plan_model.dart' show PlayerLevel, FinancialHealthScore, PlanStatus, PlanAdjustment, ResetFlags;
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../data/goal_saver_store.dart';
import '../logic/achievement_evaluator.dart';
import '../logic/daily_motivation.dart';
import '../logic/savings_plan_calculator.dart';
import '../models/achievement_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/extensions.dart';
import '../services/exchange_rate_service.dart';
import '../services/notification_service.dart';
import '../services/plan_notification_scheduler.dart';
import '../data/reset_registry.dart';

/// Dashboard summary card types for rearrange/hide feature.
enum DashboardCardType {
  balanceOverview('Balance Overview', Icons.account_balance_wallet_rounded, 'Your total saved vs target'),
  smartStatus('Smart Status', Icons.speed_rounded, 'Savings streak & health metrics'),
  quickActions('Quick Actions', Icons.bolt_rounded, 'Add goal or record savings'),
  confirmSavings("Today's Savings", Icons.notifications_active_rounded, 'Confirm recommended deposits'),
  playerLevel('Player Level', Icons.emoji_events_rounded, 'XP & gamification progress'),
  monthlySummary('Monthly Summary', Icons.calendar_month_rounded, 'This month\'s savings overview'),
  healthScore('Financial Health', Icons.favorite_rounded, 'Overall financial health score'),
  savingsCoach('Savings Coach', Icons.psychology_rounded, 'Personalized savings tips'),
  recentActivity('Recent Activity', Icons.history_rounded, 'Latest savings transactions'),
  notesPreview('Quick Notes', Icons.note_alt_rounded, 'Recent notes preview'),
  goalSearch('Search & Filters', Icons.search_rounded, 'Search and sort your goals');

  const DashboardCardType(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}

/// Default ordered list of all dashboard cards.
const List<DashboardCardType> kDefaultCardOrder = [
  DashboardCardType.balanceOverview,
  DashboardCardType.smartStatus,
  DashboardCardType.quickActions,
  DashboardCardType.confirmSavings,
  DashboardCardType.playerLevel,
  DashboardCardType.monthlySummary,
  DashboardCardType.healthScore,
  DashboardCardType.savingsCoach,
  DashboardCardType.recentActivity,
  DashboardCardType.notesPreview,
  DashboardCardType.goalSearch,
];

/// Central state controller for Goal Saver, backed by a [GoalSaverStore].
///
/// ALL state is persisted through the [GoalSaverStore] interface (Hive in
/// production, MemoryStore for testing). No data is stored via
/// FlutterSecureStorage — every property change is written to Hive immediately
/// so data survives navigation, tab switches, and app restarts.
class GoalSaverController extends ChangeNotifier {
  GoalSaverController(this._store);

  GoalSaverStore _store;

  /// Public access to the backing store (for backup/restore).
  GoalSaverStore get store => _store;

  // ── Core Data Lists ─────────────────────────────────────────────────────

  final List<SavingsGoal> _goals = [];
  final List<SavingsLog> _history = [];
  final List<GoalCategory> _customCategories = [];
  final List<CalendarEvent> _calendarEvents = [];

  // ── Settings (persisted) ────────────────────────────────────────────────

  String searchQuery = '';
  GoalCategory? categoryFilter;
  GoalSort sort = GoalSort.priority;
  AnalyticsRange range = AnalyticsRange.monthly;
  bool isDarkMode = true;
  bool remindersEnabled = true;
  int reminderHour = 20;
  int reminderMinute = 0;
  bool showBalance = true;
  bool animationsEnabled = true;
  String currencyCode = 'PHP';
  String analyticsDisplay = 'Balanced dashboard';
  bool isLoading = true;
  String userName = 'User';
  String userEmail = '';
  String? userPhotoUrl;
  String userNotes = '';
  List<Map<String, dynamic>> userNotesList = [];
  Color accentColor = const Color(0xFFA8FF3E);
  List<AchievementBadge> achievementBadges = [];
  int unreadNotificationCount = 0;
  String dailyMotivationMessage = '';
  bool hasCheckedInToday = false;

  Set<String> celebratedMilestones = {};

  /// Pending goal that was just completed (for celebration overlay).
  SavingsGoal? pendingCompletedGoal;

  void clearPendingCompletedGoal() {
    pendingCompletedGoal = null;
  }

  /// Pending milestone that was just reached (for celebration overlay).
  SavingsGoal? _pendingMilestoneGoal;
  int? _pendingMilestonePercent;

  SavingsGoal? get pendingMilestoneGoal => _pendingMilestoneGoal;
  int? get pendingMilestonePercent => _pendingMilestonePercent;

  void consumePendingMilestone() {
    _pendingMilestoneGoal = null;
    _pendingMilestonePercent = null;
  }

  /// Pending achievements that were just unlocked (for celebration overlay).
  final List<AchievementBadge> _pendingNewAchievements = [];
  List<AchievementBadge> get pendingNewAchievements => List.unmodifiable(_pendingNewAchievements);

  /// Consume and clear pending new achievements.
  List<AchievementBadge> consumePendingAchievements() {
    final list = List<AchievementBadge>.from(_pendingNewAchievements);
    _pendingNewAchievements.clear();
    return list;
  }

  /// Tracks which predefined categories the user has unlocked for editing.
  Set<String> _unlockedPredefinedCategories = {};
  Set<String> get unlockedPredefinedCategories => Set.unmodifiable(_unlockedPredefinedCategories);
  bool isPredefinedUnlocked(String name) => _unlockedPredefinedCategories.contains(name);

  // ── Dashboard Card Customization ────────────────────────────────────────

  List<DashboardCardType> _visibleCardOrder = List.from(kDefaultCardOrder);
  Set<DashboardCardType> _hiddenCards = {};

  List<DashboardCardType> get visibleCardOrder => List.unmodifiable(_visibleCardOrder);
  bool isCardHidden(DashboardCardType type) => _hiddenCards.contains(type);

  Future<void> toggleCardVisibility(DashboardCardType type) async {
    if (_hiddenCards.contains(type)) {
      _hiddenCards.remove(type);
      if (!_visibleCardOrder.contains(type)) {
        final defaultIndex = kDefaultCardOrder.indexOf(type);
        int insertAt = _visibleCardOrder.length;
        for (int i = 0; i < _visibleCardOrder.length; i++) {
          final defaultPos = kDefaultCardOrder.indexOf(_visibleCardOrder[i]);
          if (defaultPos > defaultIndex) {
            insertAt = i;
            break;
          }
        }
        _visibleCardOrder.insert(insertAt.clamp(0, _visibleCardOrder.length), type);
      }
    } else {
      _hiddenCards.add(type);
      _visibleCardOrder.remove(type);
    }
    await _persistDashboardLayout();
    notifyListeners();
  }

  Future<void> reorderCards(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final card = _visibleCardOrder.removeAt(oldIndex);
    _visibleCardOrder.insert(newIndex.clamp(0, _visibleCardOrder.length), card);
    await _persistDashboardLayout();
    notifyListeners();
  }

  Future<void> resetCardOrder() async {
    _visibleCardOrder = List.from(kDefaultCardOrder);
    _hiddenCards = {};
    await _persistDashboardLayout();
    notifyListeners();
  }

  Future<void> _persistDashboardLayout() async {
    try {
      await _store.saveCardOrder(_visibleCardOrder.map((c) => c.name).toList());
      await _store.saveHiddenCards(_hiddenCards.map((c) => c.name).toList());
    } catch (_) {}
  }

  Future<void> _loadDashboardLayout() async {
    try {
      final orderNames = await _store.loadCardOrder();
      if (orderNames.isNotEmpty) {
        _visibleCardOrder = orderNames
            .map((name) => DashboardCardType.values.firstWhere(
                  (t) => t.name == name,
                  orElse: () => DashboardCardType.balanceOverview,
                ))
            .toList();
      }
      final hiddenNames = await _store.loadHiddenCards();
      if (hiddenNames.isNotEmpty) {
        _hiddenCards = hiddenNames
            .map((name) => DashboardCardType.values.firstWhere(
                  (t) => t.name == name,
                  orElse: () => DashboardCardType.balanceOverview,
                ))
            .toSet();
      }
      _visibleCardOrder.removeWhere((c) => _hiddenCards.contains(c));
    } catch (_) {}
  }

  static const List<Color> accentColorPalette = [
    Color(0xFFA8FF3E), // Lime (default)
    Color(0xFF5FDE9E), // Green
    Color(0xFF00D9FF), // Cyan
    Color(0xFFFF6B9D), // Pink
    Color(0xFF9D4EDD), // Purple
    Color(0xFFFFB703), // Amber
    Color(0xFFFF8A65), // Coral
    Color(0xFF52B788), // Teal
  ];

  static const Map<String, String> accentColorNames = {
    '0xFFA8FF3E': 'Lime',
    '0xFF5FDE9E': 'Green',
    '0xFF00D9FF': 'Cyan',
    '0xFFFF6B9D': 'Pink',
    '0xFF9D4EDD': 'Purple',
    '0xFFFFB703': 'Amber',
    '0xFFFF8A65': 'Coral',
    '0xFF52B788': 'Teal',
  };

  String get accentColorName =>
      accentColorNames[accentColor.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')] ??
      'Custom';

  String get currencySymbol => const {
    'PHP': '₱',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
  }[currencyCode] ?? '₱';

  String formatMoney(double value) {
    return CurrencyFormatter.format(value);
  }

  SavingsPlanCalculator get calc => SavingsPlanCalculator.instance;

  // ── Computed Getters ────────────────────────────────────────────────────

  List<SavingsGoal> get goals {
    var result = _goals.where((goal) {
      final query = searchQuery.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          goal.title.toLowerCase().contains(query) ||
          goal.categoryName.toLowerCase().contains(query);
      final matchesCategory =
          categoryFilter == null || goal.category == categoryFilter;
      return matchesSearch && matchesCategory && !goal.deleted && !goal.archived;
    }).toList();

    result.sort((a, b) {
      if (sort == GoalSort.priority) return b.priority.compareTo(a.priority);
      if (sort == GoalSort.progress) return b.progress.compareTo(a.progress);
      if (sort == GoalSort.deadline) return a.daysLeft.compareTo(b.daysLeft);
      if (sort == GoalSort.target) return b.target.compareTo(a.target);
      return (b.createdDate ?? DateTime.now()).compareTo(a.createdDate ?? DateTime.now());
    });

    return result;
  }

  List<SavingsGoal> get archivedGoals =>
      _goals.where((goal) => goal.archived && !goal.deleted).toList();

  List<SavingsGoal> get allActiveGoals =>
      _goals.where((goal) => !goal.deleted && !goal.archived).toList();

  List<SavingsLog> get history => List.unmodifiable(_history);

  List<GoalCategory> get customCategories => List.unmodifiable(_customCategories);

  List<GoalCategory> get allCategories {
    final seen = GoalCategory.predefined.map((c) => c.name).toSet();
    return [
      ...GoalCategory.predefined,
      ..._customCategories.where((c) => !seen.contains(c.name)),
    ];
  }

  double get totalSaved =>
      allActiveGoals.fold(0, (total, goal) => total + goal.saved);

  double get totalTarget =>
      allActiveGoals.fold(0, (total, goal) => total + goal.target);

  double get averageProgress => totalTarget == 0 ? 0 : (totalSaved / totalTarget).clamp(0, 1);

  int get streakDays {
    if (_history.isEmpty) return 0;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final day = todayStart.subtract(Duration(days: i));
      final hasActivity = _history.any((log) =>
        log.date.day == day.day &&
        log.date.month == day.month &&
        log.date.year == day.year
      );
      if (hasActivity) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int get disciplineScore {
    final consistency = streakDays / 25;
    final progress = averageProgress.clamp(0, 1);
    final historyScore = (_history.length / 16).clamp(0, 1);
    return ((consistency * .42 + progress * .38 + historyScore * .20) * 100).round();
  }

  List<SavingsLog> get logsForSelectedRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _history.where((log) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      final difference = today.difference(logDate).inDays;
      return switch (range) {
        AnalyticsRange.daily => difference == 0,
        AnalyticsRange.weekly => difference >= 0 && difference < 7,
        AnalyticsRange.monthly => difference >= 0 && difference < 30,
        AnalyticsRange.yearly => difference >= 0 && difference < 365,
      };
    }).toList();
  }

  double get savedInSelectedRange {
    return logsForSelectedRange.fold<double>(0.0, (sum, log) => sum + log.amount);
  }

  double get targetInSelectedRange {
    double total = 0.0;
    final rangeDays = switch (range) {
      AnalyticsRange.daily => 1,
      AnalyticsRange.weekly => 7,
      AnalyticsRange.monthly => 30,
      AnalyticsRange.yearly => 365,
    };
    for (final goal in allActiveGoals) {
      total += SavingsPlanCalculator.proratedTargetForRange(
        target: goal.target,
        saved: goal.saved,
        daysLeft: goal.daysLeft.toDouble(),
        frequencyDays: goal.frequency.days,
        rangeDays: rangeDays,
      );
    }
    return total == 0 ? totalSaved : total;
  }

  List<Map<String, dynamic>> get weeklyContributions {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < 7; i++) {
      final dayDate = startOfWeek.add(Duration(days: i));
      final totalForDay = _history
          .where((log) => log.date.day == dayDate.day && log.date.month == dayDate.month && log.date.year == dayDate.year)
          .fold<double>(0.0, (sum, log) => sum + log.amount);
      result.add({'label': days[i], 'value': totalForDay});
    }
    return result;
  }

  List<Map<String, dynamic>> get monthlySavingsData {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (var i = 5; i >= 0; i--) {
      int targetMonth = now.month - i;
      int targetYear = now.year;
      while (targetMonth < 1) {
        targetMonth += 12;
        targetYear -= 1;
      }
      final targetDate = DateTime(targetYear, targetMonth, 1);
      final monthName = _getMonthName(targetDate.month);
      final totalInMonth = _history
          .where((log) => log.date.month == targetDate.month && log.date.year == targetDate.year)
          .fold<double>(0.0, (sum, log) => sum + log.amount);
      result.add({'month': '$monthName ${targetDate.year}', 'amount': totalInMonth});
    }
    return result;
  }

  String _getMonthName(int month) {
    return const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][month - 1];
  }

  // ── Load / Persist ──────────────────────────────────────────────────────

  /// Load ALL state from the Hive store.
  ///
  /// This is the SINGLE source of truth for persisted data. Every property
  /// is loaded from Hive because:
  /// 1. All writes go through _store.save* methods (which persist to Hive synchronously)
  /// 2. The _store has user-scoped keys set via setUserId() before this call
  /// 3. The try/finally pattern ensures isLoading is always reset
  ///
  /// Data survives restarts because:
  /// - Auth session is stored in the goal_saver_auth box (_kCurrentUserId)
  /// - All user data is stored in the goal_saver_local_store box with {userId}_ prefix
  /// - Both boxes are opened in main.dart before the app runs
  /// - loadUserData() sets the userId context before calling this method
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      registerDefaultResetEntries();

      // ── Load goals & history (AWAIT each for reliable ordering) ─
      try {
        final savedGoals = await _store.loadGoals();
        _goals
          ..clear()
          ..addAll(savedGoals.map((g) => g.ensurePlan()).toList());
        debugPrint('[Controller] Loaded ${_goals.length} goals from Hive.');
      } catch (e) {
        debugPrint('[Controller] Error loading goals: $e');
      }

      try {
        final savedHistory = await _store.loadHistory();
        _history
          ..clear()
          ..addAll(savedHistory);
        debugPrint('[Controller] Loaded ${_history.length} history entries from Hive.');
      } catch (e) {
        debugPrint('[Controller] Error loading history: $e');
      }

      // ── Load user profile from Hive store (primary source) ────
      // The Hive store's user-scoped keys are the authoritative source
      // because they are written on every profile update via updateProfile().
      // AuthService is the fallback for legacy data compatibility.
      try {
        final loadedName = await _store.loadUserName();
        if (loadedName.isNotEmpty && loadedName != 'User') {
          userName = loadedName;
        }
      } catch (_) {}
      try {
        final loadedEmail = await _store.loadUserEmail();
        if (loadedEmail.isNotEmpty) {
          userEmail = loadedEmail;
        }
      } catch (_) {}
      try {
        final loadedPhotoUrl = await _store.loadUserPhotoUrl();
        if (loadedPhotoUrl != null && loadedPhotoUrl.isNotEmpty) {
          userPhotoUrl = loadedPhotoUrl;
        }
      } catch (_) {}

      // ── Try from AuthService as secondary source ──────────────
      // Only overwrites if Hive store values are empty defaults
      try {
        final authService = AuthService();
        final user = await authService.getUser();
        if (user != null) {
          if (userName == 'User' || userName.isEmpty) {
            userName = user.name;
          }
          if (userEmail.isEmpty) {
            userEmail = user.email;
          }
          if (userPhotoUrl == null || userPhotoUrl!.isEmpty) {
            userPhotoUrl = user.photoUrl;
          }
        }
      } catch (_) {}

      debugPrint('[Controller] Profile: userName="$userName", userEmail="$userEmail", userPhotoUrl="$userPhotoUrl"');

      // ── Load settings from Hive ──────────────────────────────
      try {
        isDarkMode = await _store.loadIsDarkMode();
        remindersEnabled = await _store.loadRemindersEnabled();
        reminderHour = await _store.loadReminderHour();
        reminderMinute = await _store.loadReminderMinute();
        showBalance = await _store.loadShowBalance();
        animationsEnabled = await _store.loadAnimationsEnabled();
        currencyCode = await _store.loadCurrencyCode();
        analyticsDisplay = await _store.loadAnalyticsDisplay();
        accentColor = await _store.loadAccentColor();
        CurrencyFormatter.setCurrency(currencyCode);
      } catch (_) {}

      // ── Load notes ───────────────────────────────────────────
      try {
        userNotesList = await _store.loadNotes();
        _sortNotes();
      } catch (_) {}

      // ── Load calendar events ─────────────────────────────────
      try {
        _calendarEvents
          ..clear()
          ..addAll(await _store.loadCalendarEvents());
      } catch (_) {}

      // ── Load achievements & gamification ─────────────────────
      try {
        achievementBadges = await _store.loadAchievementBadges();
      } catch (_) {}

      try {
        celebratedMilestones = await _store.loadCelebratedMilestones();
      } catch (_) {}

      try {
        _playerLevel = await _store.loadPlayerLevel();
      } catch (_) {
        _playerLevel = const PlayerLevel();
      }

      // ── Load categories ──────────────────────────────────────
      try {
        _customCategories
          ..clear()
          ..addAll(await _store.loadCustomCategories());
      } catch (_) {}
      try {
        _unlockedPredefinedCategories = await _store.loadUnlockedPredefinedCategories();
      } catch (_) {}

      // ── Load dashboard layout ────────────────────────────────
      try {
        await _loadDashboardLayout();
      } catch (_) {}

      // ── Exchange rates (async, non-blocking) ─────────────────
      ExchangeRateService().fetchRates().then((_) => notifyListeners());

      // ── Silent achievement evaluation (no popups on load) ────
      try {
        await evaluateAchievementsSilent();
      } catch (_) {}

      // ── Update notifications ─────────────────────────────────
      _updateNotifications();
    } finally {
      // Always reset loading state, even if exceptions occurred
      isLoading = false;
      notifyListeners();
    }
  }

  /// Called after Hive is ready — persists current memory state to Hive.
  ///
  /// CRITICAL: Checks for existing persisted data in the new store BEFORE
  /// writing anything. If existing goals or history exist (real user data
  /// from a previous session), those are preserved and the temporary
  /// in-memory seed data is discarded entirely. Only on a genuinely
  /// first-ever launch (durable store completely empty) does it persist
  /// the in-memory state as the starting point.
  Future<void> switchStore(GoalSaverStore newStore) async {
    // First, check if the target store already has persisted data
    final existingGoals = await newStore.loadGoals();
    final existingHistory = await newStore.loadHistory();

    _store = newStore;

    if (existingGoals.isNotEmpty || existingHistory.isNotEmpty) {
      // Real user data exists from a previous session — discard the
      // temporary in-memory seed data and load the real data directly.
      debugPrint('[Controller] switchStore: existing data found, loading directly from store.');
      await load();
    } else {
      // Genuinely first-ever launch — write the in-memory state as the
      // starting point so the user sees seed/demo data on first run.
      debugPrint('[Controller] switchStore: no existing data, saving current in-memory state.');
      await newStore.saveGoals(List.of(_goals));
      await newStore.saveHistory(List.of(_history));
      await _saveAllSettingsToStore(newStore);
      await load();
    }
  }

  /// Save all current settings to a given store (used during store switch).
  Future<void> _saveAllSettingsToStore(GoalSaverStore target) async {
    try {
      await target.saveCustomCategories(_customCategories);
      await target.saveUnlockedPredefinedCategories(_unlockedPredefinedCategories);
      await target.saveIsDarkMode(isDarkMode);
      await target.saveRemindersEnabled(remindersEnabled);
      await target.saveReminderHour(reminderHour);
      await target.saveReminderMinute(reminderMinute);
      await target.saveShowBalance(showBalance);
      await target.saveAnimationsEnabled(animationsEnabled);
      await target.saveCurrencyCode(currencyCode);
      await target.saveAnalyticsDisplay(analyticsDisplay);
      await target.saveAccentColor(accentColor);
      await target.saveUserName(userName);
      await target.saveUserEmail(userEmail);
      await target.saveUserPhotoUrl(userPhotoUrl);
      await target.saveNotes(userNotesList);
      await target.saveCalendarEvents(_calendarEvents);
      await target.saveAchievementBadges(achievementBadges);
      await target.saveCelebratedMilestones(celebratedMilestones);
      await target.savePlayerLevel(_playerLevel);
      await target.saveCardOrder(_visibleCardOrder.map((c) => c.name).toList());
      await target.saveHiddenCards(_hiddenCards.map((c) => c.name).toList());
    } catch (_) {}
  }

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    isLoading = false;
    notifyListeners();
  }

  void _updateNotifications() {
    try {
      if (remindersEnabled) {
        for (final goal in allActiveGoals) {
          _scheduleGoalNotification(goal);
        }
      } else {
        NotificationService().cancelAllNotifications();
      }
    } catch (_) {}
  }

  // ── Notes ───────────────────────────────────────────────────────────────

  Future<void> updateUserNotes(String notes) async {
    userNotes = notes;
    await _persistNotes();
    notifyListeners();
  }

  List<Map<String, dynamic>> get savedNotes => List.unmodifiable(userNotesList);

  Future<void> addNote(String content) async {
    if (content.trim().isEmpty) return;
    final now = DateTime.now();
    userNotesList.insert(0, {
      'id': now.microsecondsSinceEpoch.toString(),
      'content': content.trim(),
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
    _sortNotes();
    await _persistNotes();
    notifyListeners();
  }

  Future<void> updateNote(String id, String newContent) async {
    final index = userNotesList.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      userNotesList[index]['content'] = newContent.trim();
      userNotesList[index]['updatedAt'] = DateTime.now().toIso8601String();
      _sortNotes();
      await _persistNotes();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    userNotesList.removeWhere((n) => n['id'] == id);
    await _persistNotes();
    notifyListeners();
  }

  void _sortNotes() {
    userNotesList.sort((a, b) {
      final aDate = DateTime.tryParse(a['createdAt'] as String? ?? '') ?? DateTime(2000);
      final bDate = DateTime.tryParse(b['createdAt'] as String? ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
  }

  Future<void> _persistNotes() async {
    _sortNotes();
    await _store.saveNotes(userNotesList);
  }

  // ── Calendar Events ─────────────────────────────────────────────────────

  List<CalendarEvent> get calendarEvents => List.unmodifiable(_calendarEvents);

  List<CalendarEvent> getEventsForDate(DateTime date) {
    return _calendarEvents.where((event) =>
      event.date.day == date.day &&
      event.date.month == date.month &&
      event.date.year == date.year
    ).toList();
  }

  Future<void> addCalendarEvent(CalendarEvent event) async {
    _calendarEvents.add(event);
    await _store.saveCalendarEvents(_calendarEvents);
    notifyListeners();
  }

  Future<void> updateCalendarEvent(CalendarEvent event) async {
    final index = _calendarEvents.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _calendarEvents[index] = event;
      await _store.saveCalendarEvents(_calendarEvents);
      notifyListeners();
    }
  }

  Future<void> deleteCalendarEvent(CalendarEvent event) async {
    _calendarEvents.removeWhere((e) => e.id == event.id);
    await _store.saveCalendarEvents(_calendarEvents);
    notifyListeners();
  }

  // ── Settings ────────────────────────────────────────────────────────────

  Future<void> setReminderTime(int hour, int minute) async {
    reminderHour = hour;
    reminderMinute = minute;
    await _store.saveReminderHour(hour);
    await _store.saveReminderMinute(minute);
    _updateNotifications();
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    accentColor = color;
    await _store.saveAccentColor(color);
    notifyListeners();
  }

  Future<void> refreshExchangeRates() async {
    await ExchangeRateService().fetchRates(baseCurrency: 'PHP');
    notifyListeners();
  }

  bool get hasExchangeRates => ExchangeRateService().latestRates != null;
  String get exchangeRatesLastUpdated => ExchangeRateService().lastUpdatedLabel;
  String get currentRateLabel => ExchangeRateService().shortRateLabel(currencyCode);

  // ── Streak / Heatmap ────────────────────────────────────────────────────

  List<Map<String, dynamic>> get streakHeatmapData {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 364; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayHistory = _history.where((log) =>
        log.date.day == day.day &&
        log.date.month == day.month &&
        log.date.year == day.year
      ).toList();
      final totalAmount = dayHistory.fold<double>(0, (sum, log) => sum + log.amount);
      result.add({
        'date': day,
        'count': dayHistory.length,
        'amount': totalAmount,
        'active': dayHistory.isNotEmpty,
      });
    }
    return result;
  }

  int get longestStreak {
    if (_history.isEmpty) return 0;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    int maxStreak = 0;
    int currentStreakCount = 0;
    for (int i = 0; i < 365; i++) {
      final day = todayStart.subtract(Duration(days: i));
      final hasActivity = _history.any((log) =>
        log.date.day == day.day &&
        log.date.month == day.month &&
        log.date.year == day.year
      );
      if (hasActivity) {
        currentStreakCount++;
        if (currentStreakCount > maxStreak) {
          maxStreak = currentStreakCount;
        }
      } else {
        currentStreakCount = 0;
      }
    }
    return maxStreak;
  }

  // ── Milestone Celebrations ──────────────────────────────────────────────

  int? checkMilestoneCelebration(SavingsGoal goal) {
    final progressPct = (goal.progress * 100).round();
    for (final milestone in [25, 50, 75, 100]) {
      if (progressPct >= milestone) {
        final key = '${goal.id}_$milestone';
        if (!celebratedMilestones.contains(key)) {
          celebratedMilestones.add(key);
          // fire-and-forget persisting milestone data (non-critical path)
          _persistCelebratedMilestones();
          // Set pending milestone for the shell to display
          _pendingMilestoneGoal = goal;
          _pendingMilestonePercent = milestone;
          return milestone;
        }
      }
    }
    return null;
  }

  Future<void> _persistCelebratedMilestones() async {
    try {
      await _store.saveCelebratedMilestones(celebratedMilestones);
    } catch (_) {}
  }

  void resetMilestoneCelebrations(String goalId) {
    celebratedMilestones.removeWhere((key) => key.startsWith('${goalId}_'));
    _persistCelebratedMilestones();
  }

  // ── Recommendations ─────────────────────────────────────────────────────

  List<String> get personalizedRecommendations {
    final recommendations = <String>[];
    if (streakDays < 3) {
      recommendations.add('Start building your streak! Try saving a small amount every day, even just ₱10.');
    } else if (streakDays < 7) {
      recommendations.add('Great start on your streak! Aim for 7 days to earn the Bronze Streak badge.');
    } else if (streakDays < 30) {
      recommendations.add('You\'re on a roll! Keep it up for 30 days to unlock Gold Streak! 🔥');
    } else {
      recommendations.add('Incredible $streakDays-day streak! You\'re a savings legend! 🌟');
    }
    final activeCount = allActiveGoals.length;
    if (activeCount == 0) {
      recommendations.add('Create your first savings goal to start your journey!');
    } else if (activeCount > 5) {
      recommendations.add('You have $activeCount active goals. Consider focusing on your top priorities first.');
    }
    final completedCount = allActiveGoals.where((g) => g.completed).length;
    if (completedCount == 0 && activeCount > 0) {
      recommendations.add('Focus on completing your closest goal for motivation!');
    }
    final health = financialHealth;
    if (health.consistency < 0.3) {
      recommendations.add('Try to save on a regular schedule to improve your consistency score.');
    }
    if (health.savingsRate < 0.3) {
      recommendations.add('Consider increasing your savings amounts to reach your targets faster.');
    }
    if (recommendations.length < 2) {
      recommendations.add(DailyMotivation.getTip(
        streakDays: streakDays,
        activeGoals: activeCount,
        totalSaved: totalSaved,
      ));
    }
    return recommendations;
  }

  // ── Gamification ────────────────────────────────────────────────────────

  PlayerLevel _playerLevel = const PlayerLevel();
  PlayerLevel get playerLevel => _playerLevel;

  FinancialHealthScore get financialHealth {
    final activeCount = allActiveGoals.length;
    final completedCount = allActiveGoals.where((g) => g.completed).length;
    final streakRatio = (streakDays / 30).clamp(0.0, 1.0);
    final completionRate = activeCount > 0 ? (completedCount / activeCount).clamp(0.0, 1.0) : 0.0;
    final avgTarget = activeCount > 0 ? totalTarget / activeCount : 1.0;
    final savingsRate = avgTarget > 0 ? (totalSaved / (avgTarget * activeCount)).clamp(0.0, 1.0) : 0.0;
    final disc = (disciplineScore / 100).clamp(0.0, 1.0);
    return FinancialHealthScore(
      consistency: streakRatio,
      completionRate: completionRate,
      savingsRate: savingsRate,
      progressRate: averageProgress.clamp(0.0, 1.0),
      discipline: disc,
    );
  }

  Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    var newXp = _playerLevel.xp + amount;
    var newTotalXp = _playerLevel.totalXp + amount;
    var newLevel = _playerLevel.level;
    var newXpToNext = _playerLevel.xpToNextLevel;
    while (newXp >= newXpToNext && newLevel < 10) {
      newXp -= newXpToNext;
      newLevel++;
      newXpToNext = (newXpToNext * 1.5).round();
    }
    _playerLevel = _playerLevel.copyWith(
      level: newLevel,
      xp: newXp,
      xpToNextLevel: newXpToNext,
      totalXp: newTotalXp,
    );
    await _store.savePlayerLevel(_playerLevel);
    notifyListeners();
  }

  Future<void> awardDepositXp(double amount) async {
    final xp = (amount / 100).round().clamp(5, 100) + 10;
    await addXp(xp);
  }

  // ── Achievements ────────────────────────────────────────────────────────

  /// Evaluate achievements and track newly unlocked ones for celebration.
  Future<void> evaluateAchievements() async {
    final previous = List<AchievementBadge>.from(achievementBadges);
    final snapshot = AchievementSnapshot(
      activeGoalCount: allActiveGoals.length,
      completedGoalCount: allActiveGoals.where((g) => g.completed).length,
      streakDays: streakDays,
      disciplineScore: disciplineScore,
      totalSaved: totalSaved,
      goals: allActiveGoals,
      history: _history,
    );
    final updatedBadges = AchievementEvaluator.evaluateAll(snapshot, achievementBadges);
    achievementBadges = updatedBadges;
    await _store.saveAchievementBadges(achievementBadges);

    // Only flag as newly unlocked if this is not the initial load
    // (avoids flashing achievements on first launch with existing data)
    if (previous.isNotEmpty) {
      final newlyUnlocked = AchievementEvaluator.countNewlyUnlocked(previous, updatedBadges);
      if (newlyUnlocked > 0) {
        int totalXp = 0;
        for (final badge in updatedBadges) {
          if (badge.unlocked) {
            final wasLocked = previous.where((b) => b.id == badge.id).firstOrNull;
            if (wasLocked == null || !wasLocked.unlocked) {
              _pendingNewAchievements.add(badge);
              totalXp += _achievementRewardXp(badge.requirement);
            }
          }
        }
        // Award XP once for all newly unlocked badges
        if (totalXp > 0) {
          await addXp(totalXp);
        }
      }
    }

    notifyListeners();
  }

  /// Calculate XP reward for unlocking an achievement based on requirement.
  int _achievementRewardXp(int requirement) {
    if (requirement >= 1000000) return 500;
    if (requirement >= 100000) return 250;
    if (requirement >= 10000) return 100;
    if (requirement >= 1000) return 50;
    return 25;
  }

  /// Initial achievement evaluation on app load (no celebration popups).
  Future<void> evaluateAchievementsSilent() async {
    final snapshot = AchievementSnapshot(
      activeGoalCount: allActiveGoals.length,
      completedGoalCount: allActiveGoals.where((g) => g.completed).length,
      streakDays: streakDays,
      disciplineScore: disciplineScore,
      totalSaved: totalSaved,
      goals: allActiveGoals,
      history: _history,
    );
    final updatedBadges = AchievementEvaluator.evaluateAll(snapshot, achievementBadges);
    achievementBadges = updatedBadges;
    await _store.saveAchievementBadges(achievementBadges);
    // No celebration popups — this is a silent evaluation at startup
  }

  void incrementNotificationBadge() {
    unreadNotificationCount++;
    notifyListeners();
  }

  void clearNotificationBadge() {
    unreadNotificationCount = 0;
    notifyListeners();
  }

  // ── UI Setters ──────────────────────────────────────────────────────────

  void updateSearch(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setSort(GoalSort value) {
    sort = value;
    notifyListeners();
  }

  void setCategory(GoalCategory? value) {
    categoryFilter = value;
    notifyListeners();
  }

  void setRange(AnalyticsRange value) {
    range = value;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    isDarkMode = value;
    await _store.saveIsDarkMode(value);
    notifyListeners();
  }

  Future<void> toggleReminders(bool value) async {
    remindersEnabled = value;
    await _store.saveRemindersEnabled(value);
    _updateNotifications();
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool value) async {
    animationsEnabled = value;
    await _store.saveAnimationsEnabled(value);
    notifyListeners();
  }

  Future<void> toggleBalanceVisibility() async {
    showBalance = !showBalance;
    await _store.saveShowBalance(showBalance);
    notifyListeners();
  }

  Future<void> setShowBalance(bool value) async {
    showBalance = value;
    await _store.saveShowBalance(value);
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    currencyCode = value;
    CurrencyFormatter.setCurrency(value);
    await _store.saveCurrencyCode(value);
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    userName = name;
    await _store.saveUserName(name);
    try {
      final authService = AuthService();
      final user = await authService.getUser();
      if (user != null) {
        await authService.saveUser(user.copyWith(name: name));
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateProfile({required String name, required String email, String? photoUrl}) async {
    userName = name;
    userEmail = email;
    userPhotoUrl = photoUrl;
    await _store.saveUserName(name);
    await _store.saveUserEmail(email);
    await _store.saveUserPhotoUrl(photoUrl);
    try {
      final authService = AuthService();
      final user = await authService.getUser();
      if (user != null) {
        await authService.saveUser(user.copyWith(
          name: name,
          email: email,
          photoUrl: photoUrl,
        ));
      }
    } catch (_) {}
    notifyListeners();
  }

  // ── Authentication & User Data ──────────────────────────────────────────

  /// Initialize a new user's profile data immediately after successful signup.
  /// This creates the user's first settings, default achievements, and saves
  /// all initial data to Hive under the user-scoped keys.
  Future<void> initializeNewUser(String userId, UserModel user) async {
    // Set the user context on the store so all data is saved under userId keys
    _store.setUserId(userId);

    // Save profile data
    userName = user.name;
    userEmail = user.email;
    userPhotoUrl = user.photoUrl;
    await _store.saveUserName(user.name);
    await _store.saveUserEmail(user.email);
    await _store.saveUserPhotoUrl(user.photoUrl);

    // Save default settings
    await _store.saveIsDarkMode(true);
    await _store.saveRemindersEnabled(true);
    await _store.saveReminderHour(20);
    await _store.saveReminderMinute(0);
    await _store.saveShowBalance(true);
    await _store.saveAnimationsEnabled(true);
    await _store.saveCurrencyCode('PHP');
    await _store.saveAnalyticsDisplay('Balanced dashboard');
    await _store.saveAccentColor(const Color(0xFFA8FF3E));

    // Initialize achievements
    achievementBadges = Achievements.all
        .map((badge) => badge.copyWith(
              unlocked: false,
              unlockedDate: null,
              currentProgress: 0,
            ))
        .toList();
    await _store.saveAchievementBadges(achievementBadges);

    // Initialize player level
    _playerLevel = const PlayerLevel();
    await _store.savePlayerLevel(_playerLevel);

    // Save empty lists for other data
    await _store.saveGoals(_goals);
    await _store.saveHistory(_history);
    await _store.saveCustomCategories(_customCategories);
    await _store.saveUnlockedPredefinedCategories(_unlockedPredefinedCategories);
    await _store.saveNotes(userNotesList);
    await _store.saveCalendarEvents(_calendarEvents);
    await _store.saveCelebratedMilestones(celebratedMilestones);
    await _store.saveCardOrder(kDefaultCardOrder.map((c) => c.name).toList());
    await _store.saveHiddenCards([]);

    // Sync the auth user profile
    try {
      final authService = AuthService();
      await authService.saveUser(user);
    } catch (_) {}

    notifyListeners();
  }

  /// After a successful sign-in, set the user context and load all data.
  /// Call this instead of [load()] to ensure user-scoped data isolation.
  /// This is the SINGLE entry point for loading persisted user data from Hive
  /// after authentication, whether on app startup or after sign-in/sign-up.
  Future<void> loadUserData(String userId) async {
    // Validate the user ID
    if (userId.isEmpty) {
      debugPrint('[Controller] loadUserData called with empty userId!');
      isLoading = false;
      notifyListeners();
      return;
    }

    // Set the user context on the store so all keys are scoped to this user
    _store.setUserId(userId);

    // Load all data from the store
    isLoading = true;
    notifyListeners();

    debugPrint('[Controller] loadUserData: loading data for user $userId');
    await load();
    debugPrint('[Controller] loadUserData: loaded ${_goals.length} goals, ${_history.length} history entries');
  }

  /// Clear all in-memory data when signing out.
  /// Resets the store's user context so the next user's data is isolated.
  /// IMPORTANT: This does NOT touch any Hive data. All user data is preserved
  /// in Hive under user-scoped keys and will be reloaded on next sign-in.
  Future<void> signOutAndClear() async {
    // Clear in-memory data only — Hive data is preserved untouched
    _goals.clear();
    _history.clear();
    _customCategories.clear();
    _calendarEvents.clear();
    _unlockedPredefinedCategories.clear();
    achievementBadges.clear();
    celebratedMilestones.clear();
    _playerLevel = const PlayerLevel();
    userName = 'User';
    userEmail = '';
    userPhotoUrl = null;
    userNotesList.clear();
    userNotes = '';
    searchQuery = '';
    categoryFilter = null;
    sort = GoalSort.priority;
    range = AnalyticsRange.monthly;
    hasCheckedInToday = false;
    dailyMotivationMessage = '';
    pendingCompletedGoal = null;
    consumePendingMilestone();
    _pendingNewAchievements.clear();
    celebratedMilestones.clear();

    // Reset all settings to defaults
    isDarkMode = true;
    remindersEnabled = true;
    reminderHour = 20;
    reminderMinute = 0;
    showBalance = true;
    animationsEnabled = true;
    currencyCode = 'PHP';
    analyticsDisplay = 'Balanced dashboard';
    accentColor = const Color(0xFFA8FF3E);
    _visibleCardOrder = List.from(kDefaultCardOrder);
    _hiddenCards = {};

    // Reset the user context on the store so no stale keys remain
    _store.setUserId(null);

    debugPrint('[Controller] signOutAndClear: memory cleared, Hive data preserved.');
    notifyListeners();
  }

  List<String> get allAvailableCurrencies {
    return const ['PHP', 'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'SGD'];
  }

  // ── Categories ──────────────────────────────────────────────────────────

  Future<void> addCustomCategory(GoalCategory category) async {
    if (!_customCategories.any((c) => c.name == category.name) &&
        !GoalCategory.predefined.any((c) => c.name == category.name)) {
      _customCategories.add(category);
      await _store.saveCustomCategories(_customCategories);
      notifyListeners();
    }
  }

  Future<void> updateCustomCategory(GoalCategory oldCategory, GoalCategory newCategory) async {
    final index = _customCategories.indexWhere((c) => c.name == oldCategory.name);
    if (index != -1) {
      _customCategories[index] = newCategory;
      await _store.saveCustomCategories(_customCategories);
      notifyListeners();
    }
  }

  Future<void> deleteCustomCategory(GoalCategory category) async {
    _customCategories.removeWhere((c) => c.name == category.name);
    await _store.saveCustomCategories(_customCategories);
    notifyListeners();
  }

  Future<void> unlockPredefinedCategory(String categoryName) async {
    _unlockedPredefinedCategories.add(categoryName);
    await _store.saveUnlockedPredefinedCategories(_unlockedPredefinedCategories);
    notifyListeners();
  }

  Future<void> lockPredefinedCategory(String categoryName) async {
    _unlockedPredefinedCategories.remove(categoryName);
    await _store.saveUnlockedPredefinedCategories(_unlockedPredefinedCategories);
    notifyListeners();
  }

  Future<void> updatePredefinedCategory(GoalCategory oldCategory, GoalCategory newCategory) async {
    for (var i = 0; i < _goals.length; i++) {
      if (_goals[i].category.name == oldCategory.name) {
        _goals[i] = _goals[i].copyWith(category: newCategory);
      }
    }
    await _persistGoals();
    await _store.saveCustomCategories(_customCategories);
    notifyListeners();
  }

  Future<void> resetPredefinedCategories() async {
    _unlockedPredefinedCategories.clear();
    for (var i = 0; i < _goals.length; i++) {
      final defaultCategory = GoalCategory.predefined.where((c) => c.name == _goals[i].category.name).firstOrNull;
      if (defaultCategory != null) {
        _goals[i] = _goals[i].copyWith(category: defaultCategory);
      }
    }
    await _store.saveUnlockedPredefinedCategories(_unlockedPredefinedCategories);
    await _persistGoals();
    notifyListeners();
  }

  Future<void> setAnalyticsDisplay(String value) async {
    analyticsDisplay = value;
    await _store.saveAnalyticsDisplay(value);
    notifyListeners();
  }

  // ── Goal CRUD ───────────────────────────────────────────────────────────

  Future<void> createGoalWithPlan(SavingsGoal goal) async {
    _goals.insert(0, goal);
    await _persistGoals();
    _scheduleGoalNotification(goal);
  }

  Future<void> addGoal(SavingsGoal goal) async {
    _goals.insert(0, goal.ensurePlan());
    await _persistGoals();
    _scheduleGoalNotification(goal.ensurePlan());
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    final updated = goal.ensurePlan();
    _replace(updated);
    await _persistGoals();
    _scheduleGoalNotification(updated);
  }

  /// Add savings to a goal with strict validation:
  /// - Caps deposit at remaining goal amount (never exceed target)
  /// - Clamps progress to 100%
  /// - Prevents additional deposits once goal is completed
  /// - Sets remaining to $0 when goal is fully funded
  Future<void> addSavings(
    SavingsGoal goal,
    double amount, {
    SavingsEntryType entryType = SavingsEntryType.manual,
  }) async {
    try {
      final index = _goals.indexWhere((item) => item.id == goal.id);
      if (index == -1) return;

      final storedGoal = _goals[index];

      // Prevent deposits if goal is already completed
      if (storedGoal.completed) return;

      // Validate amount
      if (amount <= 0 || !amount.isFinite) return;

      // Calculate remaining space — cap deposit to remaining goal amount
      final remaining = (storedGoal.target - storedGoal.saved).clamp(0.0, storedGoal.target);
      final effectiveAmount = amount > remaining ? remaining : amount;
      if (effectiveAmount <= 0) return;

      final newSaved = storedGoal.saved + effectiveAmount;
      // Clamp so saved never exceeds target
      final clampedSaved = newSaved > storedGoal.target ? storedGoal.target : newSaved;
      final completed = clampedSaved >= storedGoal.target;

      final oldPlan = storedGoal.plan;
      final updatedPlan = oldPlan?.recalculate(clampedSaved);

      if (oldPlan != null && updatedPlan != null) {
        final oldInterval = oldPlan.currentIntervalAmount;
        final newInterval = updatedPlan.currentIntervalAmount;
        if ((oldInterval - newInterval).abs() >= 1.0) {
          final adjustment = PlanAdjustment(
            date: DateTime.now(),
            reason: entryType == SavingsEntryType.missed
                ? 'Missed period — interval amount adjusted'
                : effectiveAmount >= oldInterval
                    ? 'On-track deposit — interval amount updated'
                    : 'Under-saved — interval amount increased',
            oldIntervalAmount: oldInterval,
            newIntervalAmount: newInterval,
            intervalsRemaining: SavingsPlanCalculator.calculateIntervalsLeft(
              storedGoal.daysLeft,
              storedGoal.frequency.days,
            ),
            remainingAmount: (storedGoal.target - clampedSaved).clamp(0, storedGoal.target),
          );
          _goals[index] = storedGoal.copyWith(
            saved: clampedSaved,
            paused: false,
            completed: completed,
            plan: updatedPlan.withAdjustment(adjustment),
          );
        } else {
          _goals[index] = storedGoal.copyWith(
            saved: clampedSaved,
            paused: false,
            completed: completed,
            plan: updatedPlan,
          );
        }
      } else {
        _goals[index] = storedGoal.copyWith(
          saved: clampedSaved,
          paused: false,
          completed: completed,
          plan: updatedPlan,
        );
      }

      // Log the actual amount deposited (user-entered, for history accuracy)
      _history.insert(
        0,
        SavingsLog(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          goalId: goal.id,
          goalTitle: goal.title,
          amount: effectiveAmount,
          date: DateTime.now(),
          entryType: entryType,
        ),
      );

      final updatedGoal = _goals[index];
      checkMilestoneCelebration(updatedGoal);
      hasCheckedInToday = true;
      dailyMotivationMessage = DailyMotivation.getMessage(
        streakDays: streakDays,
        activeGoals: allActiveGoals.length,
        disciplineScore: disciplineScore,
        totalSaved: totalSaved,
        completedGoals: allActiveGoals.where((g) => g.completed).length,
        hasCheckedInToday: hasCheckedInToday,
      );

      await _persistGoalsAndHistory();

      awardDepositXp(effectiveAmount);

      if (completed) {
        pendingCompletedGoal = _goals[index];
        PlanNotificationScheduler().cancelGoal(goal.id);
      } else {
        PlanNotificationScheduler().scheduleGoal(
          goal: updatedGoal,
          remindersEnabled: remindersEnabled,
          reminderHour: reminderHour,
          reminderMinute: reminderMinute,
          formatMoney: formatMoney,
        );
        if (updatedGoal.planStatus == PlanStatus.atRisk) {
          PlanNotificationScheduler().scheduleAtRiskAlert(
            goal: updatedGoal,
            remindersEnabled: remindersEnabled,
            formatMoney: formatMoney,
          );
        }
      }
      await evaluateAchievements();
    } catch (e, stackTrace) {
      debugPrint('addSavings error: $e\n$stackTrace');
    }
  }

  Future<void> recalculatePlans() async {
    bool changed = false;
    for (var i = 0; i < _goals.length; i++) {
      if (_goals[i].deleted || _goals[i].archived) continue;
      final recalculated = _goals[i].plan?.recalculate(_goals[i].saved);
      if (recalculated != null && recalculated.currentIntervalAmount != _goals[i].plan?.currentIntervalAmount) {
        _goals[i] = _goals[i].copyWith(plan: recalculated);
        changed = true;
      }
    }
    if (changed) {
      await _persistGoals();
    } else {
      notifyListeners();
    }
    _updateNotifications();
  }

  Future<void> recalculatePlan(SavingsGoal goal) async {
    final index = _goals.indexWhere((item) => item.id == goal.id);
    if (index == -1) return;
    final currentGoal = _goals[index];
    if (currentGoal.deleted || currentGoal.archived || currentGoal.completed) return;
    final lastLog = _history.where((log) => log.goalId == goal.id).fold<DateTime?>(
      null,
      (latest, log) => latest == null || log.date.isAfter(latest) ? log.date : latest,
    );
    final referenceDate = lastLog ?? (currentGoal.createdDate ?? DateTime.now().subtract(const Duration(days: 30)));
    final daysSinceReference = DateTime.now().difference(referenceDate).inDays;
    final intervalsSinceReference = daysSinceReference ~/ currentGoal.frequency.days;
    final maxMissed = 4;
    final missedCount = intervalsSinceReference.clamp(0, maxMissed);
    for (var i = 1; i <= missedCount; i++) {
      final missedDate = referenceDate.add(Duration(days: currentGoal.frequency.days * i));
      final alreadyLogged = _history.any((log) =>
        log.goalId == goal.id &&
        (log.date.difference(missedDate).inDays).abs() <= 1
      );
      if (!alreadyLogged) {
        _history.insert(
          0,
          SavingsLog(
            id: 'missed_${goal.id}_${missedDate.millisecondsSinceEpoch}',
            goalId: goal.id,
            goalTitle: goal.title,
            amount: 0,
            date: missedDate,
            entryType: SavingsEntryType.missed,
            notes: 'Missed period — auto-logged',
          ),
        );
      }
    }
    final updatedPlan = currentGoal.plan?.recalculate(currentGoal.saved);
    if (updatedPlan != null) {
      _goals[index] = currentGoal.copyWith(plan: updatedPlan);
      await _persistGoalsAndHistory();
    } else if (missedCount > 0) {
      await _store.saveHistory(_history);
    }
  }

  SavingsGoal? latestGoal(String goalId) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    return index != -1 ? _goals[index] : null;
  }

  void _scheduleGoalNotification(SavingsGoal goal) {
    PlanNotificationScheduler().scheduleGoal(
      goal: goal,
      remindersEnabled: remindersEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      formatMoney: formatMoney,
    );
  }

  Future<void> deleteSavingsLog(SavingsLog log) async {
    final goalIndex = _goals.indexWhere((g) => g.id == log.goalId);
    if (goalIndex != -1) {
      final goal = _goals[goalIndex];
      final newSaved = (goal.saved - log.amount).clamp(0.0, double.infinity);
      final recalculatedPlan = goal.plan?.recalculate(newSaved);
      _goals[goalIndex] = goal.copyWith(
        saved: newSaved,
        completed: newSaved >= goal.target,
        plan: recalculatedPlan,
      );
    }
    _history.removeWhere((item) => item.id == log.id);
    await _persistGoalsAndHistory();
  }

  Future<void> updateSavingsLog(SavingsLog log, double newAmount) async {
    final goalIndex = _goals.indexWhere((g) => g.id == log.goalId);
    if (goalIndex != -1) {
      final goal = _goals[goalIndex];
      final diff = newAmount - log.amount;
      final newSaved = (goal.saved + diff).clamp(0.0, double.infinity);
      final recalculatedPlan = goal.plan?.recalculate(newSaved);
      _goals[goalIndex] = goal.copyWith(
        saved: newSaved,
        completed: newSaved >= goal.target,
        plan: recalculatedPlan,
      );
    }
    final historyIndex = _history.indexWhere((item) => item.id == log.id);
    if (historyIndex != -1) {
      _history[historyIndex] = _history[historyIndex].copyWith(amount: newAmount);
    }
    await _persistGoalsAndHistory();
  }

  Future<void> togglePaused(SavingsGoal goal) async {
    final updated = goal.copyWith(paused: !goal.paused);
    _replace(updated);
    await _persistGoals();
    if (!goal.paused) {
      _scheduleGoalNotification(updated);
    } else {
      PlanNotificationScheduler().cancelGoal(goal.id);
    }
  }

  Future<void> markCompleted(SavingsGoal goal) async {
    final completedPlan = goal.plan?.copyWith(status: PlanStatus.completed);
    _replace(goal.copyWith(completed: true, paused: false, plan: completedPlan));
    await _persistGoals();
    PlanNotificationScheduler().cancelGoal(goal.id);
  }

  Future<void> deleteGoal(SavingsGoal goal) async {
    _replace(goal.copyWith(deleted: true));
    await _persistGoals();
  }

  Future<void> restoreGoal(SavingsGoal goal) async {
    _replace(goal.copyWith(deleted: false));
    await _persistGoals();
  }

  Future<void> archiveGoal(SavingsGoal goal) async {
    _replace(goal.copyWith(archived: true, paused: true));
    await _persistGoals();
  }

  Future<void> unarchiveGoal(SavingsGoal goal) async {
    _replace(goal.copyWith(archived: false, paused: false));
    await _persistGoals();
  }

  Future<void> resumeGoal(SavingsGoal goal) async {
    _replace(goal.copyWith(paused: false));
    await _persistGoals();
  }

  Future<void> undoCompletion(SavingsGoal goal) async {
    final revertedPlan = goal.plan?.recalculate(goal.saved).copyWith(status: PlanStatus.onTrack);
    _replace(goal.copyWith(completed: false, plan: revertedPlan));
    await _persistGoals();
  }

  // ── Reset Progress ──────────────────────────────────────────────────────

  Future<void> resetAllProgress() async {
    await resetSelectedProgress(ResetFlags()..selectAll());
  }

  Future<void> resetSelectedProgress(ResetFlags flags) async {
    if (!flags.anySelected) return;

    for (final entry in ResetRegistry.entries) {
      if (entry.isSelected(flags)) {
        await entry.execute(this);
      }
    }

    if (flags.goals) {
      _goals.clear();
      await _store.saveGoals(_goals);
    }

    if (flags.history) {
      _history.clear();
      await _store.saveHistory(_history);
    }

    if (flags.budgetAllocations) {
      for (var i = 0; i < _goals.length; i++) {
        _goals[i] = _goals[i].copyWith(clearPlan: true);
      }
      await _persistGoals();
    }

    if (flags.savingsForecasts) {
      range = AnalyticsRange.monthly;
    }

    if (flags.analytics) {
      range = AnalyticsRange.monthly;
      searchQuery = '';
      categoryFilter = null;
      sort = GoalSort.priority;
    }

    if (flags.healthScore) {
      if (!flags.goals && !flags.history && !flags.streak && !flags.xpLevel) {
        _playerLevel = const PlayerLevel();
        await _store.savePlayerLevel(_playerLevel);
      }
    }

    if (flags.recentActivity) {
      if (!flags.history) {
        final count = _history.length;
        final removeCount = count > 50 ? 50 : count;
        if (removeCount > 0) {
          _history.removeRange(0, removeCount);
          await _store.saveHistory(_history);
        }
      }
    }

    if (flags.goalMilestones) {
      celebratedMilestones.clear();
      for (var i = 0; i < _goals.length; i++) {
        _goals[i] = _goals[i].copyWith(completed: false, clearCompletedDate: true);
      }
      await _persistGoals();
      await _store.saveCelebratedMilestones(celebratedMilestones);
    }

    if (flags.milestoneCelebrations) {
      celebratedMilestones.clear();
      await _store.saveCelebratedMilestones(celebratedMilestones);
    }

    if (flags.achievements) {
      achievementBadges = Achievements.all.map((badge) =>
        badge.copyWith(unlocked: false, unlockedDate: null, currentProgress: 0)
      ).toList();
      await _store.saveAchievementBadges(achievementBadges);
    }

    if (flags.xpLevel) {
      _playerLevel = const PlayerLevel();
      await _store.savePlayerLevel(_playerLevel);
    }

    if (flags.streak) {
      if (!flags.history) {
        _history.removeWhere((log) => log.entryType == SavingsEntryType.missed);
        await _store.saveHistory(_history);
      }
    }

    if (flags.dailyMotivation) {
      dailyMotivationMessage = '';
    }

    if (flags.notes) {
      userNotesList.clear();
      userNotes = '';
      await _store.saveNotes(userNotesList);
    }

    if (flags.calendarEvents) {
      _calendarEvents.clear();
      await _store.saveCalendarEvents(_calendarEvents);
    }

    if (flags.profileData) {
      userName = 'User';
      userEmail = '';
      userPhotoUrl = null;
      await _store.saveUserName('User');
      await _store.saveUserEmail('');
      await _store.saveUserPhotoUrl(null);
      try {
        final authService = AuthService();
        final user = await authService.getUser();
        if (user != null) {
          await authService.saveUser(user.copyWith(name: 'User', email: '', photoUrl: null));
        }
      } catch (_) {}
    }

    if (flags.productImages) {
      // Clear product photo URLs from all goals
      for (var i = 0; i < _goals.length; i++) {
        if (_goals[i].productPhotoUrl != null) {
          _goals[i] = _goals[i].copyWith(productPhotoUrl: null);
        }
      }
      await _persistGoals();
    }

    if (flags.dashboardLayout) {
      _visibleCardOrder = List.from(kDefaultCardOrder);
      _hiddenCards = {};
      await _persistDashboardLayout();
      debugPrint('[Controller] Dashboard layout reset to default.');
    }

    if (flags.categories) {
      _customCategories.clear();
      _unlockedPredefinedCategories.clear();
      await _store.saveCustomCategories(_customCategories);
      await _store.saveUnlockedPredefinedCategories(_unlockedPredefinedCategories);
    }

    if (flags.predefinedCategories) {
      _unlockedPredefinedCategories.clear();
      for (var i = 0; i < _goals.length; i++) {
        final defaultCat = GoalCategory.predefined.where((c) => c.name == _goals[i].category.name).firstOrNull;
        if (defaultCat != null) {
          _goals[i] = _goals[i].copyWith(category: defaultCat);
        }
      }
      await _store.saveUnlockedPredefinedCategories(_unlockedPredefinedCategories);
      await _persistGoals();
    }

    if (flags.reminders) {
      remindersEnabled = true;
      reminderHour = 20;
      reminderMinute = 0;
      await _store.saveRemindersEnabled(true);
      await _store.saveReminderHour(20);
      await _store.saveReminderMinute(0);
      try {
        await NotificationService().cancelAllNotifications();
        PlanNotificationScheduler().cancelAll();
      } catch (_) {}
    }

    if (flags.preferences) {
      isDarkMode = true;
      showBalance = true;
      animationsEnabled = true;
      currencyCode = 'PHP';
      analyticsDisplay = 'Balanced dashboard';
      accentColor = const Color(0xFFA8FF3E);
      reminderHour = 20;
      reminderMinute = 0;
      unreadNotificationCount = 0;
      _visibleCardOrder = List.from(kDefaultCardOrder);
      _hiddenCards = {};
      await _store.saveIsDarkMode(true);
      await _store.saveShowBalance(true);
      await _store.saveAnimationsEnabled(true);
      await _store.saveCurrencyCode('PHP');
      await _store.saveAnalyticsDisplay('Balanced dashboard');
      await _store.saveAccentColor(accentColor);
      await _store.saveReminderHour(20);
      await _store.saveReminderMinute(0);
      await _persistDashboardLayout();
    }

    if (!flags.achievements) {
      evaluateAchievements();
    }
    _updateNotifications();
    notifyListeners();
  }

  // ── Persistence Helpers ─────────────────────────────────────────────────

  /// Persist goals and history to the store immediately.
  /// Note: NOT debounced — writes happen synchronously (awaited) so data
  /// is always consistent, especially important for critical CRUD operations.
  Future<void> _persistGoals() async {
    try {
      await _store.saveGoals(_goals);
      notifyListeners();
    } catch (e) {
      debugPrint('Persist goals error: $e');
    }
  }

  Future<void> _persistGoalsAndHistory() async {
    try {
      await _store.saveGoals(_goals);
      await _store.saveHistory(_history);
      notifyListeners();
    } catch (e) {
      debugPrint('Persist error: $e');
    }
  }

  void _replace(SavingsGoal goal) {
    final index = _goals.indexWhere((item) => item.id == goal.id);
    if (index == -1) return;
    _goals[index] = goal;
  }

  /// Register default reset entries for auto-discovery.
  static void registerDefaultResetEntries() {
    ResetRegistry.clear();

    ResetRegistry.register(ResetEntry(
      name: 'Calendar Events',
      isSelected: (f) => f.calendarEvents,
      execute: (ctrl) async {
        ctrl._calendarEvents.clear();
        await ctrl._store.saveCalendarEvents(ctrl._calendarEvents);
      },
    ));

    ResetRegistry.register(ResetEntry(
      name: 'Coach Insights',
      isSelected: (f) => f.coachInsights,
      execute: (ctrl) async {},
    ));

    ResetRegistry.register(ResetEntry(
      name: 'Goal Predictions',
      isSelected: (f) => f.goalPredictions,
      execute: (ctrl) async {},
    ));

    ResetRegistry.register(ResetEntry(
      name: 'Reports',
      isSelected: (f) => f.reports,
      execute: (ctrl) async {},
    ));
  }
}


