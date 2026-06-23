import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common_widgets.dart';

/// Toggle row for selecting the analytics date range.
class AnalyticsRangeFilter extends StatelessWidget {
  const AnalyticsRangeFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AnalyticsRange.values.map((range) {
          final selected = controller.range == range;
          final isLast = range == AnalyticsRange.values.last;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: Pressable(
              onTap: () => controller.setRange(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.lime.withValues(alpha: 0.18) : AppColors.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.lime : AppColors.muted.withValues(alpha: 0.18),
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Text(
                  range.label,
                  style: TextStyle(
                    color: selected ? AppColors.lime : AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
