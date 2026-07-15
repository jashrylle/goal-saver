import 'dart:math' as math;
import '../models/goal_model.dart' show SavingFrequency, SavingsLog;
import '../models/savings_plan_model.dart' show PlanStatus;

/// Pure-function calculation engine for all savings plan math.
///
/// No Flutter/UI dependencies — fully unit-testable.
/// This is the SINGLE source of truth for all savings calculations.
class SavingsPlanCalculator {
  const SavingsPlanCalculator._();

  /// Singleton instance for convenience when calling static methods.
  static const SavingsPlanCalculator instance = SavingsPlanCalculator._();

  // ── Interval & Duration helpers ──────────────────────────────────────────

  /// Calculate the number of intervals between [start] and [end] at [frequency].
  static int calculateTotalIntervals(
    DateTime start,
    DateTime end,
    SavingFrequency frequency,
  ) {
    final totalDays = end.difference(start).inDays;
    if (totalDays <= 0) return 1;
    return math.max(1, (totalDays / frequency.days).ceil());
  }

  /// Calculate intervals remaining given [daysLeft] and [intervalDays].
  static int calculateIntervalsLeft(int daysLeft, int intervalDays) {
    if (daysLeft <= 0) return 0;
    return math.max(1, (daysLeft / intervalDays).ceil());
  }

  /// How many days from now until [date].
  static int daysUntil(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    return math.max(0, diff);
  }

  /// Base interval amount: target / intervals.
  static double calculateIntervalAmount(double target, int intervals) {
    if (intervals <= 0 || target <= 0) return 0;
    return (target / intervals).ceilToDouble();
  }

  // ── Core formulas ────────────────────────────────────────────────────────

  /// Calculate the current recommended deposit per interval (live).
  ///
  ///   remaining = max(0, target - saved)
  ///   intervalsLeft = ceil(daysLeft / frequency.days)
  ///   currentIntervalAmount = remaining / intervalsLeft
  static double calculateCurrentIntervalAmount({
    required double target,
    required double saved,
    required int daysLeft,
    required int frequencyDays,
  }) {
    if (daysLeft <= 0) return 0;
    final remaining = (target - saved).clamp(0, target);
    if (remaining <= 0) return 0;
    final intervalsLeft = calculateIntervalsLeft(daysLeft, frequencyDays);
    return (remaining / intervalsLeft).ceilToDouble();
  }

  /// Estimate the completion date based on actual average deposit pace from history.
  ///
  /// Uses the past N intervals' average deposit to project forward, rather than
  /// the plan's recommended amount — reflects reality, not the plan.
  static DateTime? estimateCompletionFromHistory({
    required double target,
    required double saved,
    required List<SavingsLog> historyLogs,
    required int frequencyDays,
  }) {
    final remaining = (target - saved).clamp(0, target);
    if (remaining <= 0) return DateTime.now();

    // Calculate average deposit from recent intervals
    final recentLogs = _recentLogsByInterval(historyLogs, frequencyDays);
    if (recentLogs.isEmpty) return null;

    final avgPerInterval =
        recentLogs.fold(0.0, (sum, l) => sum + l.amount) / recentLogs.length;
    if (avgPerInterval <= 0) return null;

    final intervalsNeeded = (remaining / avgPerInterval).ceil();
    final daysNeeded = intervalsNeeded * frequencyDays;
    return DateTime.now().add(Duration(days: daysNeeded));
  }

  /// Estimate completion label: human-readable string.
  static String estimateCompletionLabel(DateTime? estimate) {
    if (estimate == null) return 'Not enough data yet';
    final days = estimate.difference(DateTime.now()).inDays;
    if (days <= 0) return 'Any day now';
    if (days == 1) return 'Tomorrow';
    if (days < 7) return '$days days';
    if (days < 30) return '${(days / 7).ceil()} weeks';
    if (days < 365) return '${(days / 30).ceil()} months';
    return '${(days / 365).ceil()} years';
  }

  /// Progress percentage 0–1.
  static double calculateProgress(double saved, double target) {
    if (target <= 0) return 0;
    return (saved / target).clamp(0, 1);
  }

  /// Remaining amount to save.
  static double calculateRemaining(double saved, double target) {
    return (target - saved).clamp(0, target);
  }

