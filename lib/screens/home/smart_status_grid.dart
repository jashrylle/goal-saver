import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

/// 3-column grid showing Active / Overdue / Completed counts.
class SmartStatusGrid extends StatelessWidget {
  const SmartStatusGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final activeGoals = controller.goals.length;
    final overdue = controller.goals.where((g) => g.isOverdue).length;
    final completed = controller.allActiveGoals.where((g) => g.completed).length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        _StatusTile(label: 'Active',    value: '$activeGoals', icon: Icons.flag_rounded,         color: AppColors.lime),
        _StatusTile(label: 'Overdue',   value: '$overdue',     icon: Icons.warning_rounded,      color: const Color(0xFFFF6B6B)),
        _StatusTile(label: 'Completed', value: '$completed',   icon: Icons.check_circle_rounded, color: const Color(0xFF5FDE9E)),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppText.title),
              Text(label, style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }
}
