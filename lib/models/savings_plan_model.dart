import 'package:flutter/material.dart';
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

  /// Recalculate the plan based on current saved amount.
  SavingsPlan recalculate(double saved) {
    final remaining = (targetAmount - saved).clamp(0.0, targetAmount);
    final intervalsLeft = SavingsPlanCalculator.calculateIntervalsLeft(
      targetDate.difference(DateTime.now()).inDays,
      frequency.days,
    );
    final newIntervalAmount = intervalsLeft > 0
        ? SavingsPlanCalculator.calculateIntervalAmount(remaining, intervalsLeft)
        : currentIntervalAmount;
    return copyWith(currentIntervalAmount: newIntervalAmount);
  }

  SavingsPlan withAdjustment(PlanAdjustment adjustment) {
    return copyWith(
      currentIntervalAmount: adjustment.newIntervalAmount,
      adjustmentHistory: [...adjustmentHistory, adjustment],
    );
  }

  Map<String, dynamic> toMap() => {
    'startDate': startDate.toIso8601String(),
    'targetDate': targetDate.toIso8601String(),
    'frequency': frequency.index,
    'targetAmount': targetAmount,
    'baseIntervalAmount': baseIntervalAmount,
    'currentIntervalAmount': currentIntervalAmount,
    'totalIntervals': totalIntervals,
    'status': status.index,
    'adjustmentHistory': adjustmentHistory.map((a) => a.toMap()).toList(),
  };

  factory SavingsPlan.fromMap(Map<String, dynamic> map) => SavingsPlan(
    startDate: DateTime.parse(map['startDate'] as String),
    targetDate: DateTime.parse(map['targetDate'] as String),
    frequency: SavingFrequency.values[(map['frequency'] as num?)?.toInt() ?? 0],
    targetAmount: (map['targetAmount'] as num).toDouble(),
    baseIntervalAmount: (map['baseIntervalAmount'] as num).toDouble(),
    currentIntervalAmount: (map['currentIntervalAmount'] as num).toDouble(),
    totalIntervals: (map['totalIntervals'] as num?)?.toInt() ?? 0,
    status: PlanStatus.values[(map['status'] as num?)?.toInt() ?? 0],
    adjustmentHistory: (map['adjustmentHistory'] as List<dynamic>?)
        ?.map((a) => PlanAdjustment.fromMap(a as Map<String, dynamic>))
        .toList() ?? [],
  );

  @override
  String toString() =>
      'SavingsPlan(₱$baseIntervalAmount/$frequency → $targetDate, status: $status)';
}

/// Status of a savings plan.
enum PlanStatus { onTrack, atRisk, behind, completed }

/// Adjustment record for a savings plan.
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

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'reason': reason,
    'oldIntervalAmount': oldIntervalAmount,
    'newIntervalAmount': newIntervalAmount,
    'intervalsRemaining': intervalsRemaining,
    'remainingAmount': remainingAmount,
  };

  factory PlanAdjustment.fromMap(Map<String, dynamic> map) => PlanAdjustment(
    date: DateTime.parse(map['date'] as String),
    reason: map['reason'] as String,
    oldIntervalAmount: (map['oldIntervalAmount'] as num).toDouble(),
    newIntervalAmount: (map['newIntervalAmount'] as num).toDouble(),
    intervalsRemaining: map['intervalsRemaining'] as int,
    remainingAmount: (map['remainingAmount'] as num).toDouble(),
  );

  @override
  String toString() =>
      'PlanAdjustment(₱$oldIntervalAmount → ₱$newIntervalAmount: $reason)';
}

/// Player level for gamification — tracks XP and level progression.
class PlayerLevel {
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int totalXp;

  const PlayerLevel({
    this.level = 1,
    this.xp = 0,
    this.xpToNextLevel = 100,
    this.totalXp = 0,
  });

  double get progress => xpToNextLevel > 0 ? (xp / xpToNextLevel).clamp(0.0, 1.0) : 1.0;
  String get title => _levelTitles[level.clamp(1, _levelTitles.length - 1)];

  static const List<String> _levelTitles = [
    'Beginner Saver',
    'Regular Saver',
    'Dedicated Saver',
    'Savings Pro',
    'Finance Wizard',
    'Money Master',
    'Wealth Builder',
    'Fortune Seeker',
    'Prosperity King',
    'Legendary Saver',
  ];

