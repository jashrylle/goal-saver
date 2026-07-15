import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/sheets/goal_details_sheet.dart';

/// Card showing each goal's allocation with accurate target percentage and progress.
class AllocationCard extends StatelessWidget {
  const AllocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    // Use all non-deleted/archived goals for accurate allocation
    final allGoals = controller.allActiveGoals;
    final goals = allGoals.take(8).toList();
    final totalTarget = allGoals.fold<double>(0.0, (sum, g) => sum + g.target);
    final totalSaved = allGoals.fold<double>(0.0, (sum, g) => sum + g.saved);
    final remainingCount = allGoals.length - goals.length;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Allocation',
                style: AppText.adaptive(context, AppText.title),
              ),
              const Spacer(),
              if (totalTarget > 0)
                Text(
                  '${controller.showBalance ? controller.formatMoney(totalSaved) : '•••'} / ${controller.showBalance ? controller.formatMoney(totalTarget) : '•••'}',
                  style: TextStyle(fontSize: 10, color: AppColors.lime, fontWeight: FontWeight.w600),
                ),
              const SizedBox(width: 6),
              Icon(
                Icons.pie_chart_rounded,
                color: AppColors.lime.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (goals.isEmpty)
            Text(
              'No goals to display',
              style: TextStyle(color: mutedColor, fontSize: 13),
            )
          else
            ...goals.map(
              (goal) {
                final share = totalTarget == 0 ? 0.0 : (goal.target / totalTarget);
                final sharePct = (share * 100).round();
                final progress = goal.progress;

                return Pressable(
                  onTap: () => showGoalDetailsSheet(context, goal),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: goal.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Icon(goal.icon, size: 13, color: goal.color),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    controller.showBalance
                                        ? '${controller.formatMoney(goal.saved)} / ${controller.formatMoney(goal.target)}'
                                        : '${controller.currencySymbol} ••• / •••',
                                    style: TextStyle(fontSize: 9, color: mutedColor),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$sharePct%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).round()}% done',
                                  style: TextStyle(
                                    color: goal.color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            value: share.clamp(0.0, 1.0),
                            backgroundColor: AppColors.muted.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(goal.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (remainingCount > 0) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                '+ $remainingCount more goal${remainingCount > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 11, color: AppColors.lime, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
