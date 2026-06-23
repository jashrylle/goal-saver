import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Page header widget with eyebrow label, large title, and optional trailing icon.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    this.eyebrow = 'Dashboard',
    this.title = 'Your savings',
    this.trailingIcon,
  });

  final String eyebrow;
  final String title;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: AppText.caption),
              const SizedBox(height: 4),
              Text(title, style: AppText.titleLarge, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (trailingIcon != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(trailingIcon, color: AppColors.muted, size: 22),
          ),
      ],
    );
  }
}

/// Main input decoration style for goal forms
InputDecoration goalInputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFFFFFFFF),
        width: 0.5,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
        width: 0.5,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFF5FDE9E),
        width: 1.5,
      ),
    ),
    filled: true,
    fillColor: const Color(0xFFFFFFFF).withValues(alpha: 0.05),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

/// Pressable interaction widget - makes any widget pressable with visual feedback
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.96).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Glassmorphism card widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.height,
    this.width,
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isDark
                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.055)
                  : const Color(0xFF000000).withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(24),
          border: border ??
              Border.all(
                color: const Color(0xFFFFFFFF)
                    .withValues(alpha: isDark ? 0.08 : 0.1),
                width: 1,
              ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.06),
              blurRadius: 28,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Category filter chip for goal filtering
class CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF5FDE9E).withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF5FDE9E)
                : const Color(0xFFFFFFFF).withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? const Color(0xFF5FDE9E)
                : const Color(0xFF889B97),
          ),
        ),
      ),
    );
  }
}

/// Goal status pill badge
class GoalStatusPill extends StatelessWidget {
  final SavingsGoal goal;

  const GoalStatusPill({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color color;

    if (goal.completed) {
      label = 'Completed';
      color = const Color(0xFF5FDE9E);
    } else if (goal.paused) {
      label = 'Paused';
      color = const Color(0xFF889B97);
    } else if (goal.archived) {
      label = 'Archived';
      color = const Color(0xFF4A5F5C);
    } else if (goal.deleted) {
      label = 'Deleted';
      color = const Color(0xFF7B8381);
    } else {
      label = 'Active';
      color = const Color(0xFF5FDE9E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Goal meta tile for detailed info
class GoalMetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const GoalMetaTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF889B97)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF889B97))),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF))),
        ],
      ),
    );
  }
}

/// Animated counter widget for balance display
class AnimatedCounter extends StatefulWidget {
  final double value;
  final String prefix;
  final TextStyle style;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.prefix,
    required this.style,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _previousValue;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
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
        final displayValue =
            _previousValue + (widget.value - _previousValue) * _animation.value;
        return Text(
          '${widget.prefix}${displayValue.toStringAsFixed(0)}',
          style: widget.style,
        );
      },
    );
  }
}

/// Metric chip for displaying stats
class MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const MetricChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF5FDE9E).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF5FDE9E).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF5FDE9E)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5FDE9E),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable goal actions for goal card
class ExpandableGoalActions extends StatefulWidget {
  final VoidCallback onContribution;
  final VoidCallback onGoal;

  const ExpandableGoalActions({
    super.key,
    required this.onContribution,
    required this.onGoal,
  });

  @override
  State<ExpandableGoalActions> createState() => _ExpandableGoalActionsState();
}

class _ExpandableGoalActionsState extends State<ExpandableGoalActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Pressable(
                    onTap: widget.onContribution,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5FDE9E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF5FDE9E).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: Color(0xFF5FDE9E), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Save Money',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5FDE9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Pressable(
                    onTap: widget.onGoal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5FDE9E).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF5FDE9E),
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flag_rounded, color: Color(0xFF5FDE9E), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Add Goal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5FDE9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Achievement shelf for displaying badges
class AchievementShelf extends StatelessWidget {
  const AchievementShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Color(0xFF5FDE9E)),
              SizedBox(width: 10),
              Text(
                'Achievement Badges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: List.generate(
              8,
              (index) => Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 28,
                      color: const Color(0xFF889B97).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Locked',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF889B97),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


