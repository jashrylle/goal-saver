import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

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
      childAspectRatio: 1.15,
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

  void _onTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label: $value goal${value != "1" ? "s" : ""}'),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final bgColor = isDark
        ? AppColors.panel
        : const Color(0xFFFFFFFF).withValues(alpha: 0.85);
    final borderColor = isDark
        ? AppColors.muted.withValues(alpha: 0.12)
        : const Color(0xFF000000).withValues(alpha: 0.07);

    return Pressable(
      onTap: () => _onTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: AppText.title.copyWith(color: textColor),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: AppText.caption.copyWith(color: mutedColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
