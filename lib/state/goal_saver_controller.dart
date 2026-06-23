import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../data/goal_saver_store.dart';
import '../data/seed_data.dart';
import '../utils/extensions.dart';

/// Central state controller for Goal Saver, backed by a [GoalSaverStore].
class GoalSaverController extends ChangeNotifier {
  GoalSaverController(this._store);

  GoalSaverStore _store;
  final List<SavingsGoal> _goals = [];
  final List<SavingsLog> _history = [];
  String searchQuery = '';
  GoalCategory? categoryFilter;
  GoalSort sort = GoalSort.priority;
  AnalyticsRange range = AnalyticsRange.monthly;
  bool isDarkMode = true;
  bool remindersEnabled = true;
  bool showBalance = true;
  String currencyCode = 'PHP';
  String analyticsDisplay = 'Balanced dashboard';
  bool isLoading = true;

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

  double get totalSaved =>
      allActiveGoals.fold(0, (total, goal) => total + goal.saved);

  double get totalTarget =>
      allActiveGoals.fold(0, (total, goal) => total + goal.target);

  double get averageProgress => totalTarget == 0 ? 0 : totalSaved / totalTarget;

  int get streakDays => 18;

  int get disciplineScore {
    final consistency = streakDays / 25;
    final progress = averageProgress.clamp(0, 1);
    final historyScore = (_history.length / 16).clamp(0, 1);
    return ((consistency * .42 + progress * .38 + historyScore * .20) * 100)
        .round();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
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
    notifyListeners();
  }

  void toggleReminders(bool value) {
    remindersEnabled = value;
    notifyListeners();
  }

  void toggleBalanceVisibility() {
    showBalance = !showBalance;
    notifyListeners();
  }

  void setCurrency(String value) {
    currencyCode = value;
    notifyListeners();
  }

  void setAnalyticsDisplay(String value) {
    analyticsDisplay = value;
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

  Future<void> togglePaused(SavingsGoal goal) async {
    _replace(goal.copyWith(paused: !goal.paused));
    await _persist();
  }

  Future<void> markCompleted(SavingsGoal goal) async {
    _replace(
      goal.copyWith(
        saved: goal.target,
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
