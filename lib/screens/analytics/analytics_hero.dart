import 'package:flutter/material.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/extensions.dart';
import '../../widgets/common_widgets.dart';

/// Hero summary card for the analytics tab.
class AnalyticsHero extends StatelessWidget {
  const AnalyticsHero({super.key, required this.controller});

  final GoalSaverController controller;

  @override
  Widget build(BuildContext context) {
    final totalSaved = controller.totalSaved;
    final totalTarget = controller.totalTarget;
    final progress = totalTarget == 0 ? 0 : totalSaved / totalTarget;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Savings Overview', style: AppText.title),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Saved', style: AppText.caption),
                    const SizedBox(height: 4),
                    Text(
                      controller.showBalance ? '₱${totalSaved.money}' : '₱ •••',
                      style: AppText.titleLarge.copyWith(color: AppColors.lime),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Target', style: AppText.caption),
                    const SizedBox(height: 4),
                    Text(
                      controller.showBalance ? '₱${totalTarget.money}' : '₱ •••',
                      style: AppText.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            minHeight: 8,
            value: progress.toDouble(),
            backgroundColor: AppColors.muted.withValues(alpha: 0.18),
            valueColor: const AlwaysStoppedAnimation(AppColors.lime),
          ),
          const SizedBox(height: 8),
          Text('${(progress * 100).round()}% complete', style: AppText.caption),
        ],
      ),
    );
  }
}
