import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_dashboard.dart';
import '../analytics/analytics_dashboard.dart';
import '../settings/settings_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/sheets/add_goal_sheet.dart';
import '../../widgets/sheets/productivity_sheet.dart';
import '../../services/export_service.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import 'goal_saver_nav_bar.dart';

/// Root shell widget managing tab navigation and the onboarding gate.
class GoalSaverShell extends StatefulWidget {
  const GoalSaverShell({super.key, this.showOnboarding = true});

  final bool showOnboarding;

  @override
  State<GoalSaverShell> createState() => _GoalSaverShellState();
}

class _GoalSaverShellState extends State<GoalSaverShell> {
  late bool _hasEntered = !widget.showOnboarding;
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!_hasEntered) {
      return OnboardingScreen(
        onComplete: () => setState(() => _hasEntered = true),
      );
    }

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: true,
      // Removed AnimatedSwitcher wrapper to preserve states of IndexedStack tabs and scroll positions
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          HomeDashboard(),
          AnalyticsDashboard(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        offset: isKeyboardOpen ? const Offset(0, 1.5) : Offset.zero,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: isKeyboardOpen ? 0 : 1,
          child: switch (_tabIndex) {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to export report: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Export'),
              ),
            _ => FloatingActionButton.small(
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  final controller = context.read<GoalSaverController>();
                  final status = controller.remindersEnabled ? 'enabled' : 'disabled';
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Notifications are $status. Manage in Settings > Notifications.'),
                      backgroundColor: controller.remindersEnabled ? AppColors.lime : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Icon(Icons.notifications_active_rounded),
              ),
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
