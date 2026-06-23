import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/extensions.dart';
import '../common_widgets.dart';
import '../goal_card.dart';
import 'productivity_sheet.dart';

/// Opens the goal-details bottom sheet.
Future<void> showGoalDetailsSheet(BuildContext context, SavingsGoal goal) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GoalDetailsSheet(goal: goal),
  );
}

/// Bottom sheet showing full details and quick actions for a goal.
class GoalDetailsSheet extends StatelessWidget {
  const GoalDetailsSheet({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final progress = goal.progress;
    final moneyNeeded = goal.moneyNeeded;

    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: goal.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(goal.icon, color: goal.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(goal.title, style: AppText.titleLarge)),
              GoalStatusPill(goal: goal),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: GoalMetaTile(icon: Icons.payments_rounded, label: 'Money Needed', value: '₱${moneyNeeded.money}')),
              const SizedBox(width: 10),
              Expanded(child: GoalMetaTile(icon: Icons.savings_rounded, label: 'Saved', value: '₱${goal.saved.money}')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: GoalMetaTile(icon: Icons.schedule_rounded, label: 'Deadline', value: goal.timeLeft)),
              const SizedBox(width: 10),
              Expanded(child: GoalMetaTile(icon: Icons.trending_up_rounded, label: 'Progress', value: goal.progressPercent)),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            backgroundColor: AppColors.muted.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation(goal.color),
          ),
          const SizedBox(height: 14),
          MilestoneIndicator(goal: goal),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Pressable(
                  onTap: () {
                    Navigator.pop(context);
                    showProductivitySheet(
                      context,
                      title: 'Add Savings',
                      icon: Icons.savings_rounded,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.lime.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: AppColors.lime),
                        SizedBox(width: 6),
                        Text('Add Savings', style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Pressable(
                  onTap: () {
                    if (goal.completed) {
                      controller.undoCompletion(goal);
                    } else {
                      controller.markCompleted(goal);
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.lime, width: 1.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          goal.completed ? Icons.undo_rounded : Icons.check_circle_rounded,
                          color: AppColors.lime,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          goal.completed ? 'Undo' : 'Complete',
                          style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
