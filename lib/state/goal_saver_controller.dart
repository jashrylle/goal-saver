import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/goal_model.dart';
import '../models/user_model.dart';
import '../data/goal_saver_store.dart';
import '../data/seed_data.dart';
import '../utils/extensions.dart';
import '../services/notification_service.dart';

/// Central state controller for Goal Saver, backed by a [GoalSaverStore].
class GoalSaverController extends ChangeNotifier {
  GoalSaverController(this._store);

  GoalSaverStore _store;
  final _storage = const FlutterSecureStorage();
  final List<SavingsGoal> _goals = [];
  final List<SavingsLog> _history = [];
  final List<GoalCategory> _customCategories = [];
  final List<CalendarEvent> _calendarEvents = [];
  String searchQuery = '';
  GoalCategory? categoryFilter;
  GoalSort sort = GoalSort.priority;
  AnalyticsRange range = AnalyticsRange.monthly;
  bool isDarkMode = true;
  bool remindersEnabled = true;
  int reminderHour = 20;
  int reminderMinute = 0;
  bool showBalance = true;
  String currencyCode = 'PHP';
  String analyticsDisplay = 'Balanced dashboard';
  bool isLoading = true;
  String userName = 'User';
  String userEmail = '';
  String? userPhotoUrl;
  String userNotes = '';
  List<Map<String, dynamic>> userNotesList = [];

  String get currencySymbol => const {
    'PHP': '₱',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
  }[currencyCode] ?? '₱';

  String formatMoney(double value) {
    return '$currencySymbol${value.money}';
  }

  // ── Computed getters ──────────────────────────────────────────────────────

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

  /// All custom categories (user-created, not predefined)
  List<GoalCategory> get customCategories => List.unmodifiable(_customCategories);

  /// All available categories (predefined + custom)
  List<GoalCategory> get allCategories => [...GoalCategory.predefined, ..._customCategories];

  double get totalSaved =>
      allActiveGoals.fold(0, (total, goal) => total + goal.saved);

  double get totalTarget =>
      allActiveGoals.fold(0, (total, goal) => total + goal.target);

  double get averageProgress => totalTarget == 0 ? 0 : totalSaved / totalTarget;

