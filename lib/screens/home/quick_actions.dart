import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/sheets/add_goal_sheet.dart';
import '../../widgets/sheets/productivity_sheet.dart';

/// Two-button row for quickly adding a product or adding savings.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<GoalSaverController>().accentColor;
    return Row(
      children: [
        Expanded(
          child: Pressable(
            onTap: () => showAddGoalSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: AppColors.ink),
                  const SizedBox(width: 8),
                  Text('Add Product', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Pressable(
            onTap: () => showProductivitySheet(
              context,
              title: 'Add Savings',
              icon: Icons.savings_rounded,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_rounded, color: AppColors.ink),
                  SizedBox(width: 8),
                  Text('Add Savings', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