  // ── Plan status detection ────────────────────────────────────────────────

  /// Determine the plan status based on saved amount, target, and days left.
  static PlanStatus determineStatus({
    required double saved,
    required double target,
    required int daysLeft,
    required int frequencyDays,
  }) {
    if (saved >= target) return PlanStatus.completed;
    final intervalsLeft = calculateIntervalsLeft(daysLeft, frequencyDays);
    if (intervalsLeft <= 0 && saved < target) return PlanStatus.atRisk;
    return PlanStatus.onTrack;
  }

  /// Check if the plan is at risk of not completing on time.
  static bool isAtRisk(double saved, double target, int daysLeft, int frequencyDays) {
    return determineStatus(
      saved: saved,
      target: target,
      daysLeft: daysLeft,
      frequencyDays: frequencyDays,
    ) == PlanStatus.atRisk;
  }

  // ── Pacing helpers ──────────────────────────────────────────────────────

  /// Savings needed per day to reach the target by the target date.
  static double savingsPerDay(double remaining, int daysLeft) {
    if (daysLeft <= 0 || remaining <= 0) return 0;
    return (remaining / math.max(1, daysLeft)).ceilToDouble();
  }

  /// Savings needed per week to reach the target by the target date.
  static double savingsPerWeek(double remaining, int daysLeft) {
    if (daysLeft <= 0 || remaining <= 0) return 0;
    final weeksLeft = daysLeft / 7;
    return (remaining / math.max(1, weeksLeft)).ceilToDouble();
  }

  /// Savings needed per month to reach the target by the target date.
  static double savingsPerMonth(double remaining, int daysLeft) {
    if (daysLeft <= 0 || remaining <= 0) return 0;
    final monthsLeft = daysLeft / 30;
    return (remaining / math.max(1, monthsLeft)).ceilToDouble();
  }

  // ── Resolution options for at-risk plans ────────────────────────────────

  /// Suggest a new (realistic) target date that makes the plan achievable at
  /// the current pace.
  static DateTime suggestExtendedTargetDate({
    required double target,
    required double saved,
    required int frequencyDays,
    required double maxIntervalAmount,
  }) {
    final remaining = (target - saved).clamp(0, target);
    final intervalsNeeded = maxIntervalAmount > 0
        ? (remaining / maxIntervalAmount).ceil()
        : 12; // default 12 intervals
    final daysNeeded = intervalsNeeded * frequencyDays;
    return DateTime.now().add(Duration(days: daysNeeded));
  }

  /// Calculate the increased interval amount needed to keep the original target date.
  static double calculateCatchUpIntervalAmount({
    required double target,
    required double saved,
    required int daysLeft,
    required int frequencyDays,
  }) {
    if (daysLeft <= 0) return target - saved; // all at once
    final intervalsLeft = calculateIntervalsLeft(daysLeft, frequencyDays);
    final remaining = (target - saved).clamp(0.0, target);
    if (intervalsLeft <= 0) return remaining;
    return (remaining / intervalsLeft).ceilToDouble();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Get logs from the most recent intervals for pacing calculation.
  static List<SavingsLog> _recentLogsByInterval(
    List<SavingsLog> logs,
    int frequencyDays,
  ) {
    if (logs.isEmpty) return [];
    // Consider up to 4 intervals of history
    final lookbackDays = math.max(7, frequencyDays * 4);
    final cutoff = DateTime.now().subtract(Duration(days: lookbackDays));
    return logs.where((log) => log.date.isAfter(cutoff)).toList();
  }

  // ── PRORATED TARGET FOR ANALYTICS RANGES ─────────────────────────────────

  /// Calculate what a goal's target should be for a given analytics range.
  /// This replaces the ad-hoc prorating currently in the controller.
  static double proratedTargetForRange({
    required double target,
    required double saved,
    required double daysLeft,
    required int frequencyDays,
    required int rangeDays,
  }) {
    final dailyTarget = daysLeft > 0
        ? (target - saved) / daysLeft
        : (target - saved) / 1;
    return saved.clamp(0, target) +
        (dailyTarget * rangeDays).clamp(0, target - saved);
  }
}
