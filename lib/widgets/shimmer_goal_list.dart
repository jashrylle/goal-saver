import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'common_widgets.dart';

/// Skeleton placeholder shown while goals load.
class ShimmerGoalList extends StatefulWidget {
  const ShimmerGoalList({super.key});

  @override
  State<ShimmerGoalList> createState() => _ShimmerGoalListState();
}

class _ShimmerGoalListState extends State<ShimmerGoalList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.055)
        : const Color(0xFF000000).withValues(alpha: 0.04);
    final shimmerColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
        : const Color(0xFF000000).withValues(alpha: 0.06);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (_, index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final shimmerOffset = _animation.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    baseColor,
                    Color.lerp(baseColor, shimmerColor, (shimmerOffset.clamp(0, 1)) - (shimmerOffset - 1).clamp(0, 1))!,
                    baseColor,
                  ],
                  stops: [
                    (shimmerOffset - 0.3).clamp(0, 1),
                    shimmerOffset.clamp(0, 1),
                    (shimmerOffset + 0.3).clamp(0, 1),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row shimmer
                    Row(
                      children: [
                        // Icon placeholder
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 14,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 10,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 24,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Amount row shimmer
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar shimmer
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first item you want to save for!',
            style: TextStyle(fontSize: 13, color: mutedColor),
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
