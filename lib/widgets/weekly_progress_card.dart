import 'package:flutter/material.dart';
import '../state/goal_saver_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'common_widgets.dart';

/// Mini weekly progress summary card with bar chart.
class WeeklyProgressCard extends StatelessWidget {
  final GoalSaverController controller;

  const WeeklyProgressCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final data = controller.weeklyContributions;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    double maxVal = 1.0;
    for (final item in data) {
      final val = item['value'] as double;
      if (val > maxVal) maxVal = val;
    }

    final total = data.fold<double>(0.0, (sum, item) => sum + (item['value'] as double));
    final avg = data.fold<double>(0.0, (sum, item) => sum + (item['value'] as double)) / data.length;

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
                  color: controller.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bar_chart_rounded, color: controller.accentColor, size: 17),
              ),
              const SizedBox(width: 8),
              Text('Weekly Progress', style: AppText.title.copyWith(color: textColor, fontSize: 13)),
              const Spacer(),
              Text(
                controller.showBalance
                    ? controller.formatMoney(total)
                    : '${controller.currencySymbol} •••',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: controller.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mini bar chart
          SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final label = item['label'] as String;
                final value = item['value'] as double;
                final fraction = maxVal == 0 ? 0.05 : (value / maxVal);
                final isToday = _isToday(label);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              color: isToday
                                  ? controller.accentColor
                                  : controller.accentColor.withValues(alpha: 0.3 + (fraction * 0.5)),
                            ),
                            height: (fraction * 30).clamp(4.0, 30.0),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label.substring(0, 1),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.normal,
                            color: isToday ? controller.accentColor : mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 11, color: mutedColor),
              const SizedBox(width: 3),
              Text(
                'Daily avg: ${controller.showBalance ? controller.formatMoney(avg) : "•••"}',
                style: TextStyle(fontSize: 9, color: mutedColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isToday(String label) {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayLabel = days[(now.weekday - 1) % 7];
    return label == todayLabel;
  }
}
