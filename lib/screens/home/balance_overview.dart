import 'package:flutter/material.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/extensions.dart';
import '../../widgets/common_widgets.dart';

/// Card showing total saved amount, progress bar, and target.
class BalanceOverview extends StatelessWidget {
  const BalanceOverview({super.key, required this.controller});

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
          Row(
            children: [
              Text('Total Saved', style: AppText.bodyMuted),
              const Spacer(),
              Flexible(
                child: controller.showBalance
                    ? Text(
                        '₱${totalSaved.money}',
                        style: AppText.titleLarge.copyWith(color: AppColors.lime),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      )
                    : const Text('₱ •••', style: AppText.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress.toDouble(),
              backgroundColor: AppColors.muted.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation(AppColors.lime),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('₱${totalTarget.money} target', style: AppText.caption),
              const Spacer(),
              Text('${(progress * 100).round()}%', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }
}
