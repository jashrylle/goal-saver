import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Displays month-over-month savings comparison with percentage change.
class MonthComparisonCard extends StatelessWidget {
  const MonthComparisonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final monthlyData = controller.monthlySavingsData;

    if (monthlyData.length < 2) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: _buildEmpty(mutedColor),
      );
    }

    final currentMonth = monthlyData.last;
    final previousMonth = monthlyData[monthlyData.length - 2];
    final currentAmount = ((currentMonth['amount'] as num?)?.toDouble() ?? 0.0);
    final previousAmount = ((previousMonth['amount'] as num?)?.toDouble() ?? 0.0);
    final diff = currentAmount - previousAmount;
    final pctChange = previousAmount > 0 ? (diff / previousAmount * 100) : 0.0;
    final isUp = diff >= 0;

    // Average savings
    final totalAll = monthlyData.fold<double>(0, (s, d) => s + ((d['amount'] as num?)?.toDouble() ?? 0.0));
    final avgMonthly = monthlyData.isNotEmpty ? totalAll / monthlyData.length : 0.0;

    // Best month
    final bestMonth = monthlyData.reduce((a, b) => ((a['amount'] as num?)?.toDouble() ?? 0) > ((b['amount'] as num?)?.toDouble() ?? 0) ? a : b);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Month Comparison', style: AppText.title.copyWith(color: textColor)),
                    const SizedBox(height: 2),
                    Text('${currentMonth['month']} vs ${previousMonth['month']}', style: TextStyle(fontSize: 11, color: mutedColor)),
                  ],
                ),
              ),
              Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                   color: isUp ? const Color(0xFF5FDE9E) : const Color(0xFFFF6B6B), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          // Main comparison
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  label: 'Current Month',
                  value: controller.showBalance ? controller.formatMoney(currentAmount) : '•••',
                  color: controller.accentColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricBox(
                  label: 'Previous Month',
                  value: controller.showBalance ? controller.formatMoney(previousAmount) : '•••',
                  color: mutedColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Change indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isUp ? const Color(0xFF5FDE9E) : const Color(0xFFFF6B6B)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (isUp ? const Color(0xFF5FDE9E) : const Color(0xFFFF6B6B)).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                     size: 16, color: isUp ? const Color(0xFF5FDE9E) : const Color(0xFFFF6B6B)),
                const SizedBox(width: 6),
                Text(
                  '${isUp ? '+' : ''}${pctChange.toStringAsFixed(1)}% ${isUp ? 'increase' : 'decrease'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isUp ? const Color(0xFF5FDE9E) : const Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _statTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'Average / Month',
                  value: controller.showBalance ? controller.formatMoney(avgMonthly) : '•••',
                  color: const Color(0xFF00D9FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(
                  icon: Icons.emoji_events_rounded,
                  label: 'Best Month',
                  value: '${bestMonth['month']}',
                  color: const Color(0xFFFFD93D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox({required String label, required String value, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFFFFFFF).withValues(alpha: 0.05) : const Color(0xFF000000).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _statTile({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color mutedColor) {
    return Column(children: [
      Icon(Icons.compare_arrows_rounded, size: 36, color: mutedColor.withValues(alpha: 0.5)),
      const SizedBox(height: 8),
      Text('Need 2+ months data for comparison', style: TextStyle(fontSize: 12, color: mutedColor)),
    ]);
  }
}
