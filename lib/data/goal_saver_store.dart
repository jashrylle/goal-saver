import '../models/goal_model.dart';

/// Abstract persistence interface for goals and savings history.
abstract class GoalSaverStore {
  Future<List<SavingsGoal>> loadGoals();
  Future<void> saveGoals(List<SavingsGoal> goals);
  Future<List<SavingsLog>> loadHistory();
  Future<void> saveHistory(List<SavingsLog> history);
}
