import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'common_widgets.dart';

/// Skeleton placeholder shown while goals load.
class ShimmerGoalList extends StatelessWidget {
  const ShimmerGoalList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}

/// Empty state card shown when there are no goals.
class EmptyGoalsCard extends StatelessWidget {
  const EmptyGoalsCard({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 44, color: mutedColor),
          const SizedBox(height: 12),
          Text(
            'No products saved yet',
            style: AppText.title.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first item you want to save for!',
            style: AppText.bodyMuted.copyWith(color: mutedColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Pressable(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Add Product',
                style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
