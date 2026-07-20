import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common_widgets.dart';

/// 3-column grid showing Active / Overdue / Completed counts with animated
/// counters and detailed breakdown dialogs on tap.
class SmartStatusGrid extends StatelessWidget {
  const SmartStatusGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final activeGoals = controller.goals.length;
    final overdue = controller.goals.where((g) => g.isOverdue).length;
    final completed = controller.allActiveGoals.where((g) => g.completed).length;
    final streak = controller.streakDays;

    return Row(
      children: [
        // Left column: Active + Overdue
        Expanded(
          child: Column(
            children: [
              _CompactTile(
                label: 'Active',
                value: activeGoals,
                icon: Icons.flag_rounded,
                color: AppColors.lime,
                detailTitle: 'Active Goals',
                detailBody: activeGoals > 0
                    ? 'You have $activeGoals active goal${activeGoals != 1 ? 's' : ''} in progress.'
                    : 'No active goals yet. Tap + to create your first!',
              ),
              const SizedBox(height: 8),
              _CompactTile(
                label: 'Overdue',
                value: overdue,
                icon: Icons.warning_rounded,
                color: const Color(0xFFFF6B6B),
                detailTitle: 'Overdue Goals',
                detailBody: overdue > 0
                    ? '$overdue goal${overdue != 1 ? 's are' : ' is'} past deadline.'
                    : 'No overdue goals \u2014 great job staying on schedule!',
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Right column: Completed + Streak
        Expanded(
          child: Column(
            children: [
              _CompactTile(
                label: 'Completed',
                value: completed,
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF5FDE9E),
                detailTitle: 'Completed Goals',
                detailBody: completed > 0
                    ? 'You have completed $completed goal${completed != 1 ? 's' : ''}! \uD83C\uDF89'
                    : 'No goals completed yet. Keep saving consistently!',
              ),
              const SizedBox(height: 8),
              _CompactTile(
                label: 'Streak',
                value: streak,
                icon: Icons.local_fire_department_rounded,
                color: streak >= 7
                    ? const Color(0xFFFF7043)
                    : streak >= 3
                        ? const Color(0xFFFFA726)
                        : AppColors.muted,
                detailTitle: 'Savings Streak',
                detailBody: streak >= 30
                    ? '\uD83D\uDD25 Incredible! $streak-day streak! Over a month!'
                    : streak >= 7
                        ? '\uD83D\uDD25 Great momentum! $streak-day streak. Keep going!'
                        : streak >= 3
                            ? '\uD83D\uDCAA Good start! $streak-day streak.'
                            : '\uD83C\uDFAF Start your streak today \u2014 log your first savings!',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactTile extends StatefulWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String detailTitle;
  final String detailBody;

  const _CompactTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.detailTitle,
    required this.detailBody,
  });

  @override
  State<_CompactTile> createState() => _CompactTileState();
}

class _CompactTileState extends State<_CompactTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void didUpdateWidget(_CompactTile old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showDetail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.panel : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 24),
            const SizedBox(width: 10),
            Text(
              widget.detailTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? AppColors.white : AppColors.lightText,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${widget.value}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.detailBody,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.muted : AppColors.lightMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.lime)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final bgColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.06)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.75);
    final borderColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
        : const Color(0xFF000000).withValues(alpha: 0.06);

    return Pressable(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with colored background
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: widget.color, size: 14),
            ),
            const SizedBox(width: 8),
            // Value and label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (context, child) {
                      final animatedVal = (widget.value * _anim.value).round();
                      return Text(
                        '$animatedVal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.1,
                        ),
                      );
                    },
                  ),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: mutedColor,
                      height: 1.2,
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
