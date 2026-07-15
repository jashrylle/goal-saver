import 'package:flutter/material.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Hero summary card for the analytics tab — shows total saved vs target with ring-style progress.
class AnalyticsHero extends StatelessWidget {
  const AnalyticsHero({super.key, required this.controller});

  final GoalSaverController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final totalSaved = controller.savedInSelectedRange;
    final totalTarget = controller.targetInSelectedRange;
    final progress =
        totalTarget == 0 ? 0.0 : (totalSaved / totalTarget).clamp(0.0, 1.0);
    final pct = (progress * 100).round();

    final isAhead = totalSaved >= totalTarget * 0.8;
    final statusColor = pct >= 100
        ? const Color(0xFF00E676)
        : pct >= 60
            ? AppColors.lime
            : const Color(0xFFFF7043);
    final statusLabel = pct >= 100
        ? 'Goal Reached!'
        : pct >= 60
            ? 'On Track'
            : 'Needs Attention';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${controller.range.label} Overview',
                      style: AppText.caption.copyWith(color: mutedColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.showBalance
                          ? controller.formatMoney(totalSaved)
                          : '${controller.currencySymbol} •••',
                      style: AppText.hero.copyWith(
                        fontSize: 32,
                        color: AppColors.lime,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.showBalance
                          ? 'of ${controller.formatMoney(totalTarget)} target'
                          : 'of ••• target',
                      style: AppText.caption.copyWith(color: mutedColor),
                    ),
                  ],
                ),
              ),
              // Circular progress indicator
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.muted.withValues(alpha: 0.15),
                      ),
                    ),
                    CircularProgressIndicator(
                      value: progress.toDouble(),
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                    Text(
                      '$pct%',
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAhead
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: AppText.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