  int get streakDays {
    if (_history.isEmpty) return 0;
    // Count consecutive days with savings logs going backwards from today
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
        break; // Break on first day with no activity
      }
    }
    return streak;
  }

  int get disciplineScore {
    final consistency = streakDays / 25;
    final progress = averageProgress.clamp(0, 1);
    final historyScore = (_history.length / 16).clamp(0, 1);
    return ((consistency * .42 + progress * .38 + historyScore * .20) * 100)
        .round();
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
    // Use actual target amounts from goals that are due within the selected range
    // or prorate based on what should be saved in this period
    double total = 0.0;
    for (final goal in allActiveGoals) {
      final savedSoFar = goal.saved;
      final remaining = goal.remaining;
      final daysLeft = goal.daysLeft;
      
      // If no days left or completed, include the full remaining target
      if (daysLeft <= 0 || goal.completed) {
        total += savedSoFar;
        continue;
      }
      
      // Prorate based on the selected range vs total time
      final rangeDays = switch (range) {
        AnalyticsRange.daily => 1,
        AnalyticsRange.weekly => 7,
        AnalyticsRange.monthly => 30,
        AnalyticsRange.yearly => 365,
      };
      
      final dailyTarget = remaining / daysLeft;
      total += savedSoFar.clamp(0, goal.target) + (dailyTarget * rangeDays).clamp(0, goal.target - savedSoFar);
    }
    return total == 0 ? totalSaved : total;
  }

  List<Map<String, dynamic>> get weeklyContributions {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));
    
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <Map<String, dynamic>>[];
    
    for (var i = 0; i < 7; i++) {
      final dayDate = startOfWeek.add(Duration(days: i));
      final totalForDay = _history
          .where((log) => log.date.day == dayDate.day && log.date.month == dayDate.month && log.date.year == dayDate.year)
          .fold<double>(0.0, (sum, log) => sum + log.amount);
      
      result.add({
        'label': days[i],
        'value': totalForDay,
      });
    }
    return result;
  }

  List<Map<String, dynamic>> get monthlySavingsData {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (var i = 5; i >= 0; i--) {
      // Calculate the target month/year, handling year rollover properly
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
          
      result.add({
        'month': '$monthName ${targetDate.year}',
        'amount': totalInMonth,
      });
    }
    return result;
  }

  String _getMonthName(int month) {
    return const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][month - 1];
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await AuthService().getUser();
      if (user != null) {
        userName = user.name;
        userEmail = user.email;
        userPhotoUrl = user.photoUrl;
      }
    } catch (_) {}

    try {
      final darkVal = await _storage.read(key: 'settings_isDarkMode');
      if (darkVal != null) isDarkMode = darkVal == 'true';

      final remindersVal = await _storage.read(key: 'settings_remindersEnabled');
      if (remindersVal != null) remindersEnabled = remindersVal == 'true';

      final reminderHourVal = await _storage.read(key: 'settings_reminderHour');
      if (reminderHourVal != null) reminderHour = int.tryParse(reminderHourVal) ?? 20;

      final reminderMinuteVal = await _storage.read(key: 'settings_reminderMinute');
      if (reminderMinuteVal != null) reminderMinute = int.tryParse(reminderMinuteVal) ?? 0;

      final showBalanceVal = await _storage.read(key: 'settings_showBalance');
      if (showBalanceVal != null) showBalance = showBalanceVal == 'true';

      final currencyVal = await _storage.read(key: 'settings_currencyCode');
      if (currencyVal != null) currencyCode = currencyVal;

      final displayVal = await _storage.read(key: 'settings_analyticsDisplay');
      if (displayVal != null) analyticsDisplay = displayVal;

      final notesVal = await _storage.read(key: 'settings_userNotes');
      if (notesVal != null) userNotes = notesVal;

      await _loadNotes();

      // Load calendar events
      final eventsJson = await _storage.read(key: 'settings_calendarEvents');
      if (eventsJson != null) {
        try {
          final decoded = json.decode(eventsJson) as List<dynamic>;
          _calendarEvents
            ..clear()
            ..addAll(decoded
                .cast<Map<String, dynamic>>()
                .map(CalendarEvent.fromMap)
                .toList());
        } catch (_) {}
      }

      // Load custom categories
      final categoriesJson = await _storage.read(key: 'settings_customCategories');
      if (categoriesJson != null) {
        try {
          final decoded = json.decode(categoriesJson) as List<dynamic>;
          _customCategories
            ..clear()
            ..addAll(decoded
                .cast<Map<String, dynamic>>()
                .map(GoalCategory.fromMap)
                .toList());
        } catch (_) {}
      }

      _updateNotifications();
    } catch (_) {}

    final savedGoals = await _store.loadGoals();
    final savedHistory = await _store.loadHistory();
    _goals
      ..clear()
      ..addAll(savedGoals.isEmpty ? seedGoals : savedGoals);
    _history
      ..clear()
      ..addAll(savedHistory.isEmpty ? seedHistory : savedHistory);
    isLoading = false;
    notifyListeners();
  }

  void _updateNotifications() {
    try {
      if (remindersEnabled) {
        NotificationService().scheduleDailyReminder(
          id: 999,
          title: 'Time to Save!',
          body: "Don't forget to record your savings and reach your goals today!",
          hour: reminderHour,
          minute: reminderMinute,
        );
      } else {
        NotificationService().cancelNotification(999);
      }
    } catch (_) {}
  }

  // ── User Notes ───────────────────────────────────────────────────────────

  Future<void> updateUserNotes(String notes) async {
    userNotes = notes;
    await _storage.write(key: 'settings_userNotes', value: notes);
    notifyListeners();
  }

  /// Get all saved notes.
  List<Map<String, dynamic>> get savedNotes => List.unmodifiable(userNotesList);

  /// Add a new note.
  Future<void> addNote(String content) async {
    if (content.trim().isEmpty) return;
    userNotesList.insert(0, {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'content': content.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _persistNotes();
  }

  /// Update an existing note.
  Future<void> updateNote(String id, String newContent) async {
    final index = userNotesList.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      userNotesList[index]['content'] = newContent.trim();
      userNotesList[index]['updatedAt'] = DateTime.now().toIso8601String();
      await _persistNotes();
    }
  }

  /// Delete a note.
  Future<void> deleteNote(String id) async {
    userNotesList.removeWhere((n) => n['id'] == id);
    await _persistNotes();
  }

  Future<void> _persistNotes() async {
    final encoded = json.encode(userNotesList);
    await _storage.write(key: 'settings_userNotesList', value: encoded);
    notifyListeners();
  }

  Future<void> _loadNotes() async {
    try {
      final notesJson = await _storage.read(key: 'settings_userNotesList');
      if (notesJson != null) {
        final decoded = json.decode(notesJson) as List<dynamic>;
        userNotesList = decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
  }

  /// Swaps the backing store (e.g. from in-memory to Hive once it's ready).
  /// Persists whatever is currently in memory, then reloads from the new store.
  Future<void> switchStore(GoalSaverStore newStore) async {
    await newStore.saveGoals(List.of(_goals));
    await newStore.saveHistory(List.of(_history));
    _store = newStore;
    await load();
  }

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    isLoading = false;
    notifyListeners();
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
    await _persistCalendarEvents();
  }

  Future<void> updateCalendarEvent(CalendarEvent event) async {
    final index = _calendarEvents.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _calendarEvents[index] = event;
      await _persistCalendarEvents();
    }
  }

  Future<void> deleteCalendarEvent(CalendarEvent event) async {
    _calendarEvents.removeWhere((e) => e.id == event.id);
    await _persistCalendarEvents();
  }

  Future<void> _persistCalendarEvents() async {
    final encoded = json.encode(_calendarEvents.map((e) => e.toMap()).toList());
    await _storage.write(key: 'settings_calendarEvents', value: encoded);
    notifyListeners();
  }

  // ── Reminder Time ───────────────────────────────────────────────────────

  Future<void> setReminderTime(int hour, int minute) async {
    reminderHour = hour;
    reminderMinute = minute;
    await _storage.write(key: 'settings_reminderHour', value: hour.toString());
    await _storage.write(key: 'settings_reminderMinute', value: minute.toString());
    _updateNotifications();
    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────────────────────

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

  void toggleTheme(bool value) {
    isDarkMode = value;
    _storage.write(key: 'settings_isDarkMode', value: value.toString());
    notifyListeners();
  }

  void toggleReminders(bool value) {
    remindersEnabled = value;
    _storage.write(key: 'settings_remindersEnabled', value: value.toString());
    _updateNotifications();
    notifyListeners();
  }

  void toggleBalanceVisibility() {
    showBalance = !showBalance;
    _storage.write(key: 'settings_showBalance', value: showBalance.toString());
    notifyListeners();
  }

  void setShowBalance(bool value) {
    showBalance = value;
    _storage.write(key: 'settings_showBalance', value: showBalance.toString());
    notifyListeners();
  }

  void setCurrency(String value) {
    currencyCode = value;
    _storage.write(key: 'settings_currencyCode', value: value);
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    userName = name;
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
    try {
      final authService = AuthService();
      final user = await authService.getUser();
      if (user != null) {
        await authService.saveUser(user.copyWith(
          name: name,
          email: email,
          photoUrl: photoUrl,
        ));
      } else {
        await authService.saveUser(UserModel(
          id: 'user_1',
          name: name,
          email: email,
          photoUrl: photoUrl,
          createdAt: DateTime.now(),
          isLoggedIn: true,
        ));
      }
    } catch (_) {}
    notifyListeners();
  }

  // ── Custom Categories ─────────────────────────────────────────────────────

  Future<void> addCustomCategory(GoalCategory category) async {
    if (!_customCategories.any((c) => c.name == category.name)) {
      _customCategories.add(category);
      await _persistCategories();
    }
  }

  Future<void> updateCustomCategory(GoalCategory oldCategory, GoalCategory newCategory) async {
    final index = _customCategories.indexWhere((c) => c.name == oldCategory.name);
    if (index != -1) {
      _customCategories[index] = newCategory;
      await _persistCategories();
    }
  }

  Future<void> deleteCustomCategory(GoalCategory category) async {
    _customCategories.removeWhere((c) => c.name == category.name);
    await _persistCategories();
  }

  Future<void> _persistCategories() async {
    final encoded = json.encode(_customCategories.map((c) => c.toMap()).toList());
    await _storage.write(key: 'settings_customCategories', value: encoded);
    notifyListeners();
  }

  void setAnalyticsDisplay(String value) {
    analyticsDisplay = value;
    _storage.write(key: 'settings_analyticsDisplay', value: value);
    notifyListeners();
  }

  // ── Goal CRUD ─────────────────────────────────────────────────────────────

  Future<void> addGoal(SavingsGoal goal) async {
    _goals.insert(0, goal);
    await _persist();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    _replace(goal);
    await _persist();
  }

  Future<void> addSavings(SavingsGoal goal, double amount) async {
    final index = _goals.indexWhere((item) => item.id == goal.id);
    if (index == -1) return;
    _goals[index] = goal.copyWith(
      saved: (goal.saved + amount).clamp(0, goal.target),
      paused: false,
      completed: goal.saved + amount >= goal.target,
    );
    _history.insert(
      0,
      SavingsLog(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        goalId: goal.id,
        goalTitle: goal.title,
        amount: amount,
        date: DateTime.now(),
      ),
    );
    await _persist();
  }

  Future<void> deleteSavingsLog(SavingsLog log) async {
    final goalIndex = _goals.indexWhere((g) => g.id == log.goalId);
    if (goalIndex != -1) {
      final goal = _goals[goalIndex];
      final newSaved = (goal.saved - log.amount).clamp(0.0, goal.target);
      _goals[goalIndex] = goal.copyWith(
        saved: newSaved,
        completed: newSaved >= goal.target,
      );
    }
    _history.removeWhere((item) => item.id == log.id);
    await _persist();
  }

  Future<void> updateSavingsLog(SavingsLog log, double newAmount) async {
    final goalIndex = _goals.indexWhere((g) => g.id == log.goalId);
    if (goalIndex != -1) {
      final goal = _goals[goalIndex];
      final diff = newAmount - log.amount;
      final newSaved = (goal.saved + diff).clamp(0.0, goal.target);
      _goals[goalIndex] = goal.copyWith(
        saved: newSaved,
        completed: newSaved >= goal.target,
      );
    }
    final historyIndex = _history.indexWhere((item) => item.id == log.id);
    if (historyIndex != -1) {
      _history[historyIndex] = _history[historyIndex].copyWith(
        amount: newAmount,
      );
    }
    await _persist();
  }

  Future<void> togglePaused(SavingsGoal goal) async {
    _replace(goal.copyWith(paused: !goal.paused));
    await _persist();
  }

  Future<void> markCompleted(SavingsGoal goal) async {
    _replace(
      goal.copyWith(
        completed: true,
        paused: false,
      ),
    );
    await _persist();
  }

  Future<void> deleteGoal(SavingsGoal goal) async {
    _replace(goal.copyWith(deleted: true));
    await _persist();
  }

  Future<void> restoreGoal(SavingsGoal goal) async {
    _replace(goal.copyWith(deleted: false));
    await _persist();
  }

  Future<void> archiveGoal(SavingsGoal goal) async {
    _replace(goal.copyWith(archived: true, paused: true));
    await _persist();
  }

  Future<void> unarchiveGoal(SavingsGoal goal) async {
    _replace(goal.copyWith(archived: false, paused: false));
    await _persist();
  }

  Future<void> resumeGoal(SavingsGoal goal) async {
    _replace(goal.copyWith(paused: false));
    await _persist();
  }

  Future<void> undoCompletion(SavingsGoal goal) async {
    _replace(goal.copyWith(completed: false));
    await _persist();
  }

  void _replace(SavingsGoal goal) {
    final index = _goals.indexWhere((item) => item.id == goal.id);
    if (index == -1) return;
    _goals[index] = goal;
  }

  Future<void> _persist() async {
    await _store.saveGoals(_goals);
    await _store.saveHistory(_history);
    notifyListeners();
  }
}

/// Convenience extension to read GoalSaverController from context.
extension GoalSaverControllerX on BuildContext {
  GoalSaverController get controller => read<GoalSaverController>();
}
