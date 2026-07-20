import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'savings_plan_model.dart';
import '../logic/savings_plan_calculator.dart';

/// Represents a single savings goal with comprehensive tracking
/// Focused on tracking savings for a specific product/object to purchase
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.title,
    required this.saved,
    required this.target,
    required this.icon,
    required this.color,
    required this.category,
    required this.frequency,
    required this.priority,
    this.productName = '',
    this.productDescription = '',
    this.productPhotoUrl,
    this.notificationsEnabled = false,
    this.notes = '',
    this.dueDate,
    this.createdDate,
    this.completedDate,
    this.paused = false,
    this.completed = false,
    this.archived = false,
    this.deleted = false,
    this.plan,
  });

  final String id;
  final String title;
  final double saved;
  final double target;
  final IconData icon;
  final Color color;
  final GoalCategory category;
  final SavingFrequency frequency;
  final int priority;
  final String productName;
  final String productDescription;
  /// Optional image path/URL for the product being saved for.
  /// Supports:
  /// - Network URLs (http/https)
  /// - Local file paths (from image_picker)
  /// - Asset paths ('assets/...')
  final String? productPhotoUrl;
  final bool notificationsEnabled;
  final String notes;
  final DateTime? dueDate;
  final DateTime? createdDate;
  final DateTime? completedDate;
  final bool paused;
  final bool completed;
  final bool archived;
  final bool deleted;

  /// The explicit savings plan for this goal (null before migration).
  final SavingsPlan? plan;

  /// Calculated progress (0-1) — clamped to ensure it never exceeds 1.0.
  double get progress => SavingsPlanCalculator.calculateProgress(saved, target).clamp(0.0, 1.0);

  /// Days remaining until due date.
  int get daysLeft {
    if (dueDate == null) return 90;
    final diff = dueDate!.difference(DateTime.now()).inDays;
    return math.max(0, diff);
  }

  /// Recommended deposit amount — reads from plan if available, else computes.
  double get recommendedDeposit {
    if (plan != null) return plan!.currentIntervalAmount;
    if (completed || daysLeft <= 0) return 0;
    final remaining = (target - saved).clamp(0, target);
    final depositsNeeded = math.max(1, daysLeft / frequency.days);
    return (remaining / depositsNeeded).ceilToDouble();
  }

  /// Time remaining as readable string
  String get timeLeft {
    if (dueDate == null) return 'No deadline';
    final diff = dueDate!.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Overdue by ${diff.abs()} days';
    if (diff <= 7) return '$diff days';
    if (diff <= 30) return '${(diff / 7).ceil()} weeks';
    if (diff <= 365) return '${(diff / 30).ceil()} months';
    return '${(diff / 365).ceil()} years';
  }

  /// Percentage complete as formatted string
  String get progressPercent => '${(progress * 100).round()}%';

  /// Remaining amount to save — uses calculator, clamped to never be negative.
  double get remaining => SavingsPlanCalculator.calculateRemaining(saved, target).clamp(0.0, target);

  /// Money needed (alias for remaining).
  double get moneyNeeded => remaining;

  /// Whether the goal is fully funded (saved >= target).
  bool get isFunded => saved >= target;

  /// Amount saved beyond the target (zero if not overfunded).
  double get excessSaved {
    if (saved <= target) return 0;
    return saved - target;
  }

  /// Human-readable funding status.
  String get fundingStatusLabel {
    if (completed) {
      if (excessSaved > 0) {
        return 'Completed with ₱${excessSaved.toStringAsFixed(0)} excess';
      }
      return 'Completed';
    }
    return 'In progress';
  }

  /// Savings per day — uses calculator.
  double get savingsPerDay =>
      SavingsPlanCalculator.savingsPerDay(remaining, daysLeft);

  /// Savings per week — uses calculator.
  double get savingsPerWeek =>
      SavingsPlanCalculator.savingsPerWeek(remaining, daysLeft);

  /// Savings per month — uses calculator.
  double get savingsPerMonth =>
      SavingsPlanCalculator.savingsPerMonth(remaining, daysLeft);

  /// Whether the goal is past its deadline and still incomplete.
  bool get isOverdue =>
      dueDate != null && !completed && DateTime.now().isAfter(dueDate!);

  /// Plan status from the plan, or computed on the fly.
  PlanStatus get planStatus {
    if (plan != null) return plan!.status;
    return SavingsPlanCalculator.determineStatus(
      saved: saved,
      target: target,
      daysLeft: daysLeft,
      frequencyDays: frequency.days,
    );
  }

  /// Estimated completion date — uses plan's calculation if available.
  DateTime? get estimatedCompletionDate {
    if (completed || remaining <= 0) return completedDate ?? dueDate;
    if (plan != null) {
      // From plan pacing: remaining / currentIntervalAmount * frequency
      final deposit = plan!.currentIntervalAmount;
      if (deposit <= 0) return null;
      final depositsNeeded = (remaining / deposit).ceil();
      final daysNeeded = depositsNeeded * frequency.days;
      return DateTime.now().add(Duration(days: daysNeeded));
    }
    final deposit = recommendedDeposit;
    if (deposit <= 0) return null;
    final depositsNeeded = (remaining / deposit).ceil();
    final daysNeeded = depositsNeeded * frequency.days;
    return DateTime.now().add(Duration(days: daysNeeded));
  }

  /// Human-readable estimate — uses calculator.
  String get estimatedCompletionLabel =>
      SavingsPlanCalculator.estimateCompletionLabel(estimatedCompletionDate);

  /// Status as readable string
  String get statusLabel {
    if (completed) return 'Completed';
    if (paused) return 'Paused';
    if (archived) return 'Archived';
    if (deleted) return 'Deleted';
    return 'Active';
  }

  /// Create a copy with modified fields
  SavingsGoal copyWith({
    String? title,
    double? saved,
    double? target,
    IconData? icon,
    Color? color,
    GoalCategory? category,
    SavingFrequency? frequency,
    String? productName,
    String? productDescription,
    String? productPhotoUrl,
    bool clearProductPhotoUrl = false,
    bool? notificationsEnabled,
    String? notes,
    DateTime? dueDate,
    DateTime? createdDate,
    DateTime? completedDate,
    bool clearDueDate = false,
    bool clearCreatedDate = false,
    bool clearCompletedDate = false,
    int? priority,
    bool? paused,
    bool? completed,
    bool? archived,
    bool? deleted,
    SavingsPlan? plan,
    bool clearPlan = false,
  }) {
    return SavingsGoal(
      id: id,
      title: title ?? this.title,
      saved: saved ?? this.saved,
      target: target ?? this.target,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      priority: priority ?? this.priority,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productPhotoUrl: clearProductPhotoUrl ? null : productPhotoUrl ?? this.productPhotoUrl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notes: notes ?? this.notes,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      createdDate: clearCreatedDate ? null : createdDate ?? this.createdDate,
      completedDate: completed == true && !this.completed
          ? DateTime.now()
          : clearCompletedDate
              ? null
              : completedDate ?? this.completedDate,
      paused: paused ?? this.paused,
      completed: completed ?? this.completed,
      archived: archived ?? this.archived,
      deleted: deleted ?? this.deleted,
      plan: clearPlan ? null : plan ?? this.plan,
    );
  }

  /// Convert to JSON map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'saved': saved,
      'target': target,
      'icon': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'color': color.toARGB32(),
      'category': category.toMap(),
      'frequency': frequency.name,
      'priority': priority,
      'productName': productName,
      'productDescription': productDescription,
      'productPhotoUrl': productPhotoUrl,
      'notificationsEnabled': notificationsEnabled,
      'notes': notes,
      'dueDate': dueDate?.toIso8601String(),
      'createdDate': createdDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'plan': plan?.toMap(),
      'paused': paused,
      'completed': completed,
      'archived': archived,
      'deleted': deleted,
    };
  }

  /// Create from JSON map
  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    final rawCategory = map['category'];
    final rawPlan = map['plan'];
    return SavingsGoal(
      id: map['id'] as String,
      title: map['title'] as String,
      saved: (map['saved'] as num?)?.toDouble() ?? 0,
      target: (map['target'] as num?)?.toDouble() ?? 0,
      icon: _iconFromData(
        (map['icon'] as int?) ?? Icons.savings_rounded.codePoint,
        fontFamily: (map['iconFontFamily'] as String?) ?? 'MaterialIcons',
        fontPackage: map['iconFontPackage'] as String?,
      ),
      color: Color((map['color'] as int?) ?? 0xFF5FDE9E),
      category: rawCategory is Map
          ? GoalCategory.fromMap(Map<String, dynamic>.from(rawCategory))
          : GoalCategory.predefined.firstWhere(
              (c) => c.name == (rawCategory as String?),
              orElse: () => GoalCategory.education,
            ),
      frequency: SavingFrequency.values.firstWhere(
        (f) => f.name == (map['frequency'] as String?),
        orElse: () => SavingFrequency.weekly,
      ),
      priority: (map['priority'] as int?) ?? 5,
      productName: (map['productName'] as String?) ?? '',
      productDescription: (map['productDescription'] as String?) ?? '',
      productPhotoUrl: map['productPhotoUrl'] as String?,
      notificationsEnabled: (map['notificationsEnabled'] as bool?) ?? false,
      notes: (map['notes'] as String?) ?? '',
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      createdDate: map['createdDate'] != null
          ? DateTime.parse(map['createdDate'] as String)
          : null,
      completedDate: map['completedDate'] != null
          ? DateTime.parse(map['completedDate'] as String)
          : null,
      paused: (map['paused'] as bool?) ?? false,
      completed: (map['completed'] as bool?) ?? false,
      archived: (map['archived'] as bool?) ?? false,
      deleted: (map['deleted'] as bool?) ?? false,
      plan: rawPlan != null
          ? SavingsPlan.fromMap(Map<String, dynamic>.from(rawPlan))
          : null,
    );
  }

  /// Ensure this goal has a [SavingsPlan]. If [plan] is null, synthesize one
  /// from existing fields (for backward compatibility with data saved before
  /// the plan system was introduced).
  SavingsGoal ensurePlan() {
    if (plan != null) return this;
    final effectiveDueDate = dueDate ?? DateTime.now().add(const Duration(days: 90));
    final effectiveCreatedDate = createdDate ?? DateTime.now().subtract(const Duration(days: 30));
    final synthesized = SavingsPlan.create(
      startDate: effectiveCreatedDate,
      targetDate: effectiveDueDate,
      frequency: frequency,
      targetAmount: target,
    );
    return copyWith(plan: synthesized.recalculate(saved));
  }

  /// Create a goal with a fresh savings plan (used by the new wizard).
  factory SavingsGoal.withPlan({
    required String id,
    required String title,
    required double target,
    required IconData icon,
    required Color color,
    required GoalCategory category,
    required SavingFrequency frequency,
    required DateTime dueDate,
    int priority = 5,
    String productName = '',
    String productDescription = '',
    String? productPhotoUrl,
    bool notificationsEnabled = false,
  }) {
    final now = DateTime.now();
    final plan = SavingsPlan.create(
      startDate: now,
      targetDate: dueDate,
      frequency: frequency,
      targetAmount: target,
    );
    return SavingsGoal(
      id: id,
      title: title,
      saved: 0,
      target: target,
      icon: icon,
      color: color,
      category: category,
      frequency: frequency,
      priority: priority,
      productName: productName,
      productDescription: productDescription,
      productPhotoUrl: productPhotoUrl,
      notificationsEnabled: notificationsEnabled,
      dueDate: dueDate,
      createdDate: now,
      plan: plan,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsGoal &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SavingsGoal(id: $id, title: $title, progress: $progress)';
}

/// Record of a savings transaction
class SavingsLog {
  const SavingsLog({
    required this.id,
    required this.goalId,
    required this.goalTitle,
    required this.amount,
    required this.date,
    this.entryType = SavingsEntryType.manual,
    this.notes = '',
  });

  final String id;
  final String goalId;
  final String goalTitle;
  final double amount;
  final DateTime date;
  final SavingsEntryType entryType;
  final String notes;

  /// Formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(date.year, date.month, date.day);

    if (logDate == today) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (logDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  SavingsLog copyWith({
    double? amount,
    String? notes,
    SavingsEntryType? entryType,
  }) {
    return SavingsLog(
      id: id,
      goalId: goalId,
      goalTitle: goalTitle,
      amount: amount ?? this.amount,
      date: date,
      entryType: entryType ?? this.entryType,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'goalTitle': goalTitle,
      'amount': amount,
      'date': date.toIso8601String(),
      'entryType': entryType.name,
      'notes': notes,
    };
  }

  factory SavingsLog.fromMap(Map<String, dynamic> map) {
    return SavingsLog(
      id: map['id'] as String,
      goalId: (map['goalId'] as String?) ?? '',
      goalTitle: map['goalTitle'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      entryType: SavingsEntryType.values.firstWhere(
        (e) => e.name == (map['entryType'] as String?),
        orElse: () => SavingsEntryType.manual,
      ),
      notes: (map['notes'] as String?) ?? '',
    );
  }
}

/// Type of savings entry.
///
/// - [manual]: User manually entered an amount via the form.
/// - [suggested]: User tapped the suggested/recommended amount.
/// - [auto]: System-logged entry (e.g., auto-deposit).
/// - [confirmed]: User confirmed the planned amount from a notification.
/// - [actual]: User entered a different amount when responding to a reminder.
/// - [missed]: Auto-logged as $0 when a reminder interval passed unanswered.
enum SavingsEntryType {
  manual('Manual Entry'),
  suggested('Suggested Deposit'),
  auto('Automatic'),
  confirmed('Confirmed'),
  actual('Actual Entry'),
  missed('Missed');

  final String label;

  const SavingsEntryType(this.label);
}

/// Represents a savings milestone (25%, 50%, 75%, 100%)
class SavingsMilestone {
  const SavingsMilestone({
    required this.id,
    required this.goalId,
    required this.percentage,
    this.reachedDate,
  });

  final String id;
  final String goalId;
  final int percentage; // 25, 50, 75, or 100
  final DateTime? reachedDate;

  /// Whether this milestone has been reached
  bool get isReached => reachedDate != null;

  /// Copy with new values
  SavingsMilestone copyWith({
    DateTime? reachedDate,
    bool clearReachedDate = false,
  }) {
    return SavingsMilestone(
      id: id,
      goalId: goalId,
      percentage: percentage,
      reachedDate: clearReachedDate ? null : reachedDate ?? this.reachedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'percentage': percentage,
      'reachedDate': reachedDate?.toIso8601String(),
    };
  }

  factory SavingsMilestone.fromMap(Map<String, dynamic> map) {
    return SavingsMilestone(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      percentage: (map['percentage'] as int?) ?? 0,
      reachedDate: map['reachedDate'] != null
          ? DateTime.parse(map['reachedDate'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'SavingsMilestone(goalId: $goalId, percentage: $percentage%, reached: $isReached)';
}

/// Goal category with customization
class GoalCategory {
  final String name;
  final String label;
  final IconData icon;
  final Color color;
  final String description;

  const GoalCategory({
    required this.name,
    required this.label,
    required this.icon,
    required this.color,
    this.description = '',
  });

  const GoalCategory.custom({
    required this.name,
    required this.label,
    required this.icon,
    required this.color,
    this.description = '',
  });

  /// Predefined categories
  static const GoalCategory education = GoalCategory(
    name: 'education',
    label: 'Education',
    icon: Icons.school_rounded,
    color: Color(0xFF5FDE9E),
    description: 'Books, courses, textbooks',
  );

  static const GoalCategory technology = GoalCategory(
    name: 'technology',
    label: 'Technology',
    icon: Icons.devices_rounded,
    color: Color(0xFF00D9FF),
    description: 'Laptops, phones, gadgets',
  );

  static const GoalCategory travel = GoalCategory(
    name: 'travel',
    label: 'Travel',
    icon: Icons.flight_rounded,
    color: Color(0xFFFF6B9D),
    description: 'Flights, trips, vacations',
  );

  static const GoalCategory emergency = GoalCategory(
    name: 'emergency',
    label: 'Emergency',
    icon: Icons.warning_rounded,
    color: Color(0xFFFFD93D),
    description: 'Emergency fund, safety net',
  );

  static const GoalCategory health = GoalCategory(
    name: 'health',
    label: 'Health',
    icon: Icons.favorite_rounded,
    color: Color(0xFF52B788),
    description: 'Fitness equipment, wellness items',
  );

  static const GoalCategory entertainment = GoalCategory(
    name: 'entertainment',
    label: 'Entertainment',
    icon: Icons.movie_rounded,
    color: Color(0xFF9D4EDD),
    description: 'Gaming, hobbies, entertainment',
  );

  static const GoalCategory savings = GoalCategory(
    name: 'savings',
    label: 'Savings',
    icon: Icons.savings_rounded,
    color: Color(0xFF3ECCC1),
    description: 'General savings fund',
  );

  static const GoalCategory investment = GoalCategory(
    name: 'investment',
    label: 'Investment',
    icon: Icons.trending_up_rounded,
    color: Color(0xFFFFB703),
    description: 'Investment purchases',
  );

  /// Get all predefined categories
  static List<GoalCategory> get predefined => [
    education,
    technology,
    travel,
    emergency,
    health,
    entertainment,
    savings,
    investment,
  ];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'label': label,
      'icon': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'color': color.toARGB32(),
      'description': description,
    };
  }

  factory GoalCategory.fromMap(Map<String, dynamic> map) {
    return GoalCategory.custom(
      name: (map['name'] as String?) ?? 'custom',
      label: (map['label'] as String?) ?? 'Custom',
      icon: _iconFromData(
        (map['icon'] as int?) ?? Icons.category_rounded.codePoint,
        fontFamily: (map['iconFontFamily'] as String?) ?? 'MaterialIcons',
        fontPackage: map['iconFontPackage'] as String?,
      ),
      color: Color((map['color'] as int?) ?? 0xFF5FDE9E),
      description: (map['description'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalCategory &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'GoalCategory($label)';
}

/// Frequency of contributions
enum SavingFrequency {
  daily('Daily', 1),
  threeDaily('Every 3 Days', 3),
  weekly('Weekly', 7),
  biWeekly('Bi-weekly', 14),
  monthly('Monthly', 30),
  quarterly('Quarterly', 90),
  yearly('Yearly', 365);

  final String label;
  final int days;

  const SavingFrequency(this.label, this.days);

  String get pluralLabel => days == 1 ? 'day' : 'days';
  String get intervalLabel => days == 1 ? 'day' : '$days days';
}

/// Sorting options for goals
enum GoalSort {
  priority('Priority', Icons.straight_rounded),
  progress('Progress', Icons.trending_up_rounded),
  deadline('Deadline', Icons.schedule_rounded),
  target('Target Amount', Icons.payments_rounded),
  created('Recently Created', Icons.new_releases_rounded);

  final String label;
  final IconData icon;

  const GoalSort(this.label, this.icon);
}

/// Analytics time range
enum AnalyticsRange {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  final String label;

  const AnalyticsRange(this.label);
}/// Calendar event for tracking non-goal events on the calendar
class CalendarEvent {
  final String id;
  final String title;
  final String? notes;
  final DateTime date;
  final TimeOfDay? time;
  final IconData icon;
  final Color color;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.notes,
    required this.date,
    this.time,
    this.icon = Icons.event_rounded,
    this.color = const Color(0xFFA8FF3E),
  });

  /// Formatted time string
  String get formattedTime {
    if (time == null) return '';
    final hour = time!.hour.toString().padLeft(2, '0');
    final minute = time!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  CalendarEvent copyWith({
    String? title,
    String? notes,
    DateTime? date,
    TimeOfDay? time,
    bool clearTime = false,
    IconData? icon,
    Color? color,
  }) {
    return CalendarEvent(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      time: clearTime ? null : time ?? this.time,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'date': date.toIso8601String(),
      'timeHour': time?.hour,
      'timeMinute': time?.minute,
      'icon': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'color': color.toARGB32(),
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    TimeOfDay? eventTime;
    if (map['timeHour'] != null && map['timeMinute'] != null) {
      eventTime = TimeOfDay(
        hour: map['timeHour'] as int,
        minute: map['timeMinute'] as int,
      );
    }
    return CalendarEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      date: DateTime.parse(map['date'] as String),
      time: eventTime,
      icon: _iconFromData(
        (map['icon'] as int?) ?? Icons.event_rounded.codePoint,
        fontFamily: (map['iconFontFamily'] as String?) ?? 'MaterialIcons',
        fontPackage: map['iconFontPackage'] as String?,
      ),
      color: Color((map['color'] as int?) ?? 0xFFA8FF3E),
    );
  }
}

/// Helper to create IconData safely without const warnings.
IconData _iconFromData(int codePoint, {String? fontFamily, String? fontPackage}) {
  // ignore: non_const_argument_for_const_parameter
  return IconData(codePoint, fontFamily: fontFamily, fontPackage: fontPackage);
}

/// Goal management actionsenum GoalAction {
  view('View Details', Icons.visibility_rounded),
  add('Add Savings', Icons.add_rounded),
  edit('Edit Goal', Icons.edit_rounded),
  pause('Pause Goal', Icons.pause_rounded),
  resume('Continue Goal', Icons.play_arrow_rounded),
  complete('Mark Completed', Icons.check_circle_rounded),
  undo('Undo Completion', Icons.undo_rounded),
  archive('Archive Goal', Icons.archive_rounded),
  unarchive('Unarchive Goal', Icons.unarchive_rounded),
  delete('Delete Goal', Icons.delete_rounded);

  final String label;
  final IconData icon;

  const GoalAction(this.label, this.icon);
}
