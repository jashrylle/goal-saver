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
import '../../services/notification_service.dart';
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

  void _showReminderDialog(
    BuildContext context,
    GoalSaverController controller,
    Color textColor,
    Color bgColor,
  ) {
    final emailController = TextEditingController(text: controller.userEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        title: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: AppColors.lime, size: 24),
            const SizedBox(width: 10),
            Text(
              'Set Reminder',
              style: AppText.titleMedium.copyWith(color: textColor),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Receive daily reminder notifications to save for your goals.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text('Email for reminders:', style: TextStyle(fontSize: 12, color: textColor)),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                style: TextStyle(color: textColor),
                decoration: goalInputDecoration(
                  'Your email address',
                  Icons.email_rounded,
                  context: context,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Reminder Status: ',
                    style: TextStyle(fontSize: 13),
                  ),
                  Icon(
                    controller.remindersEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: controller.remindersEnabled ? AppColors.lime : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    controller.remindersEnabled ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: controller.remindersEnabled ? AppColors.lime : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.toggleReminders(!controller.remindersEnabled);
            },
            child: Text(
              controller.remindersEnabled ? 'Disable' : 'Enable',
              style: TextStyle(
                color: controller.remindersEnabled ? AppColors.error : AppColors.lime,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                // Save the email to user profile
                await controller.updateProfile(
                  name: controller.userName,
                  email: email,
                  photoUrl: controller.userPhotoUrl,
                );
              }
              // Enable reminders if not already enabled
              if (!controller.remindersEnabled) {
                controller.toggleReminders(true);
              }
              // Schedule the daily reminder
              await NotificationService().scheduleDailyReminder(
                id: 999,
                title: 'Time to Save!',
                body: email.isNotEmpty
                    ? 'Reminder sent to $email - Save for your goals today!'
                    : "Don't forget to record your savings and reach your goals today!",
                hour: controller.reminderHour,
                minute: controller.reminderMinute,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      email.isNotEmpty
                        ? 'Reminders enabled! Notifications will be sent to $email'
                        : 'Reminders enabled!',
                    ),
                    backgroundColor: AppColors.lime,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.lime),
            child: Text(
              'Save & Enable',
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
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
                  final controller = context.read<GoalSaverController>();
                  final _isDark = Theme.of(context).brightness == Brightness.dark;
                  final textColor = _isDark ? AppColors.white : AppColors.lightText;
                  final bgColor = _isDark ? AppColors.panel : Colors.white;
                  _showReminderDialog(context, controller, textColor, bgColor);
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
