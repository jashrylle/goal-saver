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
import '../profile/profile_screen.dart';
import 'balance_overview.dart';
import 'smart_status_grid.dart';
import 'quick_actions.dart';
import 'goal_search_filters.dart';

/// The main home tab showing the goal list and summary cards.
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

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
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_getGreeting()}, ${controller.userName}',
                                        style: AppText.caption.copyWith(
                                          color: AppColors.lime,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Your Savings',
                                        style: AppText.adaptive(context, AppText.titleLarge),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Tappable profile icon → ProfileScreen
                                Pressable(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileScreen(),
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      final photoUrl = controller.userPhotoUrl;
                                      final name = controller.userName;
                                      if (photoUrl != null && photoUrl.isNotEmpty) {
                                        if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
                                          return Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.lime.withValues(alpha: 0.3),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: Image.network(
                                                photoUrl,
                                                width: 44,
                                                height: 44,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(name),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: AppColors.lime.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.lime.withValues(alpha: 0.3),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                photoUrl,
                                                style: const TextStyle(fontSize: 22),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                      return _buildDefaultAvatar(name);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            BalanceOverview(controller: controller),
                            const SizedBox(height: 16),
                            const SmartStatusGrid(),
                            const SizedBox(height: 16),
                            const QuickActions(),
                            const SizedBox(height: 16),
                            _QuickNotesPreview(controller: controller, context: context),
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

  /// Quick notes preview widget displayed on home dashboard — always visible and fully functional
  Widget _QuickNotesPreview({required GoalSaverController controller, required BuildContext context}) {
    final notes = controller.savedNotes;
    final latestNote = notes.isNotEmpty ? notes.first['content'] as String : '';
    final noteCount = notes.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.note_alt_rounded, color: AppColors.lime, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lime,
                        ),
                      ),
                      if (noteCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.lime.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$noteCount',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.lime,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (latestNote.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      latestNote,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tap to add notes and reminders for your savings goals',
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedColor,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: mutedColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.lime.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.lime,
          ),
        ),
      ),
    );
  }
}