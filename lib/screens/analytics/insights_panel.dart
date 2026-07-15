import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Panel displaying key analytics insights with rich stat tiles
/// and personalized savings notes based on actual user data.
class InsightsPanel extends StatelessWidget {
  const InsightsPanel({super.key});

  /// Generates personalized savings notes based on the user's data.
  List<_SavingsNote> _generateNotes(GoalSaverController controller) {
    final notes = <_SavingsNote>[];

    // Streak-based notes
    if (controller.streakDays >= 30) {
      notes.add(const _SavingsNote(
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFF7043),
        title: 'Incredible streak!',
        body: 'You\'ve saved consistently for over a month. Your discipline is paying off!',
      ));
    } else if (controller.streakDays >= 7) {
      notes.add(const _SavingsNote(
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFF7043),
        title: 'Great week streak!',
        body: 'Keep up the momentum — weekly saving habits lead to long-term financial freedom.',
      ));
    } else if (controller.streakDays == 0) {
      notes.add(const _SavingsNote(
        icon: Icons.restart_alt_rounded,
        color: Color(0xFFFFA726),
        title: 'Start your streak today',
        body: 'Make a small deposit today to start building your savings habit again.',
      ));
    }

    // Progress-based notes
    final progress = controller.averageProgress;
    if (progress >= 0.9) {
      notes.add(const _SavingsNote(
        icon: Icons.emoji_events_rounded,
        color: Color(0xFFFFD700),
        title: 'Almost there!',
        body: 'You\'re over 90% done across your goals. Push through to the finish line!',
      ));
    } else if (progress >= 0.5) {
      notes.add(const _SavingsNote(
        icon: Icons.trending_up_rounded,
        color: AppColors.lime,
        title: 'Halfway milestone!',
        body: 'You\'ve crossed the halfway mark on average. Stay consistent to reach your targets.',
      ));
    } else if (progress < 0.2 && controller.allActiveGoals.isNotEmpty) {
      notes.add(const _SavingsNote(
        icon: Icons.lightbulb_rounded,
        color: Color(0xFFFFD93D),
        title: 'Tip: Small deposits add up',
        body: 'Even saving a little each day builds momentum. Try the suggested deposit amount.',
      ));
    }

    // History-based notes
    final history = controller.history;
    if (history.length >= 20) {
      notes.add(const _SavingsNote(
        icon: Icons.history_rounded,
        color: Color(0xFF00D9FF),
        title: 'Excellent track record!',
        body: 'You have 20+ savings entries. Consistent logging is the #1 habit of successful savers.',
      ));
    } else if (history.isEmpty) {
      notes.add(const _SavingsNote(
        icon: Icons.add_circle_outline_rounded,
        color: AppColors.lime,
        title: 'Log your first savings',
        body: 'Tap the Save Money button to record your first deposit and start tracking your progress.',
      ));
    }

    // Overdue goals
    final overdueCount = controller.allActiveGoals.where((g) => g.isOverdue).length;
    if (overdueCount > 0) {
      notes.add(_SavingsNote(
        icon: Icons.warning_rounded,
        color: AppColors.error,
        title: '$overdueCount goal${overdueCount > 1 ? 's' : ''} overdue',
        body: 'You have past-deadline goal${overdueCount > 1 ? 's' : ''}. Consider extending the deadline or making a catch-up deposit.',
      ));
    }

    // Discipline score note
    if (controller.disciplineScore >= 80) {
      notes.add(const _SavingsNote(
        icon: Icons.military_tech_rounded,
        color: AppColors.lime,
        title: 'Top saver status!',
        body: 'Your discipline score is exceptional. Share your saving strategy with others!',
      ));
    }

    // Limit to 3 most relevant notes
    return notes.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avgPace = controller.goals.isEmpty
        ? 0.0
        : controller.goals
                .map((g) => g.savingsPerWeek)
                .fold<double>(0.0, (a, b) => a + b) /
            controller.goals.length;

    final streakColor = controller.streakDays >= 7
        ? AppColors.lime
        : controller.streakDays >= 3
            ? const Color(0xFFFFA726)
            : AppColors.muted;

    final disciplineColor = controller.disciplineScore >= 80
        ? AppColors.lime
        : controller.disciplineScore >= 50
            ? const Color(0xFFFFA726)
            : const Color(0xFFFF7043);

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Your Stats',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lime,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Stat tiles ──────────────────────────────────────────────────
          Row(
            children: [
              _InsightTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: streakColor,
                label: 'Streak',
                value: '${controller.streakDays}d',
                subLabel: controller.streakDays >= 7 ? 'Amazing!' : 'Keep going!',
                valueColor: streakColor,
              ),
              const SizedBox(width: 10),
              _InsightTile(
                icon: Icons.military_tech_rounded,
                iconColor: disciplineColor,
                label: 'Discipline',
                value: '${controller.disciplineScore}/100',
                subLabel: controller.disciplineScore >= 80
                    ? 'Excellent'
                    : controller.disciplineScore >= 50
                        ? 'Good'
                        : 'Improve',
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
                subLabel: 'per week',
                valueColor: AppColors.lime,
              ),
            ],
          ),

          // ── Personalized savings notes ───────────────────────────────────
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.lime),
                const SizedBox(width: 6),
                Text(
                  'Personalized Tips',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.muted : AppColors.lightMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...notes.map((note) => _NoteCard(note: note, isDark: isDark)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Pressable(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label: $value'),
              backgroundColor: iconColor,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
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