  PlayerLevel copyWith({int? level, int? xp, int? xpToNextLevel, int? totalXp}) {
    return PlayerLevel(
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      totalXp: totalXp ?? this.totalXp,
    );
  }

  Map<String, dynamic> toMap() => {
    'level': level,
    'xp': xp,
    'xpToNextLevel': xpToNextLevel,
    'totalXp': totalXp,
  };

  factory PlayerLevel.fromMap(Map<String, dynamic> map) => PlayerLevel(
    level: (map['level'] as num?)?.toInt() ?? 1,
    xp: (map['xp'] as num?)?.toInt() ?? 0,
    xpToNextLevel: (map['xpToNextLevel'] as num?)?.toInt() ?? 100,
    totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
  );

  @override
  String toString() => 'PlayerLevel(level: $level, xp: $xp/$xpToNextLevel, totalXp: $totalXp)';
}

/// Flags for selective reset of user data.
class ResetFlags {
  bool goals = false;
  bool history = false;
  bool budgetAllocations = false;
  bool savingsForecasts = false;
  bool reports = false;
  bool analytics = false;
  bool healthScore = false;
  bool recentActivity = false;
  bool goalMilestones = false;
  bool goalPredictions = false;
  bool achievements = false;
  bool xpLevel = false;
  bool streak = false;
  bool milestoneCelebrations = false;
  bool dailyMotivation = false;
  bool notes = false;
  bool calendarEvents = false;
  bool profileData = false;
  bool coachInsights = false;
  bool categories = false;
  bool predefinedCategories = false;
  bool reminders = false;
  bool preferences = false;  bool productImages = false;
  bool dashboardLayout = false;

  bool get anySelected =>
      goals || history || budgetAllocations || savingsForecasts || reports ||
      analytics || healthScore || recentActivity ||
      goalMilestones || goalPredictions ||
      achievements || xpLevel || streak || milestoneCelebrations || dailyMotivation ||
      notes || calendarEvents || profileData || coachInsights ||
      categories || predefinedCategories || reminders || preferences ||
      productImages || dashboardLayout;

  void selectAll() {
    goals = history = budgetAllocations = savingsForecasts = reports =
        analytics = healthScore = recentActivity =
        goalMilestones = goalPredictions =
    achievements = xpLevel = streak = milestoneCelebrations = dailyMotivation =
    notes = calendarEvents = profileData = coachInsights =
    categories = predefinedCategories = reminders = preferences =
    productImages = dashboardLayout = true;
  }

  void deselectAll() {
    goals = history = budgetAllocations = savingsForecasts = reports =
        analytics = healthScore = recentActivity =
        goalMilestones = goalPredictions =
    achievements = xpLevel = streak = milestoneCelebrations = dailyMotivation =
    notes = calendarEvents = profileData = coachInsights =
    categories = predefinedCategories = reminders = preferences =
    productImages = dashboardLayout = false;
  }
}

/// Financial health score computed from user's savings data.
class FinancialHealthScore {
  final double consistency;
  final double completionRate;
  final double savingsRate;
  final double progressRate;
  final double discipline;

  const FinancialHealthScore({
    required this.consistency,
    required this.completionRate,
    required this.savingsRate,
    required this.progressRate,
    required this.discipline,
  });

  int get roundedScore {
    final avg = (consistency + completionRate + savingsRate + progressRate + discipline) / 5;
    return (avg * 100).round();
  }

  String get grade {
    final s = roundedScore;
    if (s >= 90) return 'A+';
    if (s >= 80) return 'A';
    if (s >= 70) return 'B+';
    if (s >= 60) return 'B';
    if (s >= 50) return 'C+';
    if (s >= 40) return 'C';
    if (s >= 30) return 'D';
    return 'F';
  }

  Color get gradeColor {
    final s = roundedScore;
    if (s >= 80) return const Color(0xFF00E676);
    if (s >= 60) return const Color(0xFFA8FF3E);
    if (s >= 40) return const Color(0xFFFFA726);
    return const Color(0xFFFF6B6B);
  }

  IconData get gradeIcon {
    final s = roundedScore;
    if (s >= 80) return Icons.emoji_events_rounded;
    if (s >= 60) return Icons.thumb_up_rounded;
    if (s >= 40) return Icons.trending_up_rounded;
    return Icons.fitness_center_rounded;
  }
}