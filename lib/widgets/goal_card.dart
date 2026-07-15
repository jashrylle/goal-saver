import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../state/goal_saver_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
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
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
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
                        Text(goal.title, style: AppText.title.copyWith(color: textColor)),
                        const SizedBox(height: 4),
                        Text(goal.category.label, style: AppText.caption.copyWith(color: mutedColor)),
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
                        Text('Money Needed', style: AppText.caption.copyWith(color: mutedColor)),
                        const SizedBox(height: 4),
                        Text(
                          controller.showBalance
                              ? controller.formatMoney(moneyNeeded)
                              : '${controller.currencySymbol} •••',
                          style: AppText.title.copyWith(color: AppColors.lime),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Saved', style: AppText.caption.copyWith(color: mutedColor)),
                        const SizedBox(height: 4),
                        Text(
                          controller.showBalance
                              ? controller.formatMoney(goal.saved)
                              : '${controller.currencySymbol} •••',
                          style: AppText.title.copyWith(color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Recommended this period chip + plan-adjusted badge
              if (!goal.completed && goal.recommendedDeposit > 0) ...[                
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.savings_rounded, size: 11, color: AppColors.lime),
                    const SizedBox(width: 4),
                    Text(
                      'Recommended ${goal.frequency.label.toLowerCase()}: ${controller.showBalance ? controller.formatMoney(goal.recommendedDeposit) : "•••"}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.lime,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (goal.plan != null && goal.plan!.currentIntervalAmount != goal.plan!.baseIntervalAmount)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA726).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Plan adjusted',
                          style: TextStyle(
                            fontSize: 9,
                            color: const Color(0xFFFFA726),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                backgroundColor: AppColors.muted.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(goal.color),
              ),
          const SizedBox(height: 10),
          // Exact remaining/completed amount display
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      goal.completed ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 12,
                      color: goal.completed ? const Color(0xFF00E676) : mutedColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        goal.completed
                            ? 'Completed! Saved ${controller.showBalance ? controller.formatMoney(goal.saved) : "•••"}'
                            : '${controller.showBalance ? controller.formatMoney(goal.remaining) : "•••"} remaining of ${controller.showBalance ? controller.formatMoney(goal.target) : "•••"}',
                        style: TextStyle(
                          fontSize: 10,
                          color: goal.completed ? const Color(0xFF00E676) : mutedColor,
                          fontWeight: goal.completed ? FontWeight.w700 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  MilestoneIndicator(goal: goal),
                  const SizedBox(width: 8),
                  Text(
                    '${goal.progressPercent} • ${goal.timeLeft}',
                    style: AppText.caption.copyWith(color: mutedColor),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ],
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
