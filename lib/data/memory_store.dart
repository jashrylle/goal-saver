import '../models/goal_model.dart';
import 'goal_saver_store.dart';
import 'seed_data.dart';

/// In-memory store — uses seed data, no disk writes persist across restarts.
/// Used as the initial store until Hive is ready.
class MemoryGoalSaverStore implements GoalSaverStore {
  List<SavingsGoal> _goals = seedGoals;
  List<SavingsLog> _history = seedHistory;

  @override
  Future<List<SavingsGoal>> loadGoals() async => _goals;

  @override
  Future<void> saveGoals(List<SavingsGoal> goals) async {
    _goals = List.of(goals);
  }

  @override
  Future<List<SavingsLog>> loadHistory() async => _history;

  @override
  Future<void> saveHistory(List<SavingsLog> history) async {
    _history = List.of(history);
  }
}
