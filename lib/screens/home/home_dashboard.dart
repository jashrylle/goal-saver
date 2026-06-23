import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/goal_card.dart';
import '../../widgets/shimmer_goal_list.dart';
import '../../widgets/sheets/add_goal_sheet.dart';
import '../../widgets/sheets/goal_details_sheet.dart';
import 'balance_overview.dart';
import 'smart_status_grid.dart';
import 'quick_actions.dart';
import 'goal_search_filters.dart';

/// The main home tab showing the goal list and summary cards.
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Stack(
      children: [
        const AppBackground(),
        SafeArea(
          child: Consumer<GoalSaverController>(
            builder: (context, controller, _) {
              return RefreshIndicator(
                color: AppColors.lime,
                backgroundColor: AppColors.panel,
                onRefresh: controller.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(metrics.pagePadding, 18, metrics.pagePadding, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const DashboardHeader(),
                            const SizedBox(height: 20),
                            BalanceOverview(controller: controller),
                            const SizedBox(height: 16),
                            const SmartStatusGrid(),
                            const SizedBox(height: 16),
                            const QuickActions(),
                            const SizedBox(height: 22),
                            const GoalSearchAndFilters(),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Text('Products I\'m Saving For', style: AppText.section),
                                const Spacer(),
                                Text('${controller.goals.length} active', style: AppText.caption),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (controller.isLoading) const ShimmerGoalList(),
                          ],
                        ),
                      ),
                    ),
                    if (!controller.isLoading)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(metrics.pagePadding, 0, metrics.pagePadding, 128),
                        sliver: controller.goals.isEmpty
                            ? SliverToBoxAdapter(
                                child: EmptyGoalsCard(
                                  onAdd: () => showAddGoalSheet(context),
                                ),
                              )
                            : SliverList.separated(
                                itemBuilder: (context, index) {
                                  final goal = controller.goals[index];
                                  return AnimatedGoalCard(
                                    goal: goal,
                                    index: index,
                                    onTap: () => showGoalDetailsSheet(context, goal),
                                  );
                                },
                                separatorBuilder: (_, _) => const SizedBox(height: 14),
                                itemCount: controller.goals.length,
                              ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
