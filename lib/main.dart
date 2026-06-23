import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'app.dart';
import 'data/hive_store.dart';
import 'data/memory_store.dart';
import 'state/goal_saver_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Start immediately with in-memory store so the UI appears without delay.
  // Hive is initialised in the background; the controller swaps stores once ready.
  final controller = GoalSaverController(MemoryGoalSaverStore())..load();
  runApp(GoalSaverApp(controller: controller));
  _initHive(controller);
}

Future<void> _initHive(GoalSaverController controller) async {
  try {
    Hive.init('goal_saver_hive');
    final store = HiveGoalSaverStore();
    await store.init();
    await controller.switchStore(store);
  } catch (_) {
    // Keep using the in-memory store if Hive fails.
  }
}
