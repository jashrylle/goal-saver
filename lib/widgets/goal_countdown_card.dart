import 'package:flutter/material.dart';
import '../state/goal_saver_controller.dart';
import '../utils/app_colors.dart';
import 'common_widgets.dart';

/// Card showing the nearest goal deadline with an animated countdown.
class GoalCountdownCard extends StatefulWidget {
  final GoalSaverController controller;

  const GoalCountdownCard({super.key, required this.controller});

  @override
  State<GoalCountdownCard> createState() => _GoalCountdownCardState();
}

class _GoalCountdownCardState extends State<GoalCountdownCard> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final goals = controller.goals.where((g) => !g.completed && !g.paused).toList();

    if (goals.isEmpty) return const SizedBox.shrink();

    // Find the closest deadline goal
    goals.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    final nearest = goals.first;
    final daysLeft = nearest.daysLeft;
    final isUrgent = daysLeft <= 7;
    final isDue = daysLeft <= 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final urgencyColor = isDue
        ? const Color(0xFFFF6B6B)
        : isUrgent
            ? const Color(0xFFFFA726)
            : controller.accentColor;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDue ? Icons.timer_off_rounded : Icons.timer_rounded,
              color: urgencyColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDue ? 'Overdue!' : 'Next Deadline',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: urgencyColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nearest.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Animated countdown
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: isDue ? 0 : daysLeft.clamp(0, 999)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isDue ? '0' : '$value',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: urgencyColor,
                    ),
                  ),
                  Text(
                    isDue ? 'overdue' : daysLeft == 1 ? 'day' : 'days',
                    style: TextStyle(fontSize: 10, color: mutedColor),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
