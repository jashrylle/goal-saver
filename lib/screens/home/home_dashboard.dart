import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../widgets/sheets/productivity_sheet.dart';
import '../../widgets/sheets/customize_dashboard_sheet.dart';
import '../../widgets/health_score_card.dart';
import '../../widgets/player_level_card.dart';
import '../../widgets/monthly_summary_card.dart';
import '../../widgets/recent_activity_card.dart';
import '../../widgets/savings_coach_card.dart';
import '../profile/profile_screen.dart';
import '../../widgets/app_transitions.dart';
import 'balance_overview.dart';
import 'smart_status_grid.dart';
import 'quick_actions.dart';
import 'goal_search_filters.dart';

/// Wraps a child so entrance animation only plays once on first mount.
/// flutter_animate's `Animate` widget manages its own animation state,
/// so returning it once is sufficient — it plays independently regardless
/// of parent rebuilds triggered by state changes.
class _OnceAnimated extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _OnceAnimated({required this.child, this.delayMs = 0});
  @override
  State<_OnceAnimated> createState() => _OnceAnimatedState();
}

class _OnceAnimatedState extends State<_OnceAnimated> {
  bool _played = false;

  @override
  Widget build(BuildContext context) {
    if (!_played) {
      // Set the flag immediately so subsequent rebuilds always skip.
      // The Animate widget wraps the original child and manages its own
      // animation controllers internally; returning it once is sufficient
      // for the animation to play to completion regardless of parent rebuilds.
      _played = true;
      return widget.child.animate().fadeIn(
        duration: const Duration(milliseconds: 400),
        delay: Duration(milliseconds: widget.delayMs),
      ).slideY(
        begin: 0.1,
        curve: Curves.easeOutCubic,
        duration: const Duration(milliseconds: 400),
        delay: Duration(milliseconds: widget.delayMs),
      );
    }
    return widget.child;
  }
}

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
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final textColor = isDark ? AppColors.white : AppColors.lightText;
                    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
                    final accentColor = controller.accentColor;
                    return RefreshIndicator(
                color: accentColor,
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
                          children: [                              // ── Header: Avatar + Greeting + Name ─────────────────
                              // [Avatar] [Greeting & Name]    [Bell + Customize]
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Profile avatar — always visible, tappable to profile
                                  Pressable(
                                    onTap: () => Navigator.push(
                                      context,
                                      SlideFadePageRoute(page: const ProfileScreen()),
                                    ),
                                    semanticLabel: 'Open profile',
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: accentColor.withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: _buildHeaderAvatar(controller, accentColor: accentColor, size: 48)
                                            ?? Center(
                                                child: Text(
                                                  controller.userName.isNotEmpty
                                                      ? controller.userName[0].toUpperCase()
                                                      : 'U',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                    color: accentColor,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Greeting + user name
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getGreeting(),
                                          style: AppText.caption.copyWith(
                                            color: accentColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          controller.userName,
                                          style: AppText.section.copyWith(
                                            color: textColor,
                                            fontSize: 22,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Notification bell with unread badge
                                  Pressable(
                                    onTap: () {
                                      controller.clearNotificationBadge();
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.notifications_rounded, color: AppColors.ink, size: 18),
                                              SizedBox(width: 8),
                                              Text('No new notifications', style: TextStyle(color: AppColors.ink)),
                                            ],
                                          ),
                                          backgroundColor: AppColors.lime,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                      );
                                    },
                                    semanticLabel: 'Notifications',
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFFFFFFFF).withValues(alpha: 0.06)
                                                : const Color(0xFF000000).withValues(alpha: 0.04),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
                                                  : const Color(0xFF000000).withValues(alpha: 0.06),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.notifications_outlined,
                                            color: mutedColor,
                                            size: 22,
                                          ),
                                        ),
                                        if (controller.unreadNotificationCount > 0)
                                          Positioned(
                                            top: -2,
                                            right: -2,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF6B6B),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isDark ? AppColors.panel : Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Text(
                                                '${controller.unreadNotificationCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Customize dashboard button
                                  Pressable(
                                    onTap: () => showCustomizeDashboardSheet(context),
                                    semanticLabel: 'Customize dashboard',
                                    tooltip: 'Customize dashboard',
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFFFFFFFF).withValues(alpha: 0.06)
                                            : const Color(0xFF000000).withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
                                              : const Color(0xFF000000).withValues(alpha: 0.06),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: mutedColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Subtitle below the header row
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Your Savings',
                                      style: AppText.adaptive(context, AppText.titleLarge),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            ..._buildDashboardCards(controller: controller, context: context),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Flexible(
                                  child: Text('Products I\'m Saving For', style: AppText.section, overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
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
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(milliseconds: 350 + index * 60),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: AnimatedGoalCard(
                                      goal: goal,
                                      index: index,
                                      onTap: () => showGoalDetailsSheet(context, goal),
                                    ),
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
  Widget _quickNotesPreview({required GoalSaverController controller, required BuildContext context}) {
    final notes = controller.savedNotes;
    final latestNote = notes.isNotEmpty ? notes.first['content'] as String : '';
    final noteCount = notes.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final accentColor = controller.accentColor;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(
            context,
            SlideFadePageRoute(page: const ProfileScreen()),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.note_alt_rounded, color: accentColor, size: 18),
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
                            color: accentColor,
                          ),
                        ),
                        if (noteCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$noteCount',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
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
      ),
    );
  }

  /// Build dashboard summary cards in the user-configured order.
  /// Filters out hidden cards and wraps each in a staggered entrance animation.
  List<Widget> _buildDashboardCards({
    required GoalSaverController controller,
    required BuildContext context,
  }) {
    final cards = <Widget>[];
    var animIndex = 0;

    // Mapping from DashboardCardType to the actual widget builder
    Widget? cardForType(DashboardCardType type) {
      switch (type) {
        case DashboardCardType.balanceOverview:
          return BalanceOverview(controller: controller);
        case DashboardCardType.smartStatus:
          return const SmartStatusGrid();
        case DashboardCardType.quickActions:
          return const QuickActions();
        case DashboardCardType.confirmSavings: {
          final goalsNeedingSavings = controller.goals
              .where((g) => !g.completed && g.recommendedDeposit > 0)
              .take(3)
              .toList();
          if (goalsNeedingSavings.isEmpty) return null;
          return _confirmSavingsCard(controller: controller, context: context);
        }
        case DashboardCardType.playerLevel:
          return PlayerLevelCard(controller: controller);
        case DashboardCardType.monthlySummary:
          return MonthlySummaryCard(controller: controller);
        case DashboardCardType.healthScore:
          return FinancialHealthCard(controller: controller);
        case DashboardCardType.savingsCoach:
          return SavingsCoachCard(controller: controller);
        case DashboardCardType.recentActivity:
          return RecentActivityCard(controller: controller);
        case DashboardCardType.notesPreview:
          return _quickNotesPreview(controller: controller, context: context);
        case DashboardCardType.goalSearch:
          return const GoalSearchAndFilters();
      }
    }

    for (final cardType in controller.visibleCardOrder) {
      final widget = cardForType(cardType);
      if (widget == null) continue;
      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OnceAnimated(delayMs: 200 + animIndex * 70, child: widget),
        ),
      );
      animIndex++;
    }
    return cards;
  }

  /// Build the header avatar supporting network images, local file paths, and initials fallback.
  Widget? _buildHeaderAvatar(GoalSaverController controller, {required Color accentColor, double size = 48}) {
    final photoUrl = controller.userPhotoUrl;
    if (photoUrl == null || photoUrl.isEmpty) return null;

    // Network image
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      );
    }

    // Local file path
    try {
      final file = File(photoUrl);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        );
      }
    } catch (_) {}

    // Emoji preset
    if (photoUrl.length <= 2 && photoUrl.codeUnits.any((c) => c > 127)) {
      return Center(
        child: Text(photoUrl, style: TextStyle(fontSize: size * 0.45)),
      );
    }

    return null;
  }

  /// "Confirm Today's Savings" card — shows goals with reminders due today.
  Widget _confirmSavingsCard({required GoalSaverController controller, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    // Find goals that need attention today: active, not completed, with a plan and recommended deposit > 0
    final goalsNeedingSavings = controller.goals
        .where((g) => !g.completed && g.recommendedDeposit > 0)
        .take(3)
        .toList();

    if (goalsNeedingSavings.isEmpty) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFFA726), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Today\'s Savings',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Tap to record your deposit for each goal',
                        style: TextStyle(fontSize: 10, color: mutedColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...goalsNeedingSavings.asMap().entries.map((entry) {
              final i = entry.key;
              final goal = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + i * 80),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Opacity(
                      opacity: val,
                      child: Transform.translate(
                        offset: Offset(12 * (1 - val), 0),
                        child: child,
                      ),
                    ),
                  );
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showProductivitySheet(
                      context,
                      title: 'Add Savings',
                      icon: Icons.savings_rounded,
                      initialGoal: goal,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: goal.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: goal.color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(goal.icon, size: 16, color: goal.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Recommended: ${controller.formatMoney(goal.recommendedDeposit)}',
                                style: TextStyle(fontSize: 10, color: controller.accentColor, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: mutedColor),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }


}