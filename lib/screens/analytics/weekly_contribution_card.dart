import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Card showing per-day savings bars for the current week — interactive bar chart.
class WeeklyContributionCard extends StatelessWidget {
  const WeeklyContributionCard({super.key, required this.range});

  final dynamic range;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final data = controller.weeklyContributions;

    // Find max for scaling
    double maxVal = 1.0;
    for (final item in data) {
      final val = item['value'] as double;
      if (val > maxVal) maxVal = val;
    }

    final total = data.fold<double>(
      0.0,
      (sum, item) => sum + (item['value'] as double),
    );

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
                    Text(
                      'This Week',
                      style: AppText.title.copyWith(color: textColor),
                    ),
                    Text(
                      controller.showBalance
                          ? 'Total: ${controller.formatMoney(total)}'
                          : 'Total: ${controller.currencySymbol} •••',
                      style: AppText.caption
                          .copyWith(color: AppColors.lime),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.bar_chart_rounded,
                color: AppColors.lime.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Interactive column chart
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final label = item['label'] as String;
                final value = item['value'] as double;
                final barFraction = maxVal == 0 ? 0.0 : (value / maxVal);
                final isToday = _isToday(label);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (value > 0 && controller.showBalance)
                          Text(
                            _compactMoney(value),
                            style: AppText.caption.copyWith(
                              fontSize: 9,
                              color: AppColors.lime,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 3),
                        // Interactive bar — shows details on tap
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              final dayTotal = value;
                              final dayName = label;
                              _showDayDetail(context, controller, dayName, dayTotal);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutQuad,
                              transform: Matrix4.identity()..scale(1.0, barFraction.clamp(0.05, 1.0)),
                              alignment: Alignment.bottomCenter,
                              child: Transform(
                                transform: Matrix4.identity()..scale(1.0, 1.0 / barFraction.clamp(0.05, 1.0)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                    color: isToday
                                        ? AppColors.lime
                                        : value > 0
                                            ? AppColors.lime.withValues(alpha: 0.5)
                                            : AppColors.muted.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            final dayTotal = value;
                            final dayName = label;
                            _showDayDetail(context, controller, dayName, dayTotal);
                          },
                          child: Text(
                            label.substring(0, 1),
                            style: AppText.caption.copyWith(
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.normal,
                              color: isToday ? AppColors.lime : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetail(BuildContext context, GoalSaverController controller, String dayName, double amount) {
    final logsOnDay = controller.history.where((log) {
      final now = DateTime.now();
      final currentWeekday = now.weekday;
      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayIndex = days.indexOf(dayName);
      if (dayIndex == -1) return false;
      final dayDate = startOfWeek.add(Duration(days: dayIndex));
      return log.date.day == dayDate.day &&
          log.date.month == dayDate.month &&
          log.date.year == dayDate.year;
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.panel : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.lime, size: 20),
            const SizedBox(width: 8),
            Text(dayName, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.payments_rounded, size: 16, color: AppColors.lime),
                  const SizedBox(width: 6),
                  Text(
                    'Total Saved: ${controller.formatMoney(amount)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
              if (amount > 0) const SizedBox(height: 12),
              if (amount > 0 && logsOnDay.isNotEmpty) ...[
                const Text('Breakdown:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ...logsOnDay.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: AppColors.lime),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.goalTitle,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '+${controller.formatMoney(log.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.lime),
                      ),
                    ],
                  ),
                )),
              ],
              if (amount == 0) ...[
                const SizedBox(height: 8),
                const Text('No savings recorded on this day.', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.lime)),
          ),
        ],
      ),
    );
  }

  bool _isToday(String label) {
    final today = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayLabel = days[(today.weekday - 1) % 7];
    return label == todayLabel;
  }

  String _compactMoney(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}
