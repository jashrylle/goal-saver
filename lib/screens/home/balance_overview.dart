import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Card showing total saved amount, progress bar, target, and an interactive
/// mini pie chart of goal allocation.
class BalanceOverview extends StatelessWidget {
  const BalanceOverview({super.key, required this.controller});

  final GoalSaverController controller;

  void _showAllocationBreakdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goals = controller.allActiveGoals.where((g) => g.saved > 0).toList();
    if (goals.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.panel : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.pie_chart_rounded, color: AppColors.lime, size: 22),
            const SizedBox(width: 10),
            const Text('Goal Allocation',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...goals.map((g) {
                final fraction = controller.totalSaved > 0
                    ? (g.saved / controller.totalSaved)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: g.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(g.icon, color: g.color, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.lightText)),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                minHeight: 5,
                                value: fraction,
                                backgroundColor:
                                    AppColors.muted.withValues(alpha: 0.15),
                                valueColor:
                                    AlwaysStoppedAnimation(g.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(fraction * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: g.color,
                        ),
                      ),
                    ],
                  ),
                );
              }),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    final totalSaved = controller.totalSaved;
    final totalTarget = controller.totalTarget;
    final progress = totalTarget == 0 ? 0 : (totalSaved / totalTarget).clamp(0, 1);

    // Pie chart data
    final goals = controller.allActiveGoals.where((g) => g.saved > 0).toList();
    final totalWithSavings = goals.fold<double>(0, (s, g) => s + g.saved);
    final hasAllocationData = goals.isNotEmpty && totalWithSavings > 0;

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
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => controller.toggleBalanceVisibility(),
                child: Icon(
                  controller.showBalance
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: mutedColor,
                  size: 18,
                ),
              ),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: controller.showBalance
                      ? Text(
                          controller.formatMoney(totalSaved),
                          style: AppText.titleLarge
                              .copyWith(color: controller.accentColor),
                          textAlign: TextAlign.right,
                        )
                      : Text(
                          '${controller.currencySymbol} •••',
                          style: AppText.titleLarge.copyWith(color: textColor),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Progress bar + mini pie chart ────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: progress.toDouble(),
                        backgroundColor:
                            AppColors.muted.withValues(alpha: 0.18),
                        valueColor:
                            AlwaysStoppedAnimation(controller.accentColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 12, color: mutedColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            controller.showBalance
                                ? '${controller.formatMoney(totalSaved)} saved of ${controller.formatMoney(totalTarget)}'
                                : '${controller.currencySymbol} ••• of •••',
                            style:
                                AppText.caption.copyWith(color: mutedColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).round()}%',
                          style:
                              AppText.caption.copyWith(color: mutedColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasAllocationData) ...[
                const SizedBox(width: 16),
                // Mini interactive pie chart
                Pressable(
                  onTap: () => _showAllocationBreakdown(context),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: CustomPaint(
                      size: const Size(56, 56),
                      painter: _MiniPieChartPainter(
                        goals: goals,
                        total: totalWithSavings,
                        bgColor: AppColors.muted.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the mini pie chart showing goal allocation.
class _MiniPieChartPainter extends CustomPainter {
  final List<dynamic> goals;
  final double total;
  final Color bgColor;

  _MiniPieChartPainter({
    required this.goals,
    required this.total,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0 || goals.isEmpty) return;

    // Draw arcs
    double startAngle = -math.pi / 2;
    for (final goal in goals) {
      final saved = (goal.saved as double?) ?? 0.0;
      final sweepAngle = (saved / total) * 2 * math.pi;

      final paint = Paint()
        ..color = goal.color as Color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // Center hole for donut effect
    canvas.drawCircle(center, radius * 0.35, Paint()..color = bgColor);
  }

  @override
  bool shouldRepaint(_MiniPieChartPainter oldDelegate) =>
      total != oldDelegate.total || goals.length != oldDelegate.goals.length;
}
