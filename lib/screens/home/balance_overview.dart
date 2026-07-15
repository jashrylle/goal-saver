import 'package:flutter/material.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Card showing total saved amount, progress bar, and target.
class BalanceOverview extends StatelessWidget {
  const BalanceOverview({super.key, required this.controller});

  final GoalSaverController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

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
              Text(
                'Total Saved',
                style: AppText.bodyMuted.copyWith(color: mutedColor),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  controller.showBalance
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: mutedColor,
                  size: 18,
                ),
                onPressed: () {
                  controller.toggleBalanceVisibility();
                },
              ),
              const Spacer(),
              Flexible(
                child: controller.showBalance
                    ? Text(
                        controller.formatMoney(totalSaved),
                        style: AppText.titleLarge.copyWith(color: AppColors.lime),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      )
                    : Text(
                        '${controller.currencySymbol} •••',
                        style: AppText.titleLarge.copyWith(color: textColor),
                      ),
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
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 12, color: mutedColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        controller.showBalance
                            ? '${controller.formatMoney(totalSaved)} saved of ${controller.formatMoney(totalTarget)}'
                            : '${controller.currencySymbol} ••• of •••',
                        style: AppText.caption.copyWith(color: mutedColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).round()}%',
                style: AppText.caption.copyWith(color: mutedColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
