import 'package:flutter/material.dart';
import '../state/goal_saver_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'common_widgets.dart';

/// Smart Savings Coach — provides personalized, actionable advice based on
/// the user's actual savings data, streaks, discipline, and goal status.
class SavingsCoachCard extends StatelessWidget {
  final GoalSaverController controller;

  const SavingsCoachCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    final coach = _SavingsCoach(controller);
    final advice = coach.generate();

    if (advice == null) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      controller.accentColor.withValues(alpha: 0.7),
                      controller.accentColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(advice.icon, color: AppColors.ink, size: 17),
              ),
              const SizedBox(width: 8),
              Text(
                'Savings Coach',
                style: AppText.title.copyWith(color: textColor, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: controller.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  advice.priority,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: controller.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: advice.color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: advice.color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: advice.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        advice.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: advice.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        advice.message,
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedColor,
                          height: 1.45,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 5,
                      ),
                      if (advice.actionLabel != null) ...[
                        const SizedBox(height: 8),
                        Pressable(
                          onTap: advice.onAction,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: advice.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: advice.color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  advice.actionLabel!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: advice.color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: advice.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pure function engine for generating savings advice.
class _SavingsCoach {
  final GoalSaverController controller;
  _SavingsCoach(this.controller);

  _CoachAdvice? generate() {
    final goals = controller.allActiveGoals;
    final streak = controller.streakDays;
    final discipline = controller.disciplineScore;
    final history = controller.history;

    // Priority: urgent > important > informative

    // 1. Overdue goals — most urgent
    final overdue = goals.where((g) => g.isOverdue).toList();
    if (overdue.isNotEmpty) {
      final goal = overdue.first;
      return _CoachAdvice(
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFFF7043),
        title: '⚠ Goal Overdue!',
        message: '"${goal.title}" is past its deadline (${goal.timeLeft}). '
            'Consider extending the date or making a catch-up deposit of '
            '${controller.formatMoney(goal.recommendedDeposit)} to get back on track.',
        priority: 'URGENT',
        actionLabel: null,
        onAction: null,
      );
    }

    // 2. At-risk goals
    final atRisk = goals.where((g) => g.planStatus.name == 'atRisk').toList();
    if (atRisk.isNotEmpty) {
      final goal = atRisk.first;
      return _CoachAdvice(
        icon: Icons.trending_down_rounded,
        color: const Color(0xFFFFA726),
        title: '⚠ Behind Schedule',
        message: '"${goal.title}" needs ${controller.formatMoney(goal.remaining)} '
            'in ${goal.daysLeft} days. Try saving ${controller.formatMoney(goal.savingsPerDay)}/day '
            'or extend the deadline to make it manageable.',
        priority: 'ATTENTION',
        actionLabel: null,
        onAction: null,
      );
    }

    // 3. New user — no history
    if (history.isEmpty && goals.isEmpty) {
      return _CoachAdvice(
        icon: Icons.lightbulb_rounded,
        color: const Color(0xFFFFD93D),
        title: 'Let\'s Get Started! 🚀',
        message: 'Create your first savings goal to begin tracking your progress. '
            'Even saving small amounts consistently builds powerful financial habits.',
        priority: 'WELCOME',
        actionLabel: 'Add Goal →',
        onAction: null,
      );
    }

    // 4. Streak encouragement
    if (streak >= 7 && streak < 30) {
      final daysTo30 = 30 - streak;
      return _CoachAdvice(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF7043),
        title: '$streak-Day Streak! 🔥',
        message: 'You\'re just $daysTo30 days away from a 30-day streak milestone! '
            'Keep saving daily to unlock the "Unstoppable" achievement badge.',
        priority: 'KEEP GOING',
        actionLabel: null,
        onAction: null,
      );
    }

    // 5. Discipline improvement
    if (discipline < 50 && goals.isNotEmpty) {
      return _CoachAdvice(
        icon: Icons.fitness_center_rounded,
        color: controller.accentColor,
        title: 'Build Your Discipline 💪',
        message: 'Your discipline score is $discipline/100. Try saving consistently '
            'every ${goals.first.frequency.label.toLowerCase()} to build momentum. '
            'Consistency is the #1 habit of successful savers!',
        priority: 'IMPROVE',
        actionLabel: null,
        onAction: null,
      );
    }

    // 6. Great job — encouragement
    if (discipline >= 80 && streak >= 7) {
      return _CoachAdvice(
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFFD700),
        title: 'You\'re a Saving Pro! 🏆',
        message: 'With a $discipline discipline score and a $streak-day streak, '
            'you\'re building exceptional financial habits. Keep it up!',
        priority: 'EXCELLENT',
        actionLabel: null,
        onAction: null,
      );
    }

    // 7. Balanced default
    if (goals.isNotEmpty) {
      final nextGoal = goals.first;
      return _CoachAdvice(
        icon: Icons.trending_up_rounded,
        color: controller.accentColor,
        title: 'Stay on Track 📈',
        message: 'Your next recommended deposit is ${controller.formatMoney(nextGoal.recommendedDeposit)} '
            'for "${nextGoal.title}". Saving consistently each ${nextGoal.frequency.label.toLowerCase()} '
            'will help you reach your target by ${nextGoal.timeLeft}.',
        priority: 'ON TRACK',
        actionLabel: 'Save Now →',
        onAction: null,
      );
    }

    return null;
  }
}

/// Data model for a single coach advice item.
class _CoachAdvice {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String priority;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CoachAdvice({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.priority,
    this.actionLabel,
    this.onAction,
  });
}
