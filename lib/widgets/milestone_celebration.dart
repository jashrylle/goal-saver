import 'package:flutter/material.dart';
import '../models/goal_model.dart' show SavingsGoal;
import '../utils/app_colors.dart';
import '../logic/daily_motivation.dart';


/// Shows a milestone celebration overlay when a goal reaches 25%, 50%, 75%, or 100%.
class MilestoneCelebration extends StatefulWidget {
  final SavingsGoal goal;
  final int milestonePercentage;
  final VoidCallback onDismiss;

  const MilestoneCelebration({
    super.key,
    required this.goal,
    required this.milestonePercentage,
    required this.onDismiss,
  });

  @override
  State<MilestoneCelebration> createState() => _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends State<MilestoneCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    // Removed auto-dismiss - user must manually dismiss
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = DailyMotivation.getMilestoneMessage(widget.milestonePercentage);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Semi-transparent backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Celebration card
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.panel : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: widget.goal.color.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Milestone icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            widget.goal.color,
                            widget.goal.color.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.goal.color.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.milestonePercentage}%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      widget.milestonePercentage == 100
                          ? 'Goal Complete! 🎉'
                          : 'Milestone Reached! 🏆',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.white : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Goal name
                    Text(
                      widget.goal.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.goal.color,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: widget.goal.progress,
                        backgroundColor: AppColors.muted.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(widget.goal.color),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Motivational message
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.muted : AppColors.lightMuted,
                        height: 1.4,
                      ),
                    ),

                    if (widget.milestonePercentage == 100) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'XP +50 Bonus!',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Dismiss button - Material 3 styled
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.onDismiss,
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.goal.color,
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          widget.milestonePercentage == 100
                              ? '🎉 View Goal'
                              : 'Continue Saving!',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Confetti particles
          ...List.generate(20, (index) {
            final randomX = (index % 5) / 5.0;
            final randomY = (index / 5) / 5.0;
            final colors = [
              widget.goal.color,
              const Color(0xFFFFD700),
              const Color(0xFFFF6B6B),
              const Color(0xFF00D9FF),
              const Color(0xFFA8FF3E),
            ];
            return Positioned(
              left: MediaQuery.of(context).size.width * randomX,
              top: MediaQuery.of(context).size.height * randomY,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 1500 + index * 100),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value > 0.8 ? (1 - value) / 0.2 : value / 0.8,
                    child: Transform.translate(
                      offset: Offset(0, -value * 100),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  Icons.star_rounded,
                  size: 12 + (index % 3) * 6,
                  color: colors[index % colors.length],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Show the milestone celebration as an overlay.
void showMilestoneCelebration(
  BuildContext context, {
  required SavingsGoal goal,
  required int milestonePercentage,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (ctx) => MilestoneCelebration(
      goal: goal,
      milestonePercentage: milestonePercentage,
      onDismiss: () => Navigator.pop(ctx),
    ),
  );
}


