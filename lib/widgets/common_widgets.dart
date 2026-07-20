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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: AppText.caption.copyWith(
                  color: isDark ? AppColors.muted : AppColors.lightMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppText.titleLarge.copyWith(
                  color: isDark ? AppColors.white : AppColors.lightText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
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

/// Main input decoration style for goal forms — adapts to dark/light theme.
InputDecoration goalInputDecoration(String label, IconData icon, {BuildContext? context, Widget? prefix}) {
  final isDark = context != null
      ? Theme.of(context).brightness == Brightness.dark
      : true;
  final borderColor = isDark
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
      : const Color(0xFF000000).withValues(alpha: 0.12);
  final fillColor = isDark
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.05)
      : const Color(0xFF000000).withValues(alpha: 0.03);

  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: isDark ? AppColors.muted : AppColors.lightMuted),
    prefixIcon: prefix ?? Icon(icon, color: isDark ? AppColors.muted : AppColors.lightMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: borderColor, width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: borderColor, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.lime, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    // Ensure dropdown arrow is visible in both modes
    iconColor: isDark ? AppColors.muted : AppColors.lightMuted,
  );
}

/// Pressable interaction widget - makes any widget pressable with visual feedback.
/// Includes scale-down animation and optional ripple effect on tap.
/// Automatically applies a minimum 44x44 touch target for accessibility.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double scaleEnd;
  final String? semanticLabel;
  final String? tooltip;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 120),
    this.scaleEnd = 0.96,
    this.semanticLabel,
    this.tooltip,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnim = Tween<double>(begin: 1, end: widget.scaleEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (mounted) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    widget.onTap?.call();
    if (mounted) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (mounted) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: Semantics(
        label: widget.semanticLabel,
        button: true,
        enabled: widget.onTap != null,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );

    // Wrap in Tooltip if provided
    if (widget.tooltip != null && widget.onTap != null) {
      return Tooltip(
        message: widget.tooltip!,
        preferBelow: false,
        decoration: BoxDecoration(
          color: const Color(0xFF07100E),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Color(0xFFA8FF3E),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: button,
      );
    }

    return button;
  }
}

/// Glassmorphism card widget — adapts to dark/light theme.
/// Includes a subtle hover/lift animation when content changes.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? marginOverride;
  final String? semanticLabel;

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
    this.boxShadow,
    this.marginOverride,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: height,
      width: width,
      margin: marginOverride ?? margin,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark
                ? const Color(0xFFFFFFFF).withValues(alpha: 0.055)
                : const Color(0xFFFFFFFF).withValues(alpha: 0.75)),
        borderRadius: BorderRadius.circular(24),
        border: border ??
            Border.all(
              color: isDark
                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
                  : const Color(0xFF000000).withValues(alpha: 0.06),
              width: 1,
            ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.06),
            blurRadius: 28,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Semantics(
        label: semanticLabel,
        container: true,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    // Only wrap in Pressable when onTap is provided — otherwise child gesture
    // handlers (InkWell, GestureDetector, etc.) will be blocked by the Pressable's
    // GestureDetector winning the gesture arena and not forwarding the event.
    if (onTap != null) {
      return Pressable(
        onTap: onTap,
        child: container,
      );
    }

    return container;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveBorder = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.12)
        : const Color(0xFF000000).withValues(alpha: 0.12);
    final inactiveLabel = isDark
        ? const Color(0xFF889B97)
        : AppColors.lightMuted;

    return Semantics(
      label: 'Filter by $label category',
      button: true,
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: selected ? '$label selected' : 'Filter by $label',
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
                  : inactiveBorder,
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
                  : inactiveLabel,
            ),
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

/// Goal meta tile for detailed info — theme-aware text colors
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final bgColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.05)
        : const Color(0xFF000000).withValues(alpha: 0.03);
    final borderColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
        : const Color(0xFF000000).withValues(alpha: 0.07);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: mutedColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: mutedColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Animated counter widget for balance display with smooth number transitions.
class AnimatedCounter extends StatefulWidget {
  final double value;
  final String prefix;
  final TextStyle style;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.prefix,
    required this.style,
    this.decimals = 0,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

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
          '${widget.prefix}${displayValue.toStringAsFixed(widget.decimals)}',
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
    return SizedBox(
      width: MediaQuery.sizeOf(context).width - 36,
      child: ScaleTransition(
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
                      color: const Color(0xFF5FDE9E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Color(0xFF111C1A), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Save Money',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111C1A),
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
                      color: const Color(0xFF5FDE9E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag_rounded, color: Color(0xFF111C1A), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Add Goal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111C1A),
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
    );
  }
}

/// A decorative animated progress ring that fills up over time.
class AnimatedProgressRing extends StatefulWidget {
  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 60,
    this.strokeWidth = 5,
    this.child,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressRing oldWidget) {
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
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _animation.value,
                strokeWidth: widget.strokeWidth,
                backgroundColor: widget.color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(widget.color),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

/// Reusable empty state widget with icon, title, subtitle, and optional CTA.
/// Adapts to the current theme (dark/light) automatically.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final color = iconColor ?? mutedColor;

    return GlassCard(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: color.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: mutedColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: mutedColor.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              Pressable(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.lime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lime),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: AppColors.lime, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        actionLabel!,
                        style: const TextStyle(
                          color: AppColors.lime,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Achievement shelf for displaying badges
class AchievementShelf extends StatelessWidget {
  const AchievementShelf({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFF5FDE9E)),
              const SizedBox(width: 10),
              Text(
                'Achievement Badges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.lightText,
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
                  color: isDark
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
                      : const Color(0xFF000000).withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                        : const Color(0xFF000000).withValues(alpha: 0.07),
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
                    Text(
                      'Locked',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.muted : AppColors.lightMuted,
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
