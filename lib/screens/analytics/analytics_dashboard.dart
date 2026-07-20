import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/savings_forecast_card.dart';
import '../../widgets/sheets/add_goal_sheet.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/app_colors.dart';
import 'analytics_range_filter.dart';
import 'analytics_hero.dart';
import 'responsive_chart_grid.dart';
import 'analytics_charts.dart';
import 'insights_panel.dart';
import 'goal_completion_grid.dart';
import 'pie_chart_card.dart';
import 'gauge_indicator.dart';
import 'heatmap_widget.dart';
import 'comparison_card.dart';
import 'achievement_stats_card.dart';

/// A tappable badge for the top-performing goal that provides visual feedback
/// and shows a celebratory snackbar with goal status instead of navigating.
class _TopGoalBadge extends StatefulWidget {
  final GoalSaverController controller;
  final SavingsGoal topGoal;

  const _TopGoalBadge({
    required this.controller,
    required this.topGoal,
  });

  @override
  State<_TopGoalBadge> createState() => _TopGoalBadgeState();
}

class _TopGoalBadgeState extends State<_TopGoalBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context) {
    final goal = widget.topGoal;
    final ctrl = widget.controller;
    final statusEmoji = goal.completed ? '🎉' : '🏆';
    final statusText = goal.completed
        ? 'Completed!'
        : '${ctrl.showBalance ? ctrl.formatMoney(goal.moneyNeeded) : "•••"} left';
    final excessText = goal.completed && goal.excessSaved > 0
        ? ' (+${ctrl.showBalance ? ctrl.formatMoney(goal.excessSaved) : "•••"} excess)'
        : '';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppColors.ink, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$statusEmoji ${goal.title} — $statusText$excessText',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: goal.color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.topGoal;

    return Pressable(
      onTap: () => _onTap(context),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: goal.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(goal.icon, size: 14, color: goal.color),
                  const SizedBox(width: 5),
                  const Icon(Icons.emoji_events_rounded,
                      size: 12, color: AppColors.lime),
                  const SizedBox(width: 2),
                  Text(
                    goal.title,
                    style: AppText.caption.copyWith(
                      color: goal.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Analytics tab screen with comprehensive charts and insights.
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
              final goals = controller.goals;
              final topGoal = goals.isEmpty
                  ? null
                  : goals.reduce(
                      (a, b) => a.progress > b.progress ? a : b,
                    );

              if (goals.isEmpty) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        metrics.pagePadding, 18, metrics.pagePadding, 126,
                      ),
                      sliver: SliverList.list(
                        children: [
                          _buildHeader(controller, topGoal),
                          const SizedBox(height: 32),
                          EmptyState(
                            icon: Icons.analytics_rounded,
                            title: 'No savings data yet',
                            subtitle: 'Create your first savings goal to\\nsee your analytics and trends here',
                            actionLabel: 'Add Goal',
                            onAction: () => showAddGoalSheet(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        metrics.pagePadding, 18, metrics.pagePadding, 126,
                      ),
                      sliver: SliverList.list(
                        children: [
                          _buildHeader(controller, topGoal),
                          const SizedBox(height: 16),
                          const AnalyticsRangeFilter(),
                          const SizedBox(height: 16),
                          AnalyticsHero(controller: controller),
                          const SizedBox(height: 16),
                          // Charts grid row 1: line + bar
                          const ResponsiveChartGrid(
                            children: [
                              WeeklyContributionBarChart(),
                              MonthlyTrendLineChart(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Charts grid row 2: pie + stacked bar
                          const ResponsiveChartGrid(
                            children: [
                              CategoryPieChartCard(),
                              StackedCategoryBarChart(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Financial health gauge
                          const FinancialHealthGauge(),
                          const SizedBox(height: 16),
                          // Savings forecast
                          SavingsForecastCard(controller: controller),
                          const SizedBox(height: 16),
                          // Month comparison
                          const MonthComparisonCard(),
                          const SizedBox(height: 16),
                          // Heatmap
                          const SavingsHeatmap(),
                          const SizedBox(height: 16),
                          // Goal completion grid + allocation card
                          const ResponsiveChartGrid(
                            children: [
                              GoalCompletionGrid(),
                              GoalAllocationPieChart(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Achievement stats
                          const AchievementStatsCard(),
                          const SizedBox(height: 16),
                          // Insights panel
                          const InsightsPanel(),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(GoalSaverController controller, SavingsGoal? topGoal) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: AppText.caption.copyWith(
                  color: controller.accentColor,
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
          _TopGoalBadge(
            controller: controller,
            topGoal: topGoal,
          ),
      ],
    );
  }
}
