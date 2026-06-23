import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/extensions.dart';
import 'common_widgets.dart';

/// Animated goal card shown in the home list.
class AnimatedGoalCard extends StatelessWidget {
  const AnimatedGoalCard({
    super.key,
    required this.goal,
    required this.index,
    required this.onTap,
  });

  final SavingsGoal goal;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final moneyNeeded = goal.moneyNeeded;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GlassCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.title, style: AppText.title),
                        const SizedBox(height: 4),
                        Text(goal.categoryName, style: AppText.caption),
                      ],
                    ),
                  ),
                  GoalStatusPill(goal: goal),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Money Needed', style: AppText.caption),
                        const SizedBox(height: 4),
                        Text(
                          '₱${moneyNeeded.money}',
                          style: AppText.title.copyWith(color: AppColors.lime),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Saved', style: AppText.caption),
                        const SizedBox(height: 4),
                        Text(
                          '₱${goal.saved.money}',
                          style: AppText.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                backgroundColor: AppColors.muted.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(goal.color),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  MilestoneIndicator(goal: goal),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${goal.progressPercent} • ${goal.timeLeft}',
                      style: AppText.caption,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row of milestone dots showing 25/50/75/100% progress.
class MilestoneIndicator extends StatelessWidget {
  const MilestoneIndicator({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final milestones = [0.25, 0.5, 0.75, 1.0];

    return Row(
      children: milestones.map((m) {
        final reached = progress >= m;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Icon(
            reached ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: reached ? AppColors.lime : AppColors.muted,
          ),
        );
      }).toList(),
    );
  }
}

/// Custom progress bar with optional milestone tick marks.
class SavingsProgressBar extends StatelessWidget {
  const SavingsProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.milestones = const [0.25, 0.5, 0.75, 1.0],
  });

  final double progress;
  final Color color;
  final List<double> milestones;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.muted.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress.clamp(0, 1),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        ...milestones.map((m) {
          return Positioned(
            left: m * 100,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: AppColors.muted.withValues(alpha: 0.4),
            ),
          );
        }),
      ],
    );
  }
}
