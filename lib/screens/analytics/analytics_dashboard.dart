import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';
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
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      metrics.pagePadding, 18, metrics.pagePadding, 126,
                    ),
                    sliver: SliverList.list(
                      children: [
                        const DashboardHeader(
                          eyebrow: 'Analytics',
                          title: 'Savings discipline',
                          trailingIcon: Icons.calendar_month_rounded,
                        ),
                        const SizedBox(height: 18),
                        const AnalyticsRangeFilter(),
                        const SizedBox(height: 18),
                        AnalyticsHero(controller: controller),
                        const SizedBox(height: 16),
                        ResponsiveChartGrid(
                          children: [
                            MonthlyTrendCard(range: controller.range),
                            WeeklyContributionCard(range: controller.range),
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
