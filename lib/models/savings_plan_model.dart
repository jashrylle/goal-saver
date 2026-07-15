import '../logic/savings_plan_calculator.dart';
import 'goal_model.dart';

/// Represents the explicit savings plan for a goal — the single source of truth
/// for how much to save per interval and when the goal is due.
class SavingsPlan {
  final DateTime startDate;
  final DateTime targetDate;
  final SavingFrequency frequency;
  final double targetAmount;
  final double baseIntervalAmount;
  final double currentIntervalAmount;
  final int totalIntervals;
  final PlanStatus status;
  final List<PlanAdjustment> adjustmentHistory;

  const SavingsPlan({
    required this.startDate,
    required this.targetDate,
    required this.frequency,
    required this.targetAmount,
    required this.baseIntervalAmount,
    required this.currentIntervalAmount,
    required this.totalIntervals,
    this.status = PlanStatus.onTrack,
    this.adjustmentHistory = const [],
  });

  /// Create a fresh plan from scratch using the calculator.
  factory SavingsPlan.create({
    required DateTime startDate,
    required DateTime targetDate,
    required SavingFrequency frequency,
    required double targetAmount,
  }) {
    final totalIntervals =
        SavingsPlanCalculator.calculateTotalIntervals(startDate, targetDate, frequency);
    final baseIntervalAmount =
        SavingsPlanCalculator.calculateIntervalAmount(targetAmount, totalIntervals);
    return SavingsPlan(
      startDate: startDate,
      targetDate: targetDate,
      frequency: frequency,
      targetAmount: targetAmount,
      baseIntervalAmount: baseIntervalAmount,
      currentIntervalAmount: baseIntervalAmount,
      totalIntervals: totalIntervals,
    );
  }

  /// Recalculate the current interval amount based on remaining time and saved amount.
  SavingsPlan recalculate(double saved) {
    final remaining = (targetAmount - saved).clamp(0.0, targetAmount);
    final daysLeft = SavingsPlanCalculator.daysUntil(targetDate);
    final intervalsLeft =
        SavingsPlanCalculator.calculateIntervalsLeft(daysLeft, frequency.days);

    final newIntervalAmount = intervalsLeft > 0 && remaining > 0
        ? SavingsPlanCalculator.calculateIntervalAmount(remaining, intervalsLeft)
        : currentIntervalAmount;

    final newStatus = intervalsLeft <= 0 && remaining > 0
        ? PlanStatus.atRisk
        : remaining <= 0
            ? PlanStatus.completed
            : PlanStatus.onTrack;

    return SavingsPlan(
      startDate: startDate,
      targetDate: targetDate,
      frequency: frequency,
      targetAmount: targetAmount,
      baseIntervalAmount: baseIntervalAmount,
      currentIntervalAmount: newIntervalAmount,
      totalIntervals: totalIntervals,
      status: newStatus,
      adjustmentHistory: adjustmentHistory,
    );
  }

  /// Add an adjustment record when the interval amount changes significantly.
  SavingsPlan withAdjustment(PlanAdjustment adjustment) {
    return copyWith(
      adjustmentHistory: [...adjustmentHistory, adjustment],
    );
  }

  SavingsPlan copyWith({
    DateTime? startDate,
    DateTime? targetDate,
    SavingFrequency? frequency,
    double? targetAmount,
    double? baseIntervalAmount,
    double? currentIntervalAmount,
    int? totalIntervals,
    PlanStatus? status,
    List<PlanAdjustment>? adjustmentHistory,
  }) {
    return SavingsPlan(
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      frequency: frequency ?? this.frequency,
      targetAmount: targetAmount ?? this.targetAmount,
      baseIntervalAmount: baseIntervalAmount ?? this.baseIntervalAmount,
      currentIntervalAmount: currentIntervalAmount ?? this.currentIntervalAmount,
      totalIntervals: totalIntervals ?? this.totalIntervals,
      status: status ?? this.status,
      adjustmentHistory: adjustmentHistory ?? this.adjustmentHistory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'frequency': frequency.name,
      'targetAmount': targetAmount,
      'baseIntervalAmount': baseIntervalAmount,
      'currentIntervalAmount': currentIntervalAmount,
      'totalIntervals': totalIntervals,
      'status': status.name,
      'adjustmentHistory': adjustmentHistory.map((a) => a.toMap()).toList(),
    };
  }

  factory SavingsPlan.fromMap(Map<String, dynamic> map) {
    return SavingsPlan(
      startDate: DateTime.parse(map['startDate'] as String),
      targetDate: DateTime.parse(map['targetDate'] as String),
      frequency: SavingFrequency.values.firstWhere(
        (f) => f.name == (map['frequency'] as String?),
        orElse: () => SavingFrequency.weekly,
      ),
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0,
      baseIntervalAmount: (map['baseIntervalAmount'] as num?)?.toDouble() ?? 0,
      currentIntervalAmount: (map['currentIntervalAmount'] as num?)?.toDouble() ?? 0,
      totalIntervals: (map['totalIntervals'] as int?) ?? 1,
      status: PlanStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String?),
        orElse: () => PlanStatus.onTrack,
      ),
      adjustmentHistory: (map['adjustmentHistory'] as List<dynamic>?)
              ?.map((a) => PlanAdjustment.fromMap(Map<String, dynamic>.from(a)))
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      'SavingsPlan(₱$currentIntervalAmount/${frequency.label}, $totalIntervals intervals, $status)';
}

/// Status of the savings plan.
enum PlanStatus {
  onTrack('On Track'),
  atRisk('Behind Schedule'),
  completed('Completed');

  final String label;
  const PlanStatus(this.label);
}

/// Record of an adjustment to a savings plan.
class PlanAdjustment {
  final DateTime date;
  final String reason;
  final double oldIntervalAmount;
  final double newIntervalAmount;
  final int intervalsRemaining;
  final double remainingAmount;

  const PlanAdjustment({
    required this.date,
    required this.reason,
    required this.oldIntervalAmount,
    required this.newIntervalAmount,
    required this.intervalsRemaining,
    required this.remainingAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'reason': reason,
      'oldIntervalAmount': oldIntervalAmount,
      'newIntervalAmount': newIntervalAmount,
      'intervalsRemaining': intervalsRemaining,
      'remainingAmount': remainingAmount,
    };
  }

  factory PlanAdjustment.fromMap(Map<String, dynamic> map) {
    return PlanAdjustment(
      date: DateTime.parse(map['date'] as String),
      reason: map['reason'] as String,
      oldIntervalAmount: (map['oldIntervalAmount'] as num).toDouble(),
      newIntervalAmount: (map['newIntervalAmount'] as num).toDouble(),
      intervalsRemaining: map['intervalsRemaining'] as int,
      remainingAmount: (map['remainingAmount'] as num).toDouble(),
    );
  }

  @override
  String toString() =>
      'PlanAdjustment(₱$oldIntervalAmount → ₱$newIntervalAmount: $reason)';
}
