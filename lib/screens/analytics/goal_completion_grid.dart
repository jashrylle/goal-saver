import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/sheets/goal_details_sheet.dart';

/// Grid showing per-goal completion progress bars.
class GoalCompletionGrid extends StatefulWidget {
  const GoalCompletionGrid({super.key});

  @override
  State<GoalCompletionGrid> createState() => _GoalCompletionGridState();
}

class _GoalCompletionGridState extends State<GoalCompletionGrid> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final allGoals = controller.goals;
    final showCount = _expanded ? allGoals.length : allGoals.length.clamp(0, 4);
    final goals = allGoals.take(showCount).toList();
    if (goals.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.flag_rounded, color: AppColors.muted, size: 36),
            const SizedBox(height: 8),
            Text(
              'No goals yet',
              style: AppText.body.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Goal Progress',
                style: AppText.adaptive(context, AppText.title),
              ),
              const Spacer(),
              Text(
                '${allGoals.length} goal${allGoals.length != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 11, color: mutedColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...goals.map(
            (goal) {
              final pct = (goal.progress * 100).round();
              final progressColor = pct >= 100
                  ? const Color(0xFF00E676)
                  : pct >= 60
                      ? AppColors.lime
                      : const Color(0xFFFFA726);
              return Pressable(
                onTap: () => showGoalDetailsSheet(context, goal),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: goal.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(goal.icon, size: 14, color: goal.color),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              goal.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            goal.progressPercent,
                            style: TextStyle(
                              fontSize: 11,
                              color: progressColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: goal.progress,
                        backgroundColor: AppColors.muted.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(progressColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (controller.showBalance)
                      Text(
                        '${controller.formatMoney(goal.saved)} / ${controller.formatMoney(goal.target)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: mutedColor,
                        ),
                      ),
                  ],
                ),
              ),
            );
            },
          ),
          // View all / collapse toggle
          if (allGoals.length > 4)
            Pressable(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded ? 'Show less' : 'View all ${allGoals.length} goals',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lime,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.lime,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
