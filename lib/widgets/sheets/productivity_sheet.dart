import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/goal_controller.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/extensions.dart';
import '../common_widgets.dart';

/// Opens the productivity (add savings) bottom sheet.
Future<void> showProductivitySheet(
  BuildContext context, {
  required String title,
  required IconData icon,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => ProductivitySheet(title: title, icon: icon),
  );
}

/// Bottom sheet listing goals and allowing quick savings deposits.
class ProductivitySheet extends StatelessWidget {
  const ProductivitySheet({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final goals = controller.goals;

    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.lime),
              const SizedBox(width: 10),
              Text(title, style: AppText.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          if (goals.isEmpty)
            const Text('No active products to add savings to.', style: AppText.bodyMuted)
          else
            ...goals.map((goal) {
              final suggested = GoalController.getSuggestedDeposit(goal);
              final amount = suggested.toDouble();
              return Pressable(
                onTap: () {
                  controller.addSavings(goal, suggested);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.muted.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      Icon(goal.icon, color: goal.color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(goal.title, style: AppText.body)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.lime.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₱${amount.money}',
                          style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
