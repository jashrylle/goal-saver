import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';

/// Settings tab screen with theme, reminders, balance, and currency controls.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AppBackground(),
        SafeArea(
          child: Consumer<GoalSaverController>(
            builder: (context, controller, _) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const DashboardHeader(eyebrow: 'Settings', title: 'Preferences'),
                  const SizedBox(height: 18),
                  SwitchListTile(
                    title: const Text('Dark mode', style: AppText.body),
                    value: controller.isDarkMode,
                    onChanged: controller.toggleTheme,
                  ),
                  SwitchListTile(
                    title: const Text('Reminders', style: AppText.body),
                    value: controller.remindersEnabled,
                    onChanged: controller.toggleReminders,
                  ),
                  SwitchListTile(
                    title: const Text('Show balance', style: AppText.body),
                    value: controller.showBalance,
                    onChanged: (_) => controller.toggleBalanceVisibility(),
                  ),
                  const SizedBox(height: 18),
                  Text('Currency', style: AppText.title),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: ['PHP', 'USD', 'EUR', 'GBP']
                        .map(
                          (code) => ChoiceChip(
                            label: Text(code),
                            selected: controller.currencyCode == code,
                            onSelected: (_) => controller.setCurrency(code),
                          ),
                        )
                        .toList(),
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
