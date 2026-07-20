import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/achievement_model.dart';
import '../home/home_dashboard.dart';
import '../analytics/analytics_dashboard.dart';
import '../settings/settings_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/confetti_widget.dart';
import '../../widgets/achievement_celebration.dart';
import '../../widgets/milestone_celebration.dart' show showMilestoneCelebration;
import '../../widgets/sheets/add_goal_sheet.dart';
import '../../widgets/sheets/productivity_sheet.dart';
import '../../services/export_service.dart';
import '../../services/notification_service.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import 'goal_saver_nav_bar.dart';

/// Root shell widget managing tab navigation and the onboarding gate.
class GoalSaverShell extends StatefulWidget {
  const GoalSaverShell({super.key, this.showOnboarding = true, this.onLogout});

  final bool showOnboarding;
  final VoidCallback? onLogout;

  @override
  State<GoalSaverShell> createState() => _GoalSaverShellState();
}

class _GoalSaverShellState extends State<GoalSaverShell> with WidgetsBindingObserver {
  late bool _hasEntered = !widget.showOnboarding;
  int _tabIndex = 0;
  GoalSaverController? _cachedController;

  /// Check for a pending notification payload (set by the notification tap handler).
  /// If present, navigate to home tab and open the Add Savings sheet.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handleNotificationTap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recalculate plans when app returns to foreground
      _cachedController?.recalculatePlans();
    }
  }

  void _handleNotificationTap() {
    final payload = NotificationService.consumePendingPayload();
    if (payload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _tabIndex = 0);
        // Open the Add Savings sheet
        showProductivitySheet(
          context,
          title: 'Add Savings',
          icon: Icons.savings_rounded,
        );
      });
    }
  }

  final Set<String> _seenPendingAchievementIds = {};
  String? _seenMilestoneGoalId;
  int? _seenMilestonePct;
  String? _seenCompletedGoalId;

  void _checkPendingCelebrations(GoalSaverController controller) {
    // Cache controller for lifecycle handler
    _cachedController = controller;

    // Check for milestone celebration
    final milestoneGoal = controller.pendingMilestoneGoal;
    final milestonePercent = controller.pendingMilestonePercent;
    if (milestoneGoal != null && milestonePercent != null) {
      final key = '${milestoneGoal.id}_$milestonePercent';
      if (key != '${_seenMilestoneGoalId}_$_seenMilestonePct') {
        _seenMilestoneGoalId = milestoneGoal.id;
        _seenMilestonePct = milestonePercent;
        controller.consumePendingMilestone();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Delay to allow any previous dialogs to close first
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            showMilestoneCelebration(
              context,
              goal: milestoneGoal,
              milestonePercentage: milestonePercent,
            );
          });
        });
      }
    }

    // Check for completed goal celebration
    final completedGoal = controller.pendingCompletedGoal;
    if (completedGoal != null && completedGoal.id != _seenCompletedGoalId) {
      _seenCompletedGoalId = completedGoal.id;
      controller.clearPendingCompletedGoal();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Delay to allow any previous dialogs to close first
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          CelebrationOverlay.show(
            context,
            message: '🎉 Goal Complete!\n"${completedGoal.title}" is fully funded!\n\nTotal saved: ${controller.showBalance ? controller.formatMoney(completedGoal.saved) : "•••"} against ${controller.currencySymbol}${completedGoal.target.toStringAsFixed(0)} target.',
            onTap: () {
              setState(() => _tabIndex = 0);
            },
          );
        });
      });
    }

    // Check for newly unlocked achievements
    final pendingAchievements = controller.consumePendingAchievements();
    if (pendingAchievements.isNotEmpty) {
      // Filter out already-seen achievements to avoid double-showing
      final newAchievements = pendingAchievements
          .where((a) => !_seenPendingAchievementIds.contains(a.id))
          .toList();
      if (newAchievements.isNotEmpty) {
        for (final a in newAchievements) {
          _seenPendingAchievementIds.add(a.id);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Longer delay to allow savings confirmation dialog to fully close
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!mounted) return;
            _showAchievementSequence(newAchievements);
          });
        });
      }
    }
  }

  void _showAchievementSequence(List<AchievementBadge> badges) {
    if (badges.isEmpty || !mounted) return;
    final badge = badges.first;
    final remaining = badges.sublist(1);
    AchievementCelebration.show(context, badge);
    // Wait for the current dialog to close, then show the next
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && remaining.isNotEmpty) {
        _showAchievementSequence(remaining);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasEntered) {
      return OnboardingScreen(
        onComplete: () => setState(() => _hasEntered = true),
      );
    }

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = bottomInset > 0;

    // Check for celebrations (goal completion + achievement unlocks)
    final controller = context.watch<GoalSaverController>();
    _checkPendingCelebrations(controller);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: true,
      // Slide + fade transition for tab switches
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slideTween = Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          final fadeTween = Tween<double>(
            begin: 0,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeOut));

          return SlideTransition(
            position: animation.drive(slideTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_tabIndex),
          child: IndexedStack(
            index: _tabIndex,
            children: [
              const HomeDashboard(),
              const AnalyticsDashboard(),
              SettingsScreen(onLogout: widget.onLogout),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        offset: isKeyboardOpen ? const Offset(0, 1.5) : Offset.zero,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: isKeyboardOpen ? 0 : 1,            child: switch (_tabIndex) {
            0 => ExpandableGoalActions(
                onContribution: () => showProductivitySheet(
                  context,
                  title: 'Add Savings',
                  icon: Icons.savings_rounded,
                ),
                onGoal: () => showAddGoalSheet(context),
              ),
            1 => FloatingActionButton.extended(
                onPressed: () async {
                  final controller = context.read<GoalSaverController>();
                  try {
                    await ExportService().exportToPDF(
                      controller.allActiveGoals,
                      controller.history,
                      currencyCode: controller.currencyCode,
                    );
                    
                    // Show a local notification confirming the export
                    await NotificationService().showNotification(
                      id: 888,
                      title: 'Report Exported Successfully! 📄',
                      body: 'Your PDF savings report is ready and has been shared.',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to export report: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Export'),
              ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
      floatingActionButtonLocation: _tabIndex == 1
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: isKeyboardOpen
          ? null
          : GoalSaverNavBar(
              index: _tabIndex,
              onChanged: (index) => setState(() => _tabIndex = index),
            ),
    );
  }
}
