import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/extensions.dart';
import '../../widgets/common_widgets.dart';

/// Card showing each goal's target amount allocation.
class AllocationCard extends StatelessWidget {
  const AllocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final goals = controller.goals.take(4).toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Allocation', style: AppText.title),
          const SizedBox(height: 12),
          ...goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(goal.icon, size: 16, color: goal.color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(goal.title, style: AppText.body)),
                  Text('₱${goal.target.money}', style: AppText.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
