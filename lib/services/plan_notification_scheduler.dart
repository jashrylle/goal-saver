import '../models/goal_model.dart';
import '../models/savings_plan_model.dart' show PlanStatus;
import 'notification_service.dart';

/// Frequency-aware notification scheduler for per-goal reminders.
///
/// Wraps [NotificationService] to schedule reminders aligned to each goal's
/// [SavingFrequency], with action buttons for the reminder response loop.
class PlanNotificationScheduler {
  PlanNotificationScheduler._();
  static final PlanNotificationScheduler _instance = PlanNotificationScheduler._();
  factory PlanNotificationScheduler() => _instance;

  /// Schedule or update the notification for a single goal.
  void scheduleGoal({
    required SavingsGoal goal,
    required bool remindersEnabled,
    required int reminderHour,
    required int reminderMinute,
    required String formatMoney(double value),
  }) {
    if (!remindersEnabled || goal.paused || goal.completed || goal.deleted || goal.archived) {
      cancelGoal(goal.id);
      return;
    }

    final intervalAmount = goal.recommendedDeposit;
    if (intervalAmount <= 0) {
      cancelGoal(goal.id);
      return;
    }

    final title = 'Save for ${goal.title}!';
    final body = 'Save ${formatMoney(intervalAmount)} this ${goal.frequency.label.toLowerCase()} to stay on track for ${goal.title}';

    final id = _goalId(goal.id);

    // Use the notification service with frequency-aware scheduling
    NotificationService().scheduleFrequencyAware(
      id: id,
      title: title,
      body: body,
      hour: reminderHour,
      minute: reminderMinute,
      frequencyDays: goal.frequency.days,
    );
  }

  /// Schedule an at-risk alert notification for a goal.
  void scheduleAtRiskAlert({
    required SavingsGoal goal,
    required bool remindersEnabled,
    required String formatMoney(double value),
  }) {
    if (!remindersEnabled) return;
    final id = _atRiskId(goal.id);
    NotificationService().scheduleOneOff(
      id: id,
      title: '⚠️ ${goal.title} is behind schedule!',
      body: 'You need to save ${formatMoney(goal.recommendedDeposit)} this ${goal.frequency.label.toLowerCase()} to stay on track.',
      delayMinutes: 30,
    );
  }

  /// Cancel all notifications for a goal (regular + at-risk).
  void cancelGoal(String goalId) {
    NotificationService().cancelNotification(_goalId(goalId));
    NotificationService().cancelNotification(_atRiskId(goalId));
  }

  /// Cancel all goal notifications (but keep system notifications).
  void cancelAllGoalNotifications(List<SavingsGoal> goals) {
    for (final goal in goals) {
      cancelGoal(goal.id);
    }
  }

  /// Stable numeric ID for a goal's regular reminder notification.
  static int _goalId(String goalId) => goalId.hashCode.abs() % 100000;

  /// Stable numeric ID for a goal's at-risk alert notification.
  static int _atRiskId(String goalId) => _goalId(goalId) + 500000;

  /// Stable numeric ID for the old global reminder (for cleanup).
  static const int globalReminderId = 999;
}
