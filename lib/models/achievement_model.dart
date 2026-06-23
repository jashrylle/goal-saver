import 'package:flutter/material.dart';

/// Achievement badge system for gamification
class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementType type;
  final int requirement;
  final bool unlocked;
  final DateTime? unlockedDate;

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
    required this.requirement,
    this.unlocked = false,
    this.unlockedDate,
  });

  int get progress {
    // Override with actual progress calculation in controller
    return unlocked ? 100 : 0;
  }

  double get progressPercent => progress / 100.0;

  AchievementBadge copyWith({
    bool? unlocked,
    DateTime? unlockedDate,
  }) {
    return AchievementBadge(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: color,
      type: type,
      requirement: requirement,
      unlocked: unlocked ?? this.unlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon.codePoint,
      'color': color.toARGB32(),
      'type': type.name,
      'requirement': requirement,
      'unlocked': unlocked,
      'unlockedDate': unlockedDate?.toIso8601String(),
    };
  }

  factory AchievementBadge.fromMap(Map<String, dynamic> map) {
    return AchievementBadge(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      icon: IconData(
        (map['icon'] as int?) ?? 0xf0a8,
        fontFamily: 'MaterialIcons',
      ),
      color: Color((map['color'] as int?) ?? 0xFF5FDE9E),
      type: AchievementType.values.firstWhere(
        (t) => t.name == (map['type'] as String?),
        orElse: () => AchievementType.milestone,
      ),
      requirement: (map['requirement'] as int?) ?? 1,
      unlocked: (map['unlocked'] as bool?) ?? false,
      unlockedDate: map['unlockedDate'] != null
          ? DateTime.parse(map['unlockedDate'] as String)
          : null,
    );
  }
}

/// Type of achievement
enum AchievementType {
  milestone('Milestone'),
  streak('Streak'),
  savings('Savings'),
  discipline('Discipline'),
  completion('Completion'),
  social('Social');

  final String label;

  const AchievementType(this.label);
}

/// Predefined achievements
class Achievements {
  static const List<AchievementBadge> all = [
    // Milestone achievements
    AchievementBadge(
      id: 'first_goal',
      title: 'First Step',
      description: 'Create your first savings goal',
      icon: Icons.flag_rounded,
      color: Color(0xFF5FDE9E),
      type: AchievementType.milestone,
      requirement: 1,
    ),
    AchievementBadge(
      id: 'three_goals',
      title: 'Goal Setter',
      description: 'Create 3 active savings goals',
      icon: Icons.stars_rounded,
      color: Color(0xFFFFB703),
      type: AchievementType.milestone,
      requirement: 3,
    ),
    AchievementBadge(
      id: 'five_goals',
      title: 'Master Planner',
      description: 'Create 5 active savings goals',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF9D4EDD),
      type: AchievementType.milestone,
      requirement: 5,
    ),
    // Streak achievements
    AchievementBadge(
      id: 'seven_day_streak',
      title: 'On Fire',
      description: 'Maintain a 7-day saving streak',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF6B6B),
      type: AchievementType.streak,
      requirement: 7,
    ),
    AchievementBadge(
      id: 'thirty_day_streak',
      title: 'Unstoppable',
      description: 'Maintain a 30-day saving streak',
      icon: Icons.flash_on_rounded,
      color: Color(0xFFFFD93D),
      type: AchievementType.streak,
      requirement: 30,
    ),
    // Savings achievements
    AchievementBadge(
      id: 'thousand_saved',
      title: 'Saver',
      description: 'Save ₱1,000 across all goals',
      icon: Icons.savings_rounded,
      color: Color(0xFF52B788),
      type: AchievementType.savings,
      requirement: 1000,
    ),
    AchievementBadge(
      id: 'ten_thousand_saved',
      title: 'Big Saver',
      description: 'Save ₱10,000 across all goals',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF3ECCC1),
      type: AchievementType.savings,
      requirement: 10000,
    ),
    // Completion achievements
    AchievementBadge(
      id: 'first_goal_complete',
      title: 'Goal Completed',
      description: 'Complete your first savings goal',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF5FDE9E),
      type: AchievementType.completion,
      requirement: 1,
    ),
    AchievementBadge(
      id: 'three_goals_complete',
      title: 'Achiever',
      description: 'Complete 3 savings goals',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFFFB703),
      type: AchievementType.completion,
      requirement: 3,
    ),
    // Discipline achievements
    AchievementBadge(
      id: 'discipline_expert',
      title: 'Discipline Expert',
      description: 'Reach a discipline score of 90+',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF00D9FF),
      type: AchievementType.discipline,
      requirement: 90,
    ),
  ];

  /// Get achievement by ID
  static AchievementBadge? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get achievements by type
  static List<AchievementBadge> getByType(AchievementType type) {
    return all.where((a) => a.type == type).toList();
  }

  /// Get locked achievements
  static List<AchievementBadge> getLocked(List<AchievementBadge> unlocked) {
    final unlockedIds = unlocked.map((a) => a.id).toSet();
    return all.where((a) => !unlockedIds.contains(a.id)).toList();
  }
}

/// Smart reminder for motivational notifications
class SmartReminder {
  final String id;
  final String goalId;
  final String message;
  final DateTime scheduleTime;
  final ReminderFrequency frequency;
  bool enabled;
  final DateTime? lastSent;

  SmartReminder({
    required this.id,
    required this.goalId,
    required this.message,
    required this.scheduleTime,
    required this.frequency,
    this.enabled = true,
    this.lastSent,
  });

  bool shouldSendReminder() {
    if (!enabled) return false;

    final now = DateTime.now();
    if (lastSent == null) return true;

    final daysSinceLastSent = now.difference(lastSent!).inDays;

    return switch (frequency) {
      ReminderFrequency.daily => daysSinceLastSent >= 1,
      ReminderFrequency.weekly => daysSinceLastSent >= 7,
      ReminderFrequency.biWeekly => daysSinceLastSent >= 14,
      ReminderFrequency.monthly => daysSinceLastSent >= 30,
      ReminderFrequency.once => lastSent == null,
    };
  }

  SmartReminder copyWith({
    String? message,
    DateTime? scheduleTime,
    ReminderFrequency? frequency,
    bool? enabled,
    DateTime? lastSent,
  }) {
    return SmartReminder(
      id: id,
      goalId: goalId,
      message: message ?? this.message,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      frequency: frequency ?? this.frequency,
      enabled: enabled ?? this.enabled,
      lastSent: lastSent ?? this.lastSent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'message': message,
      'scheduleTime': scheduleTime.toIso8601String(),
      'frequency': frequency.name,
      'enabled': enabled,
      'lastSent': lastSent?.toIso8601String(),
    };
  }

  factory SmartReminder.fromMap(Map<String, dynamic> map) {
    return SmartReminder(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      message: map['message'] as String,
      scheduleTime: DateTime.parse(map['scheduleTime'] as String),
      frequency: ReminderFrequency.values.firstWhere(
        (f) => f.name == (map['frequency'] as String?),
        orElse: () => ReminderFrequency.weekly,
      ),
      enabled: (map['enabled'] as bool?) ?? true,
      lastSent: map['lastSent'] != null
          ? DateTime.parse(map['lastSent'] as String)
          : null,
    );
  }
}

/// Reminder frequency options
enum ReminderFrequency {
  daily('Daily'),
  weekly('Weekly'),
  biWeekly('Bi-weekly'),
  monthly('Monthly'),
  once('Once');

  final String label;

  const ReminderFrequency(this.label);
}
