import 'package:flutter/material.dart';
import '../state/goal_saver_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'common_widgets.dart';

/// Card showing the most recent savings activity entries.
class RecentActivityCard extends StatelessWidget {
  final GoalSaverController controller;

  const RecentActivityCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final history = controller.history;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    if (history.isEmpty) return const SizedBox.shrink();

    final recent = history.take(5).toList();

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded, color: Color(0xFF00D9FF), size: 17),
              ),
              const SizedBox(width: 8),
              Text('Recent Activity', style: AppText.title.copyWith(color: textColor, fontSize: 13)),
              const Spacer(),
              Text(
                '${history.length} total',
                style: TextStyle(fontSize: 10, color: mutedColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...recent.map((log) {
            // Find the matching goal for color
            final goal = controller.allActiveGoals.where((g) => g.id == log.goalId).firstOrNull;
            final goalColor = goal?.color ?? controller.accentColor;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: log.amount > 0 ? goalColor : AppColors.muted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.goalTitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          log.formattedDate,
                          style: TextStyle(fontSize: 9, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    log.amount > 0
                        ? '+${controller.showBalance ? controller.formatMoney(log.amount) : "•••"}'
                        : 'Missed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: log.amount > 0 ? goalColor : AppColors.muted,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
