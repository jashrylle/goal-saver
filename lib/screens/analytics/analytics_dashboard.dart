import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/sheets/goal_details_sheet.dart';
import 'analytics_range_filter.dart';
import 'analytics_hero.dart';
import 'responsive_chart_grid.dart';
import 'monthly_trend_card.dart';
import 'weekly_contribution_card.dart';
import 'insights_panel.dart';
import 'goal_completion_grid.dart';
import 'allocation_card.dart';

/// Analytics tab screen.
class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Stack(
      children: [
        const AppBackground(),
        SafeArea(
          child: Consumer<GoalSaverController>(
            builder: (context, controller, _) {
              // Top performer goal
              final goals = controller.goals;
              final topGoal = goals.isEmpty
                  ? null
                  : goals.reduce(
                      (a, b) => a.progress > b.progress ? a : b,
                    );

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      metrics.pagePadding, 18, metrics.pagePadding, 126,
                    ),
                    sliver: SliverList.list(
                      children: [
                        // Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analytics',
                                    style: AppText.caption.copyWith(
                                      color: AppColors.lime,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your Savings Report',
                                    style: AppText.titleLarge,
                                  ),
                                ],
                              ),
                            ),
                            if (topGoal != null)
                              Pressable(
                                onTap: () => showGoalDetailsSheet(context, topGoal),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: topGoal.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: topGoal.color.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(topGoal.icon,
                                          size: 14, color: topGoal.color),
                                      const SizedBox(width: 5),
                                      Icon(Icons.emoji_events_rounded,
                                          size: 12, color: topGoal.color),
                                      const SizedBox(width: 2),
                                      Text(
                                        topGoal.title,
                                        style: AppText.caption.copyWith(
                                          color: topGoal.color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const AnalyticsRangeFilter(),
                        const SizedBox(height: 16),
                        AnalyticsHero(controller: controller),
                        const SizedBox(height: 16),
                        ResponsiveChartGrid(
                          children: [
                            WeeklyContributionCard(range: controller.range),
                            MonthlyTrendCard(range: controller.range),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const InsightsPanel(),
                        const SizedBox(height: 16),
                        const ResponsiveChartGrid(
                          children: [
                            GoalCompletionGrid(),
                            AllocationCard(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
