import 'package:flutter/material.dart';
import '../state/goal_saver_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../logic/savings_plan_calculator.dart';
import 'common_widgets.dart';

/// Savings Forecast card — predicts future savings, completion dates,
/// and provides a visual timeline of projected progress.
class SavingsForecastCard extends StatelessWidget {
  final GoalSaverController controller;

  const SavingsForecastCard({super.key, required this.controller});

  /// Called when a projection row is tapped; receives the goal title and estimated completion.
  void _onProjectionTap(BuildContext context, _GoalProjection proj, GoalSaverController controller) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.travel_explore_rounded, color: AppColors.ink, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${proj.title}: projected ${controller.showBalance ? controller.formatMoney(proj.projectedSaved) : "•••"} — est. ${
                  proj.estCompletion.startsWith('Est.') ? proj.estCompletion : 'Est. ${proj.estCompletion}'
                }',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
          ],
        ),
        backgroundColor: proj.color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    final forecast = _calculateForecast(controller);

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
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: Color(0xFF00D9FF),
                  size: 17,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Savings Forecast',
                style: AppText.title.copyWith(color: textColor, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: forecast.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  forecast.statusLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: forecast.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Projected completion timeline
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: forecast.projections.isEmpty
                  ? Colors.transparent
                  : isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: forecast.projections.isEmpty
                ? _buildEmptyState(textColor, mutedColor)
                : _buildTimeline(context, forecast, textColor, mutedColor, isDark, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color mutedColor) {
    return Column(
      children: [
        Icon(Icons.hourglass_empty_rounded, size: 28, color: mutedColor.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text(
          'Add savings goals to see your forecast',
          style: TextStyle(fontSize: 12, color: mutedColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    _Forecast forecast,
    Color textColor,
    Color mutedColor,
    bool isDark,
    GoalSaverController controller,
  ) {
    final projections = forecast.projections.take(3).toList();

    return Column(
      children: [
        // Summary
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projected Total',
                    style: TextStyle(fontSize: 10, color: mutedColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.showBalance
                        ? controller.formatMoney(forecast.projectedTotal)
                        : '${controller.currencySymbol} •••',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: controller.accentColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'By ${forecast.estimatedDate}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: forecast.statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${forecast.completedCount}/${forecast.totalCount} goals',
                  style: TextStyle(fontSize: 10, color: mutedColor),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Goal projections
        ...projections.asMap().entries.map((entry) {
          final proj = entry.value;
          final fraction = proj.projectedTarget > 0
              ? (proj.projectedSaved / proj.projectedTarget).clamp(0.0, 1.0)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _onProjectionTap(context, proj, controller),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: proj.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(proj.icon, color: proj.color, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                proj.title,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              controller.showBalance
                                  ? controller.formatMoney(proj.projectedSaved)
                                  : '•••',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: proj.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            value: fraction,
                            backgroundColor: AppColors.muted.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(proj.color),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${proj.daysLeft}d left',
                              style: TextStyle(fontSize: 8, color: mutedColor),
                            ),
                            const Spacer(),
                            Icon(Icons.schedule_rounded, size: 8, color: mutedColor),
                            const SizedBox(width: 2),
                            Text(
                              proj.estCompletion,
                              style: TextStyle(fontSize: 8, color: proj.color),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  _Forecast _calculateForecast(GoalSaverController controller) {
    final goals = controller.allActiveGoals;
    final now = DateTime.now();

    if (goals.isEmpty) {
      return _Forecast(
        projectedTotal: 0,
        estimatedDate: 'N/A',
        statusLabel: 'No Data',
        statusColor: AppColors.muted,
        completedCount: 0,
        totalCount: 0,
        projections: [],
      );
    }

    double totalProjected = controller.totalSaved;
    final projections = <_GoalProjection>[];
    int completed = 0;

    for (final goal in goals) {
      if (goal.completed) {
        completed++;
        continue;
      }

      final daysLeft = goal.daysLeft;
      final remaining = goal.remaining;
      final dailyRate = goal.savingsPerDay;

      double projectedSaved;
      String estCompletion;

      if (dailyRate > 0 && daysLeft > 0) {
        // Project based on current pace
        projectedSaved = goal.saved + (dailyRate * daysLeft).clamp(0, remaining);
        final daysToComplete = (remaining / dailyRate).ceil();
        final estDate = now.add(Duration(days: daysToComplete.clamp(1, 365)));
        estCompletion = SavingsPlanCalculator.estimateCompletionLabel(estDate);
      } else {
        projectedSaved = goal.saved;
        estCompletion = 'No pace data';
      }

      projections.add(_GoalProjection(
        title: goal.title,
        color: goal.color,
        icon: goal.icon,
        projectedSaved: projectedSaved.clamp(0, goal.target),
        projectedTarget: goal.target,
        daysLeft: daysLeft,
        estCompletion: estCompletion,
      ));

      totalProjected += (projectedSaved - goal.saved);
    }

    // Find latest estimated completion date
    final estDates = projections
        .map((p) => p.estCompletion)
        .where((s) => s != 'No pace data' && s != 'Not enough data yet')
        .toList();

    final estimatedDate = estDates.isNotEmpty
        ? estDates.last
        : SavingsPlanCalculator.estimateCompletionLabel(
            now.add(const Duration(days: 90)),
          );

    // Status
    final statusLabel = projections.every((p) => p.daysLeft > 0)
        ? 'ON TRACK'
        : 'BEHIND';
    final statusColor = statusLabel == 'ON TRACK'
        ? const Color(0xFF00E676)
        : const Color(0xFFFF7043);

    return _Forecast(
      projectedTotal: totalProjected,
      estimatedDate: estimatedDate,
      statusLabel: statusLabel,
      statusColor: statusColor,
      completedCount: completed,
      totalCount: goals.length,
      projections: projections,
    );
  }
}

class _Forecast {
  final double projectedTotal;
  final String estimatedDate;
  final String statusLabel;
  final Color statusColor;
  final int completedCount;
  final int totalCount;
  final List<_GoalProjection> projections;

  const _Forecast({
    required this.projectedTotal,
    required this.estimatedDate,
    required this.statusLabel,
    required this.statusColor,
    required this.completedCount,
    required this.totalCount,
    required this.projections,
  });
}

class _GoalProjection {
  final String title;
  final Color color;
  final IconData icon;
  final double projectedSaved;
  final double projectedTarget;
  final int daysLeft;
  final String estCompletion;

  const _GoalProjection({
    required this.title,
    required this.color,
    required this.icon,
    required this.projectedSaved,
    required this.projectedTarget,
    required this.daysLeft,
    required this.estCompletion,
  });
}
