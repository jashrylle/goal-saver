import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common_widgets.dart';

/// Search field + category filter chips for the goals list.
class GoalSearchAndFilters extends StatelessWidget {
  const GoalSearchAndFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final searchBg = isDark
        ? AppColors.panel
        : const Color(0xFFFFFFFF).withValues(alpha: 0.85);
    final searchBorder = isDark
        ? AppColors.muted.withValues(alpha: 0.18)
        : const Color(0xFF000000).withValues(alpha: 0.08);

    return Column(
      children: [
        Semantics(
          label: 'Search savings goals',
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: searchBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: searchBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: mutedColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: controller.updateSearch,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(color: mutedColor),
                    border: InputBorder.none,
                  ),

                ),
              ),
              if (controller.searchQuery.isNotEmpty)
                Pressable(
                  onTap: () => controller.updateSearch(''),
                  semanticLabel: 'Clear search',
                  child: Icon(Icons.close_rounded, color: mutedColor, size: 18),
                ),
            ],
          ),
        ),),
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
              ...controller.allCategories.map(
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
