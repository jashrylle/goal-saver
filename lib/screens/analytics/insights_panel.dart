import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Panel displaying key analytics insights: weekly pace, discipline score, streak.
class InsightsPanel extends StatelessWidget {
  const InsightsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final avgPace = controller.goals.isEmpty
        ? 0.0
        : controller.goals
                .map((g) => g.savingsPerWeek)
                .fold<double>(0.0, (a, b) => a + b) /
            controller.goals.length;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insights', style: AppText.title),
          const SizedBox(height: 10),
          Text('Avg weekly pace: ₱${avgPace.toStringAsFixed(0)}', style: AppText.body),
          const SizedBox(height: 6),
          Text('Discipline score: ${controller.disciplineScore}/100', style: AppText.body),
          const SizedBox(height: 6),
          Text('Streak: ${controller.streakDays} days', style: AppText.body),
        ],
      ),
    );
  }
}
