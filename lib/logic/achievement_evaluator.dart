import '../models/achievement_model.dart';
import '../models/goal_model.dart' show SavingsGoal, SavingsLog;

/// Pure functions that compute live progress for each achievement badge type.
///
/// Takes a snapshot of the controller's current data so evaluation can be called
/// from any context without coupling to the controller itself.
class AchievementEvaluator {
  /// Compute the current progress for a single [badge] given live data.
  static int progressFor(
    AchievementBadge badge,
    AchievementSnapshot snapshot,
  ) {
    return switch (badge.type) {
      AchievementType.milestone => _milestoneProgress(badge, snapshot),
      AchievementType.streak => _streakProgress(badge, snapshot),
      AchievementType.savings => _savingsProgress(badge, snapshot),
      AchievementType.completion => _completionProgress(badge, snapshot),
      AchievementType.discipline => _disciplineProgress(badge, snapshot),
      AchievementType.social => badge.unlocked ? badge.requirement : 0,
    };
  }

  /// Progress as a fraction 0.0–1.0.
  static double progressPercentFor(
    AchievementBadge badge,
    AchievementSnapshot snapshot,
  ) {
    final current = progressFor(badge, snapshot);
    return (current / badge.requirement).clamp(0.0, 1.0);
  }

  /// Whether the badge should now be considered unlocked.
  static bool isUnlocked(
    AchievementBadge badge,
    AchievementSnapshot snapshot,
  ) {
    if (badge.unlocked) return true;
    return progressFor(badge, snapshot) >= badge.requirement;
  }

  /// Evaluate all predefined badges and return a list with updated progress.
  static List<AchievementBadge> evaluateAll(
    AchievementSnapshot snapshot,
    List<AchievementBadge> existingBadges,
  ) {
    return Achievements.all.map((template) {
      final existing =
          existingBadges.where((b) => b.id == template.id).firstOrNull;
      final currentProgress = progressFor(template, snapshot);
      final shouldUnlock = isUnlocked(template, snapshot);
      final alreadyUnlocked = existing?.unlocked ?? false;

      return template.copyWith(
        unlocked: alreadyUnlocked || shouldUnlock,
        unlockedDate: alreadyUnlocked
            ? (existing!.unlockedDate ?? DateTime.now())
            : shouldUnlock
                ? DateTime.now()
                : null,
        currentProgress: currentProgress,
      );
    }).toList();
  }

  /// Get only newly unlocked badges (for toast celebrations).
  static List<AchievementBadge> getNewlyUnlocked(
    AchievementSnapshot snapshot,
    List<AchievementBadge> existingBadges,
  ) {
    return Achievements.all
        .where((template) {
          final existing =
              existingBadges.where((b) => b.id == template.id).firstOrNull;
          if (existing?.unlocked ?? false) return false;
          return isUnlocked(template, snapshot);
        })
        .map((template) => template.copyWith(
              unlocked: true,
              unlockedDate: DateTime.now(),
              currentProgress: progressFor(template, snapshot),
            ))
        .toList();
  }

  /// Count newly unlocked badges from a list of all evaluated badges.
  static int countNewlyUnlocked(List<AchievementBadge> previous, List<AchievementBadge> current) {
    int count = 0;
    for (final cur in current) {
      if (!cur.unlocked) continue;
      final prev = previous.where((b) => b.id == cur.id).firstOrNull;
      if (prev == null || !prev.unlocked) count++;
    }
    return count;
  }

  // ── Per-type computation ──────────────────────────────────────────────────

  static int _milestoneProgress(AchievementBadge badge, AchievementSnapshot s) {
    // Milestone: count of active goals
    return s.activeGoalCount.clamp(0, badge.requirement);
  }

  static int _streakProgress(AchievementBadge badge, AchievementSnapshot s) {
    // Streak: current saving streak days
    return s.streakDays.clamp(0, badge.requirement);
  }

  static int _savingsProgress(AchievementBadge badge, AchievementSnapshot s) {
    // Savings: total saved across all goals
    return s.totalSaved.toInt().clamp(0, badge.requirement);
  }

  static int _completionProgress(AchievementBadge badge, AchievementSnapshot s) {
    // Completion: count of completed goals
    return s.completedGoalCount.clamp(0, badge.requirement);
  }

  static int _disciplineProgress(AchievementBadge badge, AchievementSnapshot s) {
    // Discipline: discipline score
    return s.disciplineScore.clamp(0, badge.requirement);
  }

}

/// Immutable snapshot of controller data for achievement evaluation.
///
/// Created once per evaluation cycle to ensure consistency across all badges.
class AchievementSnapshot {
  final int activeGoalCount;
  final int completedGoalCount;
  final int streakDays;
  final int disciplineScore;
  final double totalSaved;
  final List<SavingsGoal> goals;
  final List<SavingsLog> history;

  const AchievementSnapshot({
    required this.activeGoalCount,
    required this.completedGoalCount,
    required this.streakDays,
    required this.disciplineScore,
    required this.totalSaved,
    this.goals = const [],
    this.history = const [],
  });
}
