import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Card showing monthly savings data with trend indicators — interactive.
class MonthlyTrendCard extends StatelessWidget {
  const MonthlyTrendCard({super.key, required this.range});

  final dynamic range;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final data = controller.monthlySavingsData;

    // Compute overall trend: compare last 3 months vs prior 3
    double recentTotal = 0;
    double priorTotal = 0;
    for (int i = 0; i < data.length; i++) {
      final amt = data[i]['amount'] as double;
      if (i >= data.length - 3) {
        recentTotal += amt;
      } else {
        priorTotal += amt;
      }
    }
    final trendUp = recentTotal >= priorTotal;

    // find max for mini spark bars
    double maxAmt = 1.0;
    for (final d in data) {
      final a = d['amount'] as double;
      if (a > maxAmt) maxAmt = a;
    }

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
                      'Monthly Savings',
                      style: AppText.title.copyWith(color: textColor),
                    ),
                    Row(
                      children: [
                        Icon(
                          trendUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color: trendUp
                              ? AppColors.lime
                              : const Color(0xFFFF7043),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trendUp ? 'Trending up' : 'Trending down',
                          style: AppText.caption.copyWith(
                            color: trendUp
                                ? AppColors.lime
                                : const Color(0xFFFF7043),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.calendar_month_rounded,
                color: AppColors.lime.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...data.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final amount = item['amount'] as double;
            final month = item['month'] as String;
            final isLast = i == data.length - 1;
            final barFraction = maxAmt == 0 ? 0.0 : (amount / maxAmt);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      month.length >= 3 ? month.substring(0, 3) : month,
                      style: AppText.caption.copyWith(
                        fontWeight: isLast
                            ? FontWeight.w800
                            : FontWeight.normal,
                        color: isLast ? AppColors.lime : mutedColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: barFraction.clamp(0.0, 1.0),
                        backgroundColor:
                            AppColors.muted.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(
                          isLast
                              ? AppColors.lime
                              : AppColors.lime.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      _showMonthDetail(context, controller, month, amount);
                    },
                    child: Flexible(
                      flex: 0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 80, minWidth: 50),
                        child: Text(
                          controller.showBalance
                              ? controller.formatMoney(amount)
                              : '${controller.currencySymbol} •••',
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(
                            color: amount > 0
                                ? (isLast ? AppColors.lime : textColor)
                                : mutedColor,
                            fontWeight: isLast
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
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

  void _showMonthDetail(BuildContext context, GoalSaverController controller, String month, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.panel : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: AppColors.lime, size: 20),
            const SizedBox(width: 8),
            Text(month, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
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
            const SizedBox(height: 12),
            const Text('Click on a goal in "Goal Progress" below for more detail.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
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
}
