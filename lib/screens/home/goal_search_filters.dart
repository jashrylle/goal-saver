import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common_widgets.dart';

/// Search field + category filter chips for the goals list.
class GoalSearchAndFilters extends StatelessWidget {
  const GoalSearchAndFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.muted, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: controller.updateSearch,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(color: AppColors.muted),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              CategoryFilterChip(
                label: 'All',
                selected: controller.categoryFilter == null,
                onTap: () => controller.setCategory(null),
              ),
              const SizedBox(width: 8),
              ...GoalCategory.predefined.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryFilterChip(
                    label: category.label,
                    selected: controller.categoryFilter == category,
                    onTap: () => controller.setCategory(category),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
