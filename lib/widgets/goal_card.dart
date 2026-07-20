import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../state/goal_saver_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'common_widgets.dart';

/// Animated goal card shown in the home list.
class AnimatedGoalCard extends StatelessWidget {
  const AnimatedGoalCard({
    super.key,
    required this.goal,
    required this.index,
    required this.onTap,
  });

  final SavingsGoal goal;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final progress = goal.progress;
    final moneyNeeded = goal.moneyNeeded;

    return Semantics(
      label: '${goal.title}, ${(goal.progress * 100).round()}% complete, ${goal.timeLeft} remaining',
      hint: 'Tap to view details',
      child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 28 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GlassCard(
        onTap: onTap,
        semanticLabel: '${goal.title} goal card',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Product photo thumbnail (if available), otherwise fall back to category icon
                  if (goal.productPhotoUrl != null && goal.productPhotoUrl!.isNotEmpty)
                    _ProductPhotoThumbnail(photoUrl: goal.productPhotoUrl!, color: goal.color, size: 44)
                  else
                    Semantics(
                      label: '${goal.category.label} icon',
                      excludeSemantics: true,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: goal.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(goal.icon, color: goal.color, size: 22),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.title, style: AppText.title.copyWith(color: textColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(goal.category.label, style: AppText.caption.copyWith(color: mutedColor)),
                      ],
                    ),
                  ),
                  GoalStatusPill(goal: goal),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Money Needed', style: AppText.caption.copyWith(color: mutedColor)),
                        const SizedBox(height: 4),
                        Text(
                          controller.showBalance
                              ? controller.formatMoney(moneyNeeded)
                              : '${controller.currencySymbol} •••',
                          style: AppText.title.copyWith(color: controller.accentColor),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Saved', style: AppText.caption.copyWith(color: mutedColor)),
                        const SizedBox(height: 4),
                        Text(
                          controller.showBalance
                              ? controller.formatMoney(goal.saved)
                              : '${controller.currencySymbol} •••',
                          style: AppText.title.copyWith(color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Recommended this period chip + plan-adjusted badge
              if (!goal.completed && goal.recommendedDeposit > 0) ...[                
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.savings_rounded, size: 11, color: AppColors.lime),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Recommended ${goal.frequency.label.toLowerCase()}: ${controller.showBalance ? controller.formatMoney(goal.recommendedDeposit) : "•••"}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.lime,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    if (goal.plan != null && goal.plan!.currentIntervalAmount != goal.plan!.baseIntervalAmount)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA726).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Plan adjusted',
                          style: TextStyle(
                            fontSize: 9,
                            color: const Color(0xFFFFA726),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: value,
                      backgroundColor: AppColors.muted.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation(goal.color),
                    ),
                  );
                },
              ),
          const SizedBox(height: 10),
          // Exact remaining/completed amount display
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      goal.completed ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 12,
                      color: goal.completed ? const Color(0xFF00E676) : mutedColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        goal.completed
                            ? 'Completed!${goal.excessSaved > 0 ? " +${controller.showBalance ? controller.formatMoney(goal.excessSaved) : "•••"} in excess savings" : " Saved ${controller.showBalance ? controller.formatMoney(goal.saved) : "•••"}"}'
                            : '${controller.showBalance ? controller.formatMoney(goal.remaining) : "•••"} remaining of ${controller.showBalance ? controller.formatMoney(goal.target) : "•••"}',
                        style: TextStyle(
                          fontSize: 10,
                          color: goal.completed ? const Color(0xFF00E676) : mutedColor,
                          fontWeight: goal.completed ? FontWeight.w700 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                fit: FlexFit.loose,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MilestoneIndicator(goal: goal),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${goal.progressPercent} • ${goal.timeLeft}',
                        style: AppText.caption.copyWith(color: mutedColor),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// Small product photo thumbnail shown in the goal card.
class _ProductPhotoThumbnail extends StatelessWidget {
  final String photoUrl;
  final Color color;
  final double size;

  const _ProductPhotoThumbnail({
    required this.photoUrl,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl.startsWith('http')
          ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, e, error) => _fallback(context))
          : Image.file(File(photoUrl), fit: BoxFit.cover, errorBuilder: (_, e, error) => _fallback(context)),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.18),
      child: Icon(Icons.image_rounded, color: color, size: size * 0.45),
    );
  }
}

/// Row of milestone dots showing 25/50/75/100% progress.
class MilestoneIndicator extends StatelessWidget {
  const MilestoneIndicator({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final milestones = [0.25, 0.5, 0.75, 1.0];

    return Row(
      children: milestones.map((m) {
        final reached = progress >= m;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Icon(
            reached ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: reached ? AppColors.lime : AppColors.muted,
          ),
        );
      }).toList(),
    );
  }
}

/// Custom progress bar with optional milestone tick marks and fill animation.
class SavingsProgressBar extends StatefulWidget {
  final double progress;
  final Color color;
  final List<double> milestones;

  const SavingsProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.milestones = const [0.25, 0.5, 0.75, 1.0],
  });

  @override
  State<SavingsProgressBar> createState() => _SavingsProgressBarState();
}

class _SavingsProgressBarState extends State<SavingsProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SavingsProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: _animation.value, end: widget.progress)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final double progress = _animation.value.clamp(0, 1).toDouble();
        return LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (progress > 0)
                  ...widget.milestones.where((m) => m <= progress).map((m) {
                    return Positioned(
                      left: m * barWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: AppColors.muted.withValues(alpha: 0.4),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }
}

/// Animated savings list item with staggered entrance.
class AnimatedSavingsLogItem extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedSavingsLogItem({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<AnimatedSavingsLogItem> createState() => _AnimatedSavingsLogItemState();
}

class _AnimatedSavingsLogItemState extends State<AnimatedSavingsLogItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    final delay = widget.index * 50;
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}
