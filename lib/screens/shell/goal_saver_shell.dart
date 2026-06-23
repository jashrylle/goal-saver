import 'package:flutter/material.dart';
import '../home/home_dashboard.dart';
import '../analytics/analytics_dashboard.dart';
import '../settings/settings_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/sheets/add_goal_sheet.dart';
import '../../widgets/sheets/productivity_sheet.dart';
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        child: IndexedStack(
          key: ValueKey(_tabIndex),
          index: _tabIndex,
          children: const [
            HomeDashboard(),
            AnalyticsDashboard(),
            SettingsScreen(),
          ],
        ),
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
                onPressed: () => showProductivitySheet(
                  context,
                  title: 'PDF Savings Report',
                  icon: Icons.picture_as_pdf_rounded,
                ),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Export'),
              ),
            _ => FloatingActionButton.small(
                onPressed: () => showProductivitySheet(
                  context,
                  title: 'Reminder Settings',
                  icon: Icons.notifications_active_rounded,
                ),
                child: const Icon(Icons.notifications_active_rounded),
              ),
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: isKeyboardOpen
          ? null
          : GoalSaverNavBar(
              index: _tabIndex,
              onChanged: (index) => setState(() => _tabIndex = index),
            ),
    );
  }
}
