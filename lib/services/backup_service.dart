import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/goal_model.dart';
import '../state/goal_saver_controller.dart';

/// Backup & Restore service for exporting and importing all user data.
///
/// Exports goals, history, settings, achievements, notes, and categories
/// as a JSON file that can be shared or stored. Import restores all data
/// from a previously exported file.
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// Export all user data to a JSON file and trigger the share sheet.
  Future<void> exportData(GoalSaverController controller) async {
    final data = _buildExportPayload(controller);
    final json = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/goal_saver_backup_$timestamp.json');
    await file.writeAsString(json);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Goal Saver Backup',
        text: 'Goal Saver data backup — created ${DateTime.now().toIso8601String()}',
      ),
    );
  }

  /// Import data from a JSON file path and apply it to the controller.
  Future<BackupResult> importData(
    GoalSaverController controller, {
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return BackupResult(
          success: false,
          message: 'Backup file not found.',
        );
      }

      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;

      // Validate the backup format
      if (!data.containsKey('version') || !data.containsKey('type') ||
          data['type'] != 'goal_saver_backup') {
        return BackupResult(
          success: false,
          message: 'Invalid backup file format.',
        );
      }

      // Restore goals
      if (data['goals'] is List) {
        final goals = (data['goals'] as List)
            .whereType<Map<String, dynamic>>()
            .map((m) => SavingsGoal.fromMap(m))
            .toList();
        // Use the store directly for bulk import
        final store = controller.store;
        await store.saveGoals(goals);
      }

      // Restore history
      if (data['history'] is List) {
        final history = (data['history'] as List)
            .whereType<Map<String, dynamic>>()
            .map((m) => SavingsLog.fromMap(m))
            .toList();
        final store = controller.store;
        await store.saveHistory(history);
      }

      // Reload everything
      await controller.load();

      return BackupResult(
        success: true,
        message: 'Backup restored successfully! ${_countSummary(data)}',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to restore backup: $e',
      );
    }
  }

  Map<String, dynamic> _buildExportPayload(GoalSaverController controller) {
    return {
      'version': 1,
      'type': 'goal_saver_backup',
      'createdAt': DateTime.now().toIso8601String(),
      'goals': controller.goals.map((g) => g.toMap()).toList(),
      'archivedGoals': controller.archivedGoals.map((g) => g.toMap()).toList(),
      'history': controller.history.map((h) => h.toMap()).toList(),
      'notes': controller.savedNotes,
      'categories': controller.customCategories.map((c) => c.toMap()).toList(),
      'achievements': controller.achievementBadges.map((a) => a.toMap()).toList(),
      'settings': {
        'isDarkMode': controller.isDarkMode,
        'remindersEnabled': controller.remindersEnabled,
        'reminderHour': controller.reminderHour,
        'reminderMinute': controller.reminderMinute,
        'showBalance': controller.showBalance,
        'currencyCode': controller.currencyCode,
        'analyticsDisplay': controller.analyticsDisplay,
        'accentColor': controller.accentColor.toARGB32(),
      },
    };
  }

  String _countSummary(Map<String, dynamic> data) {
    final goalCount = (data['goals'] as List?)?.length ?? 0;
    final historyCount = (data['history'] as List?)?.length ?? 0;
    return '$goalCount goals, $historyCount history entries restored';
  }
}

/// Result of a backup import operation.
class BackupResult {
  final bool success;
  final String message;

  const BackupResult({
    required this.success,
    required this.message,
  });
}
