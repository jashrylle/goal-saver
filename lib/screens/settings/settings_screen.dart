import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/backup_service.dart';
import '../../models/savings_plan_model.dart' show ResetFlags;
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_transitions.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/confetti_widget.dart';
import '../categories/category_management_screen.dart';
import '../calendar/calendar_screen.dart';

/// Settings tab screen with theme, reminders, balance, and currency controls.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  void _showAccentColorPicker(BuildContext context, GoalSaverController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final bgColor = isDark ? AppColors.panel : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.muted.withValues(alpha: 0.3)
                      : AppColors.lightMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Choose Accent Color',
              style: AppText.titleMedium.copyWith(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a color to personalize your theme',
              style: AppText.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: GoalSaverController.accentColorPalette.map((color) {
                final selected = controller.accentColor == color;
                return GestureDetector(
                  onTap: () {
                    controller.setAccentColor(color);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Color(0xFF07100E), size: 28)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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
                  const DashboardHeader(eyebrow: 'Settings', title: 'Settings & Preferences'),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Appearance',
                    children: [
                      SwitchListTile(
                        tileColor: Colors.transparent,
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
                        activeThumbColor: controller.accentColor,
                      ),
                      // Accent color picker
                      _SettingsTile(
                        icon: Icons.palette_rounded,
                        title: 'Accent Color',
                        subtitle: controller.accentColorName,
                        onTap: () => _showAccentColorPicker(context, controller),
                      ),
                      // Animations toggle
                      SwitchListTile(
                        tileColor: Colors.transparent,
                        title: Text(
                          'Animated transitions',
                          style: AppText.body.copyWith(color: textColor),
                        ),
                        subtitle: Text(
                          'Enable smooth animations and micro-interactions',
                          style: AppText.caption.copyWith(color: mutedColor),
                        ),
                        value: controller.animationsEnabled,
                        onChanged: controller.setAnimationsEnabled,
                        activeThumbColor: controller.accentColor,
                      ),

                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsSection(
                    title: 'Notifications',
                    children: [
                      // Reminder time picker — shown above the toggle
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
                                    seedColor: controller.accentColor,
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
                      // Master enable/disable toggle — right-aligned switch below reminder time
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
                                  : const Color(0xFF000000).withValues(alpha: 0.06),
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
                                color: AppColors.lime.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_rounded,
                                color: AppColors.lime,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Enable reminders',
                                    style: AppText.body.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Receive daily reminders at the time above',
                                    style: AppText.caption.copyWith(color: mutedColor),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 32,
                              child: Switch.adaptive(
                                value: controller.remindersEnabled,
                                onChanged: controller.toggleReminders,
                                activeThumbColor: controller.accentColor,
                                activeTrackColor: controller.accentColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsSection(
                    title: 'Privacy',
                    children: [
                      SwitchListTile(
                        tileColor: Colors.transparent,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: controller.allAvailableCurrencies
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
                                      selectedColor: controller.accentColor,
                                      backgroundColor: isDark
                                          ? AppColors.panel
                                          : const Color(0xFFF0F0F0),
                                    ),
                                  )
                                  .toList(),
                            ),

                          ],
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
                            SlideFadePageRoute(
                              page: const CategoryManagementScreen(),
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
                            SlideFadePageRoute(
                              page: const CalendarScreen(),
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
                      // Reset All Progress — clears goals, history, and achievements
                      _SettingsTile(
                        icon: Icons.backup_rounded,
                        title: 'Backup Data',
                        subtitle: 'Export all goals, history, and settings',
                        iconColor: Colors.blue,
                        onTap: () async {
                          try {
                            await BackupService().exportData(controller);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Backup failed: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.restore_rounded,
                        title: 'Restore Data',
                        subtitle: 'Import from a previous backup file',
                        iconColor: Colors.blue,
                        onTap: () async {
                          // For now, trigger import via a dialog
                          final importResult = await _showImportDialog(context, controller);
                          if (importResult != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      importResult.success
                                          ? Icons.check_circle_rounded
                                          : Icons.error_rounded,
                                      color: AppColors.ink,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        importResult.message,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: importResult.success
                                    ? AppColors.lime
                                    : AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.restart_alt_rounded,
                        title: 'Reset All Progress',
                        subtitle: 'Clear goals, history, and restart achievements',
                        iconColor: const Color(0xFFFF7043),
                        onTap: () => _showResetProgressDialog(context, controller),
                      ),
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        iconColor: AppColors.error,
                        onTap: () async {
                          try {
                            final confirm = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
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
                              // 1. Sign out from auth service (clears session in Hive only — preserves all data)
                              await authService.signOut();
                              // 2. Clear in-memory state (does NOT touch Hive data at all)
                              await controller.signOutAndClear();
                              // 3. Show a brief confirmation before navigating
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: AppColors.ink, size: 18),
                                        SizedBox(width: 8),
                                        Text('Logged out successfully', style: TextStyle(color: AppColors.ink)),
                                      ],
                                    ),
                                    backgroundColor: AppColors.lime,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(milliseconds: 800),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                );
                                // Small delay to show the snackbar before navigating
                                await Future.delayed(const Duration(milliseconds: 400));
                              }
                              // 4. Notify GoalSaverApp to show login screen via the onLogout callback
                              if (context.mounted) {
                                onLogout?.call();
                              }
                            }
                          } catch (e) {
                            debugPrint('Logout error: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error_rounded, color: AppColors.ink, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Logout failed: $e', style: const TextStyle(color: AppColors.ink)),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              );
                              // Still try to navigate to login screen even if there's an error
                              onLogout?.call();
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
  /// Show import dialog for restoring from a backup JSON file.
  Future<BackupResult?> _showImportDialog(BuildContext context, GoalSaverController controller) async {
    final fileController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final textColor = isDark ? AppColors.white : AppColors.lightText;

    return showDialog<BackupResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Restore from Backup', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste the full file path to your backup JSON file,\nor use the share sheet to open it.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fileController,
              style: TextStyle(color: textColor),
              decoration: goalInputDecoration(
                'File path',
                Icons.folder_open_rounded,
                context: context,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFFFA726)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will REPLACE all current data with the backup.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFFFA726)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () async {
              final path = fileController.text.trim();
              if (path.isEmpty) return;
              final result = await BackupService().importData(controller, filePath: path);
              if (ctx.mounted) Navigator.pop(ctx, result);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Restore', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Show the selective reset progress dialog with checkboxes.
  void _showResetProgressDialog(BuildContext context, GoalSaverController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final accentColor = controller.accentColor;

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) => _SelectiveResetDialog(
        isDark: isDark,
        textColor: textColor,
        bgColor: bgColor,
        mutedColor: mutedColor,
        accentColor: accentColor,
        controller: controller,
        parentContext: context,
      ),
    );
  }
}

/// Dialog with checkboxes for selective progress reset.
class _SelectiveResetDialog extends StatefulWidget {
  final bool isDark;
  final Color textColor;
  final Color bgColor;
  final Color mutedColor;
  final Color accentColor;
  final GoalSaverController controller;
  final BuildContext parentContext;

  const _SelectiveResetDialog({
    required this.isDark,
    required this.textColor,
    required this.bgColor,
    required this.mutedColor,
    required this.accentColor,
    required this.controller,
    required this.parentContext,
  });

  @override
  State<_SelectiveResetDialog> createState() => _SelectiveResetDialogState();
}

class _SelectiveResetDialogState extends State<_SelectiveResetDialog> {
  late ResetFlags _flags;
  bool _selectAll = false;
  bool _showConfirmation = false;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _flags = ResetFlags();
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _flags.selectAll();
      } else {
        _flags.deselectAll();
      }
    });
  }

  void _toggleFlag(bool Function() get, void Function(bool) set) {
    setState(() {
      set(!get());
      _selectAll = _flags.goals && _flags.history && _flags.budgetAllocations &&
          _flags.savingsForecasts && _flags.reports &&
          _flags.analytics && _flags.healthScore && _flags.recentActivity &&
          _flags.goalMilestones && _flags.goalPredictions &&
          _flags.achievements && _flags.xpLevel && _flags.streak &&
          _flags.milestoneCelebrations && _flags.dailyMotivation &&
          _flags.notes && _flags.calendarEvents && _flags.profileData && _flags.coachInsights &&
          _flags.categories && _flags.predefinedCategories && _flags.reminders && _flags.preferences &&
          _flags.productImages && _flags.dashboardLayout;
    });
  }

  Future<void> _executeReset() async {
    setState(() => _isResetting = true);
    await widget.controller.resetSelectedProgress(_flags);
    if (mounted) {
      setState(() {
        _isResetting = false;
      });
      // Close the reset dialog.
      if (mounted && context.mounted) {
        Navigator.pop(context);
      }
      // Show celebration overlay after dialog dismisses
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.parentContext.mounted) {
          CelebrationOverlay.show(
            widget.parentContext,
            message: 'The selected data has been reset successfully! 🎉\nYour app is fully synchronized and ready to go.',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Confirmation step
    if (_showConfirmation) {
      return AlertDialog(
        backgroundColor: widget.bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF7043), size: 24),
            const SizedBox(width: 10),
            Text(
              'Confirm Reset',
              style: AppText.titleMedium.copyWith(color: widget.textColor),
            ),
          ],
        ),
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7043).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF7043).withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFFF7043), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This action cannot be undone!',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFFFF7043),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You are about to reset:',
                  style: TextStyle(fontSize: 13, color: widget.textColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._selectedItemsText(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showConfirmation = false),
            child: Text('Go Back', style: TextStyle(color: widget.mutedColor, fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: _isResetting ? null : _executeReset,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF7043),
              foregroundColor: AppColors.ink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isResetting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                  )
                : const Text('Confirm Reset', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      );
    }

    // Main selection dialog
    return AlertDialog(
      backgroundColor: widget.bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.restart_alt_rounded, color: Color(0xFFFF7043), size: 24),
          const SizedBox(width: 10),
          Text(
            'Reset Progress',
            style: AppText.titleMedium.copyWith(color: widget.textColor),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.55,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Select All toggle
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _toggleSelectAll,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectAll
                        ? widget.accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectAll
                          ? widget.accentColor.withValues(alpha: 0.3)
                          : widget.mutedColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectAll ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: _selectAll ? widget.accentColor : widget.mutedColor,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Select All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.textColor,
                        ),
                      ),
                      const Spacer(),
                      if (_selectAll)
                        Icon(Icons.deselect_rounded, color: widget.accentColor, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _resetGroupHeader('Financial Data', Icons.account_balance_rounded, widget.accentColor),
              const SizedBox(height: 4),
              _ResetCheckbox(
                icon: Icons.shopping_bag_rounded,
                label: 'Savings Goals',
                description: 'All products and targets',
                value: _flags.goals,
                onChanged: (v) => _toggleFlag(() => _flags.goals, (val) => _flags.goals = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.history_rounded,
                label: 'Savings History',
                description: 'All contribution logs',
                value: _flags.history,
                onChanged: (v) => _toggleFlag(() => _flags.history, (val) => _flags.history = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Budget Allocations',
                description: 'Savings plan allocations on goals',
                value: _flags.budgetAllocations,
                onChanged: (v) => _toggleFlag(() => _flags.budgetAllocations, (val) => _flags.budgetAllocations = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.trending_up_rounded,
                label: 'Savings Forecasts',
                description: 'Projected completion predictions',
                value: _flags.savingsForecasts,
                onChanged: (v) => _toggleFlag(() => _flags.savingsForecasts, (val) => _flags.savingsForecasts = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.assessment_rounded,
                label: 'Reports',
                description: 'Generated reports and summaries',
                value: _flags.reports,
                onChanged: (v) => _toggleFlag(() => _flags.reports, (val) => _flags.reports = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              const SizedBox(height: 8),
              _resetGroupHeader('Progress & Analytics', Icons.analytics_rounded, widget.accentColor),
              const SizedBox(height: 4),
              _ResetCheckbox(
                icon: Icons.bar_chart_rounded,
                label: 'Analytics, Charts & Statistics',
                description: 'Charts, trends, and visual data',
                value: _flags.analytics,
                onChanged: (v) => _toggleFlag(() => _flags.analytics, (val) => _flags.analytics = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.favorite_rounded,
                label: 'Financial Health Score',
                description: 'Health score and assessments',
                value: _flags.healthScore,
                onChanged: (v) => _toggleFlag(() => _flags.healthScore, (val) => _flags.healthScore = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.history_edu_rounded,
                label: 'Recent Activity',
                description: 'Recent activity feed',
                value: _flags.recentActivity,
                onChanged: (v) => _toggleFlag(() => _flags.recentActivity, (val) => _flags.recentActivity = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.flag_rounded,
                label: 'Goal Milestones',
                description: 'Completed milestones and dates',
                value: _flags.goalMilestones,
                onChanged: (v) => _toggleFlag(() => _flags.goalMilestones, (val) => _flags.goalMilestones = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.auto_graph_rounded,
                label: 'Goal Predictions',
                description: 'Estimated completion predictions',
                value: _flags.goalPredictions,
                onChanged: (v) => _toggleFlag(() => _flags.goalPredictions, (val) => _flags.goalPredictions = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              const SizedBox(height: 8),
              _resetGroupHeader('Gamification', Icons.emoji_events_rounded, widget.accentColor),
              const SizedBox(height: 4),
              _ResetCheckbox(
                icon: Icons.emoji_events_rounded,
                label: 'Achievements & Badges',
                description: 'All earned badges and achievements',
                value: _flags.achievements,
                onChanged: (v) => _toggleFlag(() => _flags.achievements, (val) => _flags.achievements = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.military_tech_rounded,
                label: 'XP & User Level',
                description: 'Experience points and player level',
                value: _flags.xpLevel,
                onChanged: (v) => _toggleFlag(() => _flags.xpLevel, (val) => _flags.xpLevel = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.local_fire_department_rounded,
                label: 'Savings Streak',
                description: 'Current savings streak count',
                value: _flags.streak,
                onChanged: (v) => _toggleFlag(() => _flags.streak, (val) => _flags.streak = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.celebration_rounded,
                label: 'Milestone Celebrations',
                description: 'Celebration animations and effects',
                value: _flags.milestoneCelebrations,
                onChanged: (v) => _toggleFlag(() => _flags.milestoneCelebrations, (val) => _flags.milestoneCelebrations = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.wb_sunny_rounded,
                label: 'Daily Motivation',
                description: 'Daily motivational messages',
                value: _flags.dailyMotivation,
                onChanged: (v) => _toggleFlag(() => _flags.dailyMotivation, (val) => _flags.dailyMotivation = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),

              const SizedBox(height: 8),
              _resetGroupHeader('Personal Data', Icons.person_rounded, widget.accentColor),
              const SizedBox(height: 4),
              _ResetCheckbox(
                icon: Icons.note_alt_rounded,
                label: 'Notes',
                description: 'All personal notes',
                value: _flags.notes,
                onChanged: (v) => _toggleFlag(() => _flags.notes, (val) => _flags.notes = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar Events',
                description: 'All scheduled calendar events',
                value: _flags.calendarEvents,
                onChanged: (v) => _toggleFlag(() => _flags.calendarEvents, (val) => _flags.calendarEvents = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.person_rounded,
                label: 'Profile Data',
                description: 'Name, email, and avatar',
                value: _flags.profileData,
                onChanged: (v) => _toggleFlag(() => _flags.profileData, (val) => _flags.profileData = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.psychology_rounded,
                label: 'Smart Savings Coach Insights',
                description: 'AI coach tips and suggestions',
                value: _flags.coachInsights,
                onChanged: (v) => _toggleFlag(() => _flags.coachInsights, (val) => _flags.coachInsights = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              const SizedBox(height: 8),
              _resetGroupHeader('Settings', Icons.settings_rounded, widget.accentColor),
              const SizedBox(height: 4),
              _ResetCheckbox(
                icon: Icons.category_rounded,
                label: 'Categories',
                description: 'Custom product categories',
                value: _flags.categories,
                onChanged: (v) => _toggleFlag(() => _flags.categories, (val) => _flags.categories = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.auto_awesome_rounded,
                label: 'Predefined Categories',
                description: 'Unlocked predefined categories',
                value: _flags.predefinedCategories,
                onChanged: (v) => _toggleFlag(() => _flags.predefinedCategories, (val) => _flags.predefinedCategories = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.notifications_rounded,
                label: 'Reminders & Notifications',
                description: 'Notification schedules and settings',
                value: _flags.reminders,
                onChanged: (v) => _toggleFlag(() => _flags.reminders, (val) => _flags.reminders = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.palette_rounded,
                label: 'Theme, Currency & Preferences',
                description: 'Dark mode, accent color, currency, and display',
                value: _flags.preferences,
                onChanged: (v) => _toggleFlag(() => _flags.preferences, (val) => _flags.preferences = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
              _ResetCheckbox(
                icon: Icons.image_rounded,
                label: 'Product Images',
                description: 'All product photo URLs',
                value: _flags.productImages,
                onChanged: (v) => _toggleFlag(() => _flags.productImages, (val) => _flags.productImages = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),

              _ResetCheckbox(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard Layout',
                description: 'Card order and visibility',
                value: _flags.dashboardLayout,
                onChanged: (v) => _toggleFlag(() => _flags.dashboardLayout, (val) => _flags.dashboardLayout = val),
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: widget.mutedColor, fontWeight: FontWeight.w600)),
        ),
        FilledButton(
          onPressed: _flags.anySelected
              ? () => setState(() => _showConfirmation = true)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: _flags.anySelected
                ? const Color(0xFFFF7043)
                : widget.mutedColor.withValues(alpha: 0.3),
            foregroundColor: _flags.anySelected ? AppColors.ink : widget.mutedColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Reset Selected', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _resetGroupHeader(String title, IconData icon, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: accentColor.withValues(alpha: 0.15)),
          ),
        ],
      ),
    );
  }

  List<Widget> _selectedItemsText() {
    final items = <Widget>[];
    // Financial Data
    if (_flags.goals) items.add(_resetItemText(Icons.shopping_bag_rounded, 'Savings Goals'));
    if (_flags.history) items.add(_resetItemText(Icons.history_rounded, 'Savings History'));
    if (_flags.budgetAllocations) items.add(_resetItemText(Icons.account_balance_wallet_rounded, 'Budget Allocations'));
    if (_flags.savingsForecasts) items.add(_resetItemText(Icons.trending_up_rounded, 'Savings Forecasts'));
    if (_flags.reports) items.add(_resetItemText(Icons.assessment_rounded, 'Reports'));
    // Progress & Analytics
    if (_flags.analytics) items.add(_resetItemText(Icons.bar_chart_rounded, 'Analytics, Charts & Statistics'));
    if (_flags.healthScore) items.add(_resetItemText(Icons.favorite_rounded, 'Financial Health Score'));
    if (_flags.recentActivity) items.add(_resetItemText(Icons.history_edu_rounded, 'Recent Activity'));
    if (_flags.goalMilestones) items.add(_resetItemText(Icons.flag_rounded, 'Goal Milestones'));
    if (_flags.goalPredictions) items.add(_resetItemText(Icons.auto_graph_rounded, 'Goal Predictions'));
    // Gamification
    if (_flags.achievements) items.add(_resetItemText(Icons.emoji_events_rounded, 'Achievements & Badges'));
    if (_flags.xpLevel) items.add(_resetItemText(Icons.military_tech_rounded, 'XP & User Level'));
    if (_flags.streak) items.add(_resetItemText(Icons.local_fire_department_rounded, 'Savings Streak'));
    if (_flags.milestoneCelebrations) items.add(_resetItemText(Icons.celebration_rounded, 'Milestone Celebrations'));
    if (_flags.dailyMotivation) items.add(_resetItemText(Icons.wb_sunny_rounded, 'Daily Motivation'));
    // Personal Data
    if (_flags.notes) items.add(_resetItemText(Icons.note_alt_rounded, 'Notes'));
    if (_flags.calendarEvents) items.add(_resetItemText(Icons.calendar_month_rounded, 'Calendar Events'));
    if (_flags.profileData) items.add(_resetItemText(Icons.person_rounded, 'Profile Data'));
    if (_flags.coachInsights) items.add(_resetItemText(Icons.psychology_rounded, 'Smart Savings Coach Insights'));
    // Settings
    if (_flags.categories) items.add(_resetItemText(Icons.category_rounded, 'Categories'));
    if (_flags.predefinedCategories) items.add(_resetItemText(Icons.auto_awesome_rounded, 'Predefined Categories'));
    if (_flags.reminders) items.add(_resetItemText(Icons.notifications_rounded, 'Reminders & Notifications'));
    if (_flags.preferences) items.add(_resetItemText(Icons.palette_rounded, 'Theme, Accent Color & Preferences'));
    if (_flags.productImages) items.add(_resetItemText(Icons.image_rounded, 'Product Images'));

    if (_flags.dashboardLayout) items.add(_resetItemText(Icons.dashboard_rounded, 'Dashboard Layout'));
    return items;
  }

  Widget _resetItemText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: widget.accentColor),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 12, color: widget.textColor)),
        ],
      ),
    );
  }
}

/// A single checkbox row for selective reset.
class _ResetCheckbox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;

  const _ResetCheckbox({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: value
                ? accentColor.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: value
                ? Border.all(color: accentColor.withValues(alpha: 0.2))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: value ? accentColor : mutedColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: value
                      ? accentColor.withValues(alpha: 0.12)
                      : mutedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: value ? accentColor : mutedColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(fontSize: 10, color: mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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