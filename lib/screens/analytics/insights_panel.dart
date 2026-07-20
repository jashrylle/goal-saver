import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Panel displaying dynamic, real-time financial insights based on actual
/// user data — streak, discipline, weekly pace, and personalized savings notes.
class InsightsPanel extends StatelessWidget {
  const InsightsPanel({super.key});

  /// Generates personalized, data-driven savings notes.
  List<_SavingsNote> _generateNotes(GoalSaverController controller) {
    final notes = <_SavingsNote>[];

    // ── Streak-based insights ──────────────────────────────────────────
    if (controller.streakDays >= 30) {
      notes.add(const _SavingsNote(
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFF7043),
        title: '🔥 Unstoppable Streak!',
        body:
            'You\'ve saved consistently for over a month. This level of discipline is exceptional — keep it up!',
      ));
    } else if (controller.streakDays >= 14) {
      notes.add(_SavingsNote(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF7043),
        title: '🔥 Two-Week Streak!',
        body:
            '${controller.streakDays} days and counting! Consistent saving is building a powerful financial habit.',
      ));
    } else if (controller.streakDays >= 7) {
      notes.add(const _SavingsNote(
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFFA726),
        title: '🔥 Week-Long Streak!',
        body:
            '7-day streak achieved! You\'re building momentum — aim for 14 days to unlock the next milestone.',
      ));
    } else if (controller.streakDays >= 3) {
      notes.add(_SavingsNote(
        icon: Icons.fitness_center_rounded,
        color: const Color(0xFFFFA726),
        title: '💪 Getting Started!',
        body:
            '${controller.streakDays}-day streak! Save again tomorrow to hit a full week and unlock bonus XP.',
      ));
    } else if (controller.streakDays == 0 && controller.history.isNotEmpty) {
      notes.add(const _SavingsNote(
        icon: Icons.restart_alt_rounded,
        color: Color(0xFFFFA726),
        title: '🔄 Streak Reset',
        body:
            'Your streak ended. No worries! Make a small deposit today to start a new streak and regain momentum.',
      ));
    } else if (controller.history.isEmpty) {
      notes.add(const _SavingsNote(
        icon: Icons.add_circle_outline_rounded,
        color: AppColors.lime,
        title: '🎯 First Step',
        body:
            'Log your first savings entry to start tracking progress. Even a small amount builds the habit!',
      ));
    }

    // ── Progress-based insights ────────────────────────────────────────
    final progress = controller.averageProgress;
    final activeGoals = controller.allActiveGoals.length;

    if (progress >= 0.95 && activeGoals > 0) {
      notes.add(const _SavingsNote(
        icon: Icons.emoji_events_rounded,
        color: Color(0xFFFFD700),
        title: '🏆 Almost Champion!',
        body:
            'You\'re over 95% done across all active goals. The finish line is in sight — finish strong!',
      ));
    } else if (progress >= 0.75) {
      notes.add(const _SavingsNote(
        icon: Icons.trending_up_rounded,
        color: AppColors.lime,
        title: '📈 Strong Progress!',
        body:
            'Over 75% toward your targets. Your consistent deposits are paying off — keep pushing!',
      ));
    } else if (progress >= 0.5) {
      notes.add(const _SavingsNote(
        icon: Icons.trending_up_rounded,
        color: AppColors.lime,
        title: '🎯 Halfway There!',
        body:
            'You\'ve crossed the 50% mark! Stay consistent and you\'ll reach your targets in no time.',
      ));
    } else if (progress < 0.2 && activeGoals > 0) {
      notes.add(const _SavingsNote(
        icon: Icons.lightbulb_rounded,
        color: Color(0xFFFFD93D),
        title: '💡 Keep Going!',
        body:
            'Small deposits add up quickly. Try saving the recommended amount each interval to stay on track.',
      ));
    }

    // ── Discipline-based insights ──────────────────────────────────────
    if (controller.disciplineScore >= 90) {
      notes.add(const _SavingsNote(
        icon: Icons.military_tech_rounded,
        color: AppColors.lime,
        title: '🏅 Elite Saver!',
        body:
            'Your discipline score is in the top tier. You\'re a role model for consistent saving!',
      ));
    } else if (controller.disciplineScore >= 70) {
      notes.add(const _SavingsNote(
        icon: Icons.military_tech_rounded,
        color: AppColors.lime,
        title: '🌟 Strong Discipline',
        body:
            'Great consistency! Your savings habits are well above average. Aim for 90+ to reach elite status.',
      ));
    }

    // ── Goal completion insights ───────────────────────────────────────
    final completed = controller.allActiveGoals.where((g) => g.completed).length;
    if (completed >= 5) {
      notes.add(const _SavingsNote(
        icon: Icons.checklist_rounded,
        color: Color(0xFF5FDE9E),
        title: '✅ Serial Achiever!',
        body:
            'You\'ve completed 5+ goals! Each completed goal builds financial confidence and momentum.',
      ));
    } else if (completed >= 1) {
      notes.add(_SavingsNote(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF5FDE9E),
        title: '🎉 Goal Completed!',
        body:
            'You\'ve successfully completed $completed goal${completed > 1 ? 's' : ''}! Celebrate your progress and set your next target.',
      ));
    }

    // ── Overdue goals ──────────────────────────────────────────────────
    final overdueCount =
        controller.allActiveGoals.where((g) => g.isOverdue).length;
    if (overdueCount > 0) {
      notes.add(_SavingsNote(
        icon: Icons.warning_rounded,
        color: AppColors.error,
        title: '⚠️ $overdueCount Goal${overdueCount > 1 ? 's' : ''} Overdue',
        body:
            'You have past-deadline goal${overdueCount > 1 ? 's' : ''}. Consider extending the date or making a catch-up deposit to get back on track.',
      ));
    }

    // ── Total saved milestone ──────────────────────────────────────────
    final symbol = controller.currencySymbol;
    if (controller.totalSaved >= 100000) {
      notes.add(_SavingsNote(
        icon: Icons.savings_rounded,
        color: const Color(0xFFFFD700),
        title: '💰 Six-Figure Saver!',
        body:
            'You\'ve saved over $symbol${controller.formatMoney(100000)}! That\'s an incredible financial achievement. You\'re building serious wealth!',
      ));
    } else if (controller.totalSaved >= 50000) {
      notes.add(_SavingsNote(
        icon: Icons.savings_rounded,
        color: const Color(0xFF00D9FF),
        title: '💎 Major Milestone!',
        body:
            'You\'ve saved over $symbol${controller.formatMoney(50000)}! This is a significant achievement. Keep going to reach six figures!',
      ));
    } else if (controller.totalSaved >= 10000) {
      notes.add(_SavingsNote(
        icon: Icons.savings_rounded,
        color: AppColors.lime,
        title: '🌟 Saving Goal Achieved!',
        body:
            'You\'ve saved over $symbol${controller.formatMoney(10000)}! This shows real commitment to your financial goals.',
      ));
    }

    // ── History count insight ──────────────────────────────────────────
    final logCount = controller.history.length;
    if (logCount >= 50) {
      notes.add(const _SavingsNote(
        icon: Icons.history_rounded,
        color: Color(0xFF00D9FF),
        title: '📊 50+ Logs!',
        body:
            'You\'ve logged 50+ savings entries. Detailed tracking is the #1 habit of successful savers.',
      ));
    } else if (logCount >= 20) {
      notes.add(const _SavingsNote(
        icon: Icons.history_rounded,
        color: Color(0xFF00D9FF),
        title: '📊 20+ Logs!',
        body:
            'You have 20+ savings entries. Consistent logging builds awareness and accountability.',
      ));
    }

    // Limit to top 4 most relevant notes (prioritize by severity/positivity)
    return notes.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    // Dynamic computed values
    final avgPace = controller.goals.isEmpty
        ? 0.0
        : controller.goals
                .map((g) => g.savingsPerWeek)
                .fold<double>(0.0, (a, b) => a + b) /
            controller.goals.length;

    final totalSaved = controller.totalSaved;
    final activeCount = controller.allActiveGoals.length;
    final completedCount =
        controller.allActiveGoals.where((g) => g.completed).length;

    // Color-coded streak
    final streakColor = controller.streakDays >= 14
        ? const Color(0xFFFF7043)
        : controller.streakDays >= 7
            ? AppColors.lime
            : controller.streakDays >= 3
                ? const Color(0xFFFFA726)
                : AppColors.muted;

    final streakLabel = controller.streakDays >= 14
        ? 'On Fire!'
        : controller.streakDays >= 7
            ? 'Great!'
            : controller.streakDays >= 3
                ? 'Good Start'
                : 'No Streak';

    // Color-coded discipline
    final disciplineColor = controller.disciplineScore >= 80
        ? AppColors.lime
        : controller.disciplineScore >= 50
            ? const Color(0xFFFFA726)
            : const Color(0xFFFF7043);

    final disciplineLabel = controller.disciplineScore >= 80
        ? 'Excellent'
        : controller.disciplineScore >= 50
            ? 'Good'
            : 'Needs Work';

    // Weekly pace insight
    final paceLabel = avgPace >= 1000
        ? 'Fast Pace'
        : avgPace >= 500
            ? 'Steady'
            : avgPace > 0
                ? 'Building'
                : 'No Data';

    final notes = _generateNotes(controller);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Insights',
                style: AppText.adaptive(context, AppText.title),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$activeCount active · $completedCount done',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lime,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Dynamic stat tiles ────────────────────────────────────────
          Row(
            children: [
              _InsightTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: streakColor,
                label: 'Streak',
                value: '${controller.streakDays}d',
                subLabel: controller.streakDays > 0 ? streakLabel : 'Start today',
                valueColor: streakColor,
              ),
              const SizedBox(width: 10),
              _InsightTile(
                icon: Icons.military_tech_rounded,
                iconColor: disciplineColor,
                label: 'Discipline',
                value: '${controller.disciplineScore}/100',
                subLabel: disciplineLabel,
                valueColor: disciplineColor,
              ),
              const SizedBox(width: 10),
              _InsightTile(
                icon: Icons.speed_rounded,
                iconColor: AppColors.lime,
                label: 'Wkly Pace',
                value: controller.showBalance
                    ? controller.formatMoney(avgPace)
                    : '•••',
                subLabel: paceLabel,
                valueColor: AppColors.lime,
              ),
            ],
          ),

          // ── Progress overview bar ─────────────────────────────────────
          if (activeCount > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.muted.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      size: 16, color: AppColors.lime),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total progress: ${(controller.averageProgress * 100).round()}% across $activeCount goal${activeCount != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: controller.averageProgress,
                            backgroundColor:
                                AppColors.muted.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(
                                controller.accentColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    controller.showBalance
                        ? controller.formatMoney(totalSaved)
                        : '•••',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: controller.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Personalized data-driven notes ────────────────────────────
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: AppColors.lime),
                const SizedBox(width: 6),
                Text(
                  'Personalized Tips',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...notes.map((note) => _NoteCard(note: note, isDark: isDark)),
          ],

          // Empty state
          if (notes.isEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 36,
                      color: mutedColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'Start saving to see personalized insights',
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subLabel,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subLabel;
  final Color valueColor;

  void _showDetail(BuildContext context, GoalSaverController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String title;
    String body;
    switch (label) {
      case 'Streak':
        title = 'Savings Streak';
        body = controller.streakDays >= 30
            ? '🔥 $controller.streakDays days! You\'ve saved every day for over a month. This is world-class consistency!'
            : controller.streakDays >= 14
                ? '🔥 $controller.streakDays days! Two weeks of consistent saving — your financial habits are becoming automatic.'
                : controller.streakDays >= 7
                    ? '🔥 $controller.streakDays days! A full week of savings. Keep going to reach 14 days!'
                    : controller.streakDays >= 3
                        ? '💪 $controller.streakDays days! Good start. Save again tomorrow to reach a full week.'
                        : controller.streakDays == 0 && controller.history.isNotEmpty
                            ? '🔄 Your streak reset. Log a savings today to start a new one!'
                            : '🎯 No streaks yet. Log your first savings to begin building momentum.';
        break;
      case 'Discipline':
        title = 'Discipline Score';
        body = controller.disciplineScore >= 80
            ? '🌟 ${controller.disciplineScore}/100 — Excellent! Your savings consistency, progress, and history are all top-notch.'
            : controller.disciplineScore >= 50
                ? '👍 ${controller.disciplineScore}/100 — Good foundation. To improve, try saving daily and completing more goals.'
                : '📈 ${controller.disciplineScore}/100 — Room to grow. Small daily deposits build consistency fast!';
        break;
      default:
        title = 'Weekly Pace';
        final avgPace = controller.goals.isEmpty
            ? 0.0
            : controller.goals
                    .map((g) => g.savingsPerWeek)
                    .fold<double>(0.0, (a, b) => a + b) /
                controller.goals.length;
        body = avgPace > 0
            ? 'Your current weekly savings pace is ${controller.formatMoney(avgPace)}. '
                '${avgPace >= 1000 ? "You're saving fast! Great momentum." : avgPace >= 500 ? "Steady pace — increase slightly to accelerate your progress." : "Start small — even $avgPace/week builds up over time."}'
            : 'Add savings to establish your weekly pace.';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.panel : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: valueColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(body,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.muted : AppColors.lightMuted,
                    height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Close', style: TextStyle(color: AppColors.lime)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Pressable(
        onTap: () => _showDetail(context, controller),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.muted : AppColors.lightMuted,
                ),
              ),
              Text(
                subLabel,
                style: TextStyle(
                  color: iconColor.withValues(alpha: 0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data model for a single savings note/tip.
class _SavingsNote {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _SavingsNote({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

/// Card UI for a single savings note.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.isDark});

  final _SavingsNote note;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: note.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: note.color.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: note.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(note.icon, color: note.color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: note.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    note.body,
                    style: TextStyle(
                      fontSize: 11,
                      color: mutedColor,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
