import 'package:flutter/material.dart';

/// Achievement badge system for gamification.
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
  final int currentProgress;

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
    this.currentProgress = 0,
  });

  /// Progress as fraction 0.0–1.0.
  double get progressPercent =>
      requirement > 0 ? (currentProgress / requirement).clamp(0.0, 1.0) : 0.0;

  /// Progress percentage string.
  String get progressText => '${(progressPercent * 100).round()}%';

  /// Whether the badge should display as newly unlocked.
  bool get isNewlyUnlocked =>
      unlocked && unlockedDate != null &&
      DateTime.now().difference(unlockedDate!).inSeconds < 5;

  AchievementBadge copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    Color? color,
    AchievementType? type,
    int? requirement,
    bool? unlocked,
    DateTime? unlockedDate,
    int? currentProgress,
  }) {
    return AchievementBadge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      requirement: requirement ?? this.requirement,
      unlocked: unlocked ?? this.unlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      currentProgress: currentProgress ?? this.currentProgress,
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
      'currentProgress': currentProgress,
    };
  }

  factory AchievementBadge.fromMap(Map<String, dynamic> map) {
    return AchievementBadge(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      icon: _iconFromCodePoint((map['icon'] as int?) ?? Icons.emoji_events_rounded.codePoint),
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
      currentProgress: (map['currentProgress'] as int?) ?? 0,
    );
  }
}

/// Type of achievement.
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

/// Game-style badge tiers with associated colors and icons.
class BadgeTier {
  final String name;
  final Color color;
  final IconData icon;
  final int level;

  const BadgeTier._(this.name, this.color, this.icon, this.level);

  static const BadgeTier bronze = BadgeTier._('Bronze', Color(0xFFCD7F32), Icons.emoji_events_rounded, 1);
  static const BadgeTier silver = BadgeTier._('Silver', Color(0xFFC0C0C0), Icons.emoji_events_rounded, 2);
  static const BadgeTier gold = BadgeTier._('Gold', Color(0xFFFFD700), Icons.emoji_events_rounded, 3);
  static const BadgeTier platinum = BadgeTier._('Platinum', Color(0xFFE5E4E2), Icons.diamond_rounded, 4);
  static const BadgeTier diamond = BadgeTier._('Diamond', Color(0xFFB9F2FF), Icons.diamond_rounded, 5);
  static const BadgeTier legendary = BadgeTier._('Legendary', Color(0xFFFF6B35), Icons.auto_awesome_rounded, 6);
  static const BadgeTier trophy = BadgeTier._('Trophy', Color(0xFFFFD700), Icons.emoji_events_rounded, 7);
  static const BadgeTier medal = BadgeTier._('Medal', Color(0xFFFF6B9D), Icons.military_tech_rounded, 8);
  static const BadgeTier shield = BadgeTier._('Shield', Color(0xFF00D9FF), Icons.shield_rounded, 9);
  static const BadgeTier emblem = BadgeTier._('Emblem', Color(0xFF9D4EDD), Icons.verified_rounded, 10);

  static const List<BadgeTier> all = [
    bronze, silver, gold, platinum, diamond,
    legendary, trophy, medal, shield, emblem,
  ];
}

/// Predefined achievements — expanded with game-style tiered badges.
class Achievements {
  static const List<AchievementBadge> all = [
    // ── Milestone Achievements (Tier-based) ──────────────────────────

    AchievementBadge(
      id: 'first_goal',
      title: 'Bronze Starter',
      description: 'Create your first savings goal',
      icon: Icons.flag_rounded,
      color: Color(0xFFCD7F32), // Bronze
      type: AchievementType.milestone,
      requirement: 1,
    ),
    AchievementBadge(
      id: 'three_goals',
      title: 'Silver Planner',
      description: 'Create 3 active savings goals',
      icon: Icons.stars_rounded,
      color: Color(0xFFC0C0C0), // Silver
      type: AchievementType.milestone,
      requirement: 3,
    ),
    AchievementBadge(
      id: 'five_goals',
      title: 'Gold Strategist',
      description: 'Create 5 active savings goals',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFFD700), // Gold
      type: AchievementType.milestone,
      requirement: 5,
    ),
    AchievementBadge(
      id: 'ten_goals',
      title: 'Platinum Architect',
      description: 'Create 10 active savings goals',
      icon: Icons.account_tree_rounded,
      color: Color(0xFFE5E4E2), // Platinum
      type: AchievementType.milestone,
      requirement: 10,
    ),

    // ── Streak Achievements (Tier-based) ─────────────────────────────

