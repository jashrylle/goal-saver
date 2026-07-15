import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../categories/category_management_screen.dart';
import '../calendar/calendar_screen.dart';
import '../shell/goal_saver_shell.dart';

/// Settings tab screen with theme, reminders, balance, and currency controls.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    return Stack(
      children: [
        const AppBackground(),
        SafeArea(
          child: Consumer<GoalSaverController>(
            builder: (context, controller, _) {
              return ListView(
                padding: EdgeInsets.fromLTRB(metrics.pagePadding, 18, metrics.pagePadding, 100),
                children: [
                  DashboardHeader(eyebrow: 'Settings', title: 'Preferences'),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Appearance',
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Dark mode',
                          style: AppText.body.copyWith(color: textColor),
                        ),
                        subtitle: Text(
                          'Toggle between dark and light theme',
                          style: AppText.caption.copyWith(color: mutedColor),
                        ),
                        value: controller.isDarkMode,
                        onChanged: controller.toggleTheme,
                        activeThumbColor: AppColors.lime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsSection(
                    title: 'Notifications',
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Enable reminders',
                          style: AppText.body.copyWith(color: textColor),
                        ),
                        subtitle: Text(
                          'Daily reminders at ${controller.reminderHour.toString().padLeft(2, '0')}:${controller.reminderMinute.toString().padLeft(2, '0')}',
                          style: AppText.caption.copyWith(color: mutedColor),
                        ),
                        value: controller.remindersEnabled,
                        onChanged: controller.toggleReminders,
                        activeThumbColor: AppColors.lime,
                      ),
                      // Reminder time picker
                      if (controller.remindersEnabled)
                        _SettingsTile(
                          icon: Icons.schedule_rounded,
                          title: 'Reminder Time',
                          subtitle: '${controller.reminderHour.toString().padLeft(2, '0')}:${controller.reminderMinute.toString().padLeft(2, '0')} — tap to change',
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: controller.reminderHour,
                                minute: controller.reminderMinute,
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.fromSeed(
                                      seedColor: AppColors.lime,
                                      brightness: isDark ? Brightness.dark : Brightness.light,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              controller.setReminderTime(picked.hour, picked.minute);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsSection(
                    title: 'Privacy',
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Show balance',
                          style: AppText.body.copyWith(color: textColor),
                        ),
                        subtitle: Text(
                          'Show or hide financial amounts',
                          style: AppText.caption.copyWith(color: mutedColor),
                        ),
                        value: controller.showBalance,
                        onChanged: controller.setShowBalance,
                        activeThumbColor: AppColors.lime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsSection(
                    title: 'Currency',
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: ['PHP', 'USD', 'EUR', 'GBP']
                              .map(
                                (code) => ChoiceChip(
                                  label: Text(
                                    code,
                                    style: TextStyle(
                                      color: controller.currencyCode == code
                                          ? AppColors.ink
                                          : textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  selected: controller.currencyCode == code,
                                  onSelected: (_) => controller.setCurrency(code),
                                  selectedColor: AppColors.lime,
                                  backgroundColor: isDark
                                      ? AppColors.panel
                                      : const Color(0xFFF0F0F0),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsSection(
                    title: 'Organization',
                    children: [
                      _SettingsTile(
                        icon: Icons.category_rounded,
                        title: 'Manage Categories',
                        subtitle: 'Add, edit, or delete categories',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoryManagementScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.calendar_month_rounded,
                        title: 'Calendar View',
                        subtitle: 'View your savings schedule',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CalendarScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsSection(
                    title: 'Account',
                    children: [
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        iconColor: AppColors.error,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) {
                              final dialogDark = Theme.of(ctx).brightness == Brightness.dark;
                              return AlertDialog(
                                backgroundColor: dialogDark ? AppColors.panel : Colors.white,
                                title: Text(
                                  'Logout',
                                  style: AppText.titleMedium.copyWith(
                                    color: dialogDark ? AppColors.white : AppColors.lightText,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to logout?',
                                  style: AppText.body.copyWith(
                                    color: dialogDark ? AppColors.white : AppColors.lightText,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(
                                      'Cancel',
                                      style: AppText.body.copyWith(color: AppColors.muted),
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                    child: Text(
                                      'Logout',
                                      style: AppText.body.copyWith(color: AppColors.white),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true && context.mounted) {
                            final authService = AuthService();
                            await authService.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(
                                    onLoginSuccess: () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => GoalSaverShell(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.adaptive(context, AppText.titleMedium),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final borderColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
        : const Color(0xFF000000).withValues(alpha: 0.06);
    final effectiveIconColor = iconColor ?? AppColors.lime;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppText.caption.copyWith(color: mutedColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
          ],
        ),
      ),
    );
  }
}