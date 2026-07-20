import 'package:flutter/material.dart';
import '../state/goal_saver_controller.dart';
import '../utils/app_colors.dart';
import 'common_widgets.dart';

/// Monthly savings summary card showing this month's overview.
class MonthlySummaryCard extends StatelessWidget {
  final GoalSaverController controller;

  const MonthlySummaryCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    final now = DateTime.now();
    final thisMonth = now.month;
    final thisYear = now.year;

    final thisMonthTotal = controller.history
        .where((log) => log.date.month == thisMonth && log.date.year == thisYear && log.amount > 0)
        .fold<double>(0.0, (sum, log) => sum + log.amount);

    // Previous month
    final prevMonth = thisMonth == 1 ? 12 : thisMonth - 1;
    final prevYear = thisMonth == 1 ? thisYear - 1 : thisYear;
    final prevMonthTotal = controller.history
        .where((log) => log.date.month == prevMonth && log.date.year == prevYear && log.amount > 0)
        .fold<double>(0.0, (sum, log) => sum + log.amount);

    final change = prevMonthTotal > 0
        ? ((thisMonthTotal - prevMonthTotal) / prevMonthTotal * 100).round()
        : thisMonthTotal > 0 ? 100 : 0;

    final isUp = change >= 0;
    final monthName = const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][thisMonth - 1];

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF52B788).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF52B788), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$monthName Summary',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mutedColor),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.showBalance
                      ? controller.formatMoney(thisMonthTotal)
                      : '${controller.currencySymbol} •••',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: controller.accentColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isUp ? const Color(0xFF00E676) : const Color(0xFFFF6B6B)).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 14,
                  color: isUp ? const Color(0xFF00E676) : const Color(0xFFFF6B6B),
                ),
                const SizedBox(width: 2),
                Text(
                  '${isUp ? '+' : ''}$change%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isUp ? const Color(0xFF00E676) : const Color(0xFFFF6B6B),
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
