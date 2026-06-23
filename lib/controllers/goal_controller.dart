import 'package:goal_saver/models/goal_model.dart';
import 'dart:math' as math;

/// Business logic for goal and savings operations
class GoalController {
  const GoalController();

  /// Get suggested deposit amount for a goal based on frequency and deadline
  static double getSuggestedDeposit(SavingsGoal goal) {
    if (goal.completed || goal.daysLeft <= 0) return 0;
    final remaining = (goal.target - goal.saved).clamp(0, goal.target);
    if (remaining <= 0) return 0;

    final depositsNeeded = math.max(1, goal.daysLeft / goal.frequency.days);
    return (remaining / depositsNeeded).ceilToDouble();
  }

  /// Get milestones for a goal (25%, 50%, 75%, 100%)
  static List<SavingsMilestone> getMilestonesForGoal(
    SavingsGoal goal,
    List<SavingsMilestone> allMilestones,
  ) {
    final goalMilestones = allMilestones
        .where((m) => m.goalId == goal.id)
        .toList();

    // Ensure all 4 milestones exist
    for (final percentage in [25, 50, 75, 100]) {
      if (!goalMilestones.any((m) => m.percentage == percentage)) {
        goalMilestones.add(
          SavingsMilestone(
            id: '${goal.id}_milestone_$percentage',
            goalId: goal.id,
            percentage: percentage,
          ),
        );
      }
    }

    // Sort by percentage
    goalMilestones.sort((a, b) => a.percentage.compareTo(b.percentage));

    // Update milestone reached status based on progress
    final updatedMilestones = goalMilestones.map((m) {
      final progressPercent = (goal.progress * 100).round();
      final isNowReached = progressPercent >= m.percentage;
      final wasReached = m.isReached;

      if (isNowReached && !wasReached) {
        // Milestone just reached
        return m.copyWith(reachedDate: DateTime.now());
      } else if (!isNowReached && wasReached) {
        // Milestone was reached but progress went down (edit/delete scenario)
        return m.copyWith(clearReachedDate: true);
      }
      return m;
    }).toList();

    return updatedMilestones;
  }

  /// Get all milestones that have been reached for a goal
  static List<SavingsMilestone> getReachedMilestones(
    SavingsGoal goal,
    List<SavingsMilestone> allMilestones,
  ) {
    final milestones = getMilestonesForGoal(goal, allMilestones);
    return milestones.where((m) => m.isReached).toList();
  }

  /// Calculate total money needed across all active goals
  static double getTotalMoneyNeeded(List<SavingsGoal> goals) {
    return goals
        .where((g) => !g.completed && !g.archived && !g.deleted)
        .fold<double>(0, (sum, goal) => sum + goal.moneyNeeded);
  }

  /// Calculate total money saved across all goals
  static double getTotalSaved(List<SavingsGoal> goals) {
    return goals.fold<double>(0, (sum, goal) => sum + goal.saved);
  }

  /// Get completion rate for a list of goals
  static double getCompletionRate(List<SavingsGoal> goals) {
    if (goals.isEmpty) return 0;
    final completed = goals.where((g) => g.completed).length;
    return completed / goals.length;
  }

  /// Calculate average savings per day across all goals
  static double getAverageSavingsPerDay(List<SavingsGoal> goals) {
    if (goals.isEmpty) return 0;
    final totalSaved = getTotalSaved(goals);
    final oldestGoal = goals.reduce((a, b) {
      final aDate = a.createdDate ?? DateTime.now();
      final bDate = b.createdDate ?? DateTime.now();
      return aDate.isBefore(bDate) ? a : b;
    });
    final daysSinceStart =
        DateTime.now().difference(oldestGoal.createdDate ?? DateTime.now()).inDays + 1;
    return totalSaved / math.max(1, daysSinceStart);
  }

  /// Get goals grouped by category
  static Map<GoalCategory, List<SavingsGoal>> getGoalsByCategory(
    List<SavingsGoal> goals,
  ) {
    final grouped = <GoalCategory, List<SavingsGoal>>{};
    for (final goal in goals) {
      if (!grouped.containsKey(goal.category)) {
        grouped[goal.category] = [];
      }
      grouped[goal.category]!.add(goal);
    }
    return grouped;
  }

  /// Get active goals (not completed, paused, archived, or deleted)
  static List<SavingsGoal> getActiveGoals(List<SavingsGoal> goals) {
    return goals
        .where(
          (g) => !g.completed && !g.paused && !g.archived && !g.deleted,
        )
        .toList();
  }

  /// Get goals that are overdue
  static List<SavingsGoal> getOverdueGoals(List<SavingsGoal> goals) {
    return goals.where((g) => g.isOverdue).toList();
  }

  /// Create milestones for a new goal
  static List<SavingsMilestone> createMilestonesForGoal(String goalId) {
    final milestones = <SavingsMilestone>[];
    for (final percentage in [25, 50, 75, 100]) {
      milestones.add(
        SavingsMilestone(
          id: '${goalId}_milestone_$percentage',
          goalId: goalId,
          percentage: percentage,
        ),
      );
    }
    return milestones;
  }
}
