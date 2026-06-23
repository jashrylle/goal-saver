import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Grid showing per-goal completion progress bars.
class GoalCompletionGrid extends StatelessWidget {
  const GoalCompletionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final goals = controller.goals.take(4).toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Completion', style: AppText.title),
          const SizedBox(height: 12),
          ...goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(goal.icon, size: 16, color: goal.color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(goal.title, style: AppText.body)),
                      Text(goal.progressPercent, style: AppText.caption),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    minHeight: 6,
                    value: goal.progress,
                    backgroundColor: AppColors.muted.withValues(alpha: 0.18),
                    valueColor: AlwaysStoppedAnimation(goal.color),
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