    AchievementBadge(
      id: 'seven_day_streak',
      title: 'Bronze Streak',
      description: 'Maintain a 7-day saving streak',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFCD7F32),
      type: AchievementType.streak,
      requirement: 7,
    ),
    AchievementBadge(
      id: 'fourteen_day_streak',
      title: 'Silver Streak',
      description: 'Maintain a 14-day saving streak',
      icon: Icons.whatshot_rounded,
      color: Color(0xFFC0C0C0),
      type: AchievementType.streak,
      requirement: 14,
    ),
    AchievementBadge(
      id: 'thirty_day_streak',
      title: 'Gold Streak',
      description: 'Maintain a 30-day saving streak',
      icon: Icons.flash_on_rounded,
      color: Color(0xFFFFD700),
      type: AchievementType.streak,
      requirement: 30,
    ),
    AchievementBadge(
      id: 'sixty_day_streak',
      title: 'Diamond Streak',
      description: 'Maintain a 60-day saving streak',
      icon: Icons.electric_bolt_rounded,
      color: Color(0xFFB9F2FF),
      type: AchievementType.streak,
      requirement: 60,
    ),
    AchievementBadge(
      id: 'hundred_day_streak',
      title: 'Legendary Streak',
      description: 'Maintain a 100-day saving streak',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFF6B35),
      type: AchievementType.streak,
      requirement: 100,
    ),

    // ── Savings Achievements (Tier-based) ────────────────────────────

    AchievementBadge(
      id: 'thousand_saved',
      title: 'Bronze Saver',
      description: 'Save ₱1,000 across all goals',
      icon: Icons.savings_rounded,
      color: Color(0xFFCD7F32),
      type: AchievementType.savings,
      requirement: 1000,
    ),
    AchievementBadge(
      id: 'ten_thousand_saved',
      title: 'Silver Saver',
      description: 'Save ₱10,000 across all goals',
      icon: Icons.trending_up_rounded,
      color: Color(0xFFC0C0C0),
      type: AchievementType.savings,
      requirement: 10000,
    ),
    AchievementBadge(
      id: 'fifty_thousand_saved',
      title: 'Gold Saver',
      description: 'Save ₱50,000 across all goals',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFFFFD700),
      type: AchievementType.savings,
      requirement: 50000,
    ),
    AchievementBadge(
      id: 'hundred_thousand_saved',
      title: 'Platinum Saver',
      description: 'Save ₱100,000 across all goals',
      icon: Icons.monetization_on_rounded,
      color: Color(0xFFE5E4E2),
      type: AchievementType.savings,
      requirement: 100000,
    ),
    AchievementBadge(
      id: 'million_saved',
      title: 'Legendary Saver',
      description: 'Save ₱1,000,000 across all goals',
      icon: Icons.diamond_rounded,
      color: Color(0xFFFF6B35),
      type: AchievementType.savings,
      requirement: 1000000,
    ),

    // ── Completion Achievements (Tier-based) ─────────────────────────

    AchievementBadge(
      id: 'first_goal_complete',
      title: 'Bronze Trophy',
      description: 'Complete your first savings goal',
      icon: Icons.check_circle_rounded,
      color: Color(0xFFCD7F32),
      type: AchievementType.completion,
      requirement: 1,
    ),
    AchievementBadge(
      id: 'three_goals_complete',
      title: 'Silver Trophy',
      description: 'Complete 3 savings goals',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFC0C0C0),
      type: AchievementType.completion,
      requirement: 3,
    ),
    AchievementBadge(
      id: 'five_goals_complete',
      title: 'Gold Trophy',
      description: 'Complete 5 savings goals',
      icon: Icons.military_tech_rounded,
      color: Color(0xFFFFD700),
      type: AchievementType.completion,
      requirement: 5,
    ),
    AchievementBadge(
      id: 'ten_goals_complete',
      title: 'Diamond Trophy',
      description: 'Complete 10 savings goals',
      icon: Icons.shield_rounded,
      color: Color(0xFFB9F2FF),
      type: AchievementType.completion,
      requirement: 10,
    ),
    AchievementBadge(
      id: 'twenty_goals_complete',
      title: 'Legendary Trophy',
      description: 'Complete 20 savings goals',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFF6B35),
      type: AchievementType.completion,
      requirement: 20,
    ),

    // ── Discipline Achievements (Tier-based) ─────────────────────────

    AchievementBadge(
      id: 'discipline_50',
      title: 'Bronze Medal',
      description: 'Reach a discipline score of 50',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFFCD7F32),
      type: AchievementType.discipline,
      requirement: 50,
    ),
    AchievementBadge(
      id: 'discipline_70',
      title: 'Silver Medal',
      description: 'Reach a discipline score of 70',
      icon: Icons.favorite_rounded,
      color: Color(0xFFC0C0C0),
      type: AchievementType.discipline,
      requirement: 70,
    ),
    AchievementBadge(
      id: 'discipline_expert',
      title: 'Gold Medal',
      description: 'Reach a discipline score of 90+',
      icon: Icons.shield_rounded,
      color: Color(0xFFFFD700),
      type: AchievementType.discipline,
      requirement: 90,
    ),
    AchievementBadge(
      id: 'discipline_master',
      title: 'Diamond Shield',
      description: 'Reach a discipline score of 100',
      icon: Icons.verified_rounded,
      color: Color(0xFFB9F2FF),
      type: AchievementType.discipline,
      requirement: 100,
    ),

  ];

  /// Get achievement by ID.
  static AchievementBadge? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get achievements by type.
  static List<AchievementBadge> getByType(AchievementType type) {
    return all.where((a) => a.type == type).toList();
  }

  /// Get locked achievements given a list of unlocked ones.
  static List<AchievementBadge> getLocked(List<AchievementBadge> unlocked) {
    final unlockedIds = unlocked.map((a) => a.id).toSet();
    return all.where((a) => !unlockedIds.contains(a.id)).toList();
  }

  /// Total badge count.
  static int get totalCount => all.length;
}

/// Helper to create IconData safely without const warnings.
IconData _iconFromCodePoint(int codePoint) {
  // ignore: non_const_argument_for_const_parameter
  return IconData(codePoint, fontFamily: 'MaterialIcons');
}

/// Smart reminder for motivational notifications.
class SmartReminder {
  final String id;
  final String goalId;
  final String message;
  final DateTime scheduleTime;
  final ReminderFrequency frequency;
  final bool enabled;
  final DateTime? lastSent;

  const SmartReminder({
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

/// Reminder frequency options.
enum ReminderFrequency {
  daily('Daily'),
  weekly('Weekly'),
  biWeekly('Bi-weekly'),
  monthly('Monthly'),
  once('Once');

  final String label;

  const ReminderFrequency(this.label);
}
