import 'package:hive/hive.dart';
import '../models/goal_model.dart';
import 'goal_saver_store.dart';

/// Hive-backed persistent store.
class HiveGoalSaverStore implements GoalSaverStore {
  late final Box<dynamic> _box;

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>('goal_saver_local_store');
  }

  @override
  Future<List<SavingsGoal>> loadGoals() async {
    final raw = _box.get('goals');
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => SavingsGoal.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<void> saveGoals(List<SavingsGoal> goals) async {
    await _box.put('goals', goals.map((goal) => goal.toMap()).toList());
  }

  @override
  Future<List<SavingsLog>> loadHistory() async {
    final raw = _box.get('history');
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => SavingsLog.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<void> saveHistory(List<SavingsLog> history) async {
    await _box.put('history', history.map((log) => log.toMap()).toList());
  }
}
