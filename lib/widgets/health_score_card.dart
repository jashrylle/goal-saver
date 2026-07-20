import 'package:flutter/material.dart';
import '../state/goal_saver_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'common_widgets.dart';

/// Animated financial health score card with breakdown details.
class FinancialHealthCard extends StatefulWidget {
  final GoalSaverController controller;

  const FinancialHealthCard({super.key, required this.controller});

  @override
  State<FinancialHealthCard> createState() => _FinancialHealthCardState();
}

class _FinancialHealthCardState extends State<FinancialHealthCard>
    with SingleTickerProviderStateMixin {
  bool _showDetails = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    final health = widget.controller.financialHealth;
    final score = health.roundedScore;
    final grade = health.grade;
    final gradeColor = health.gradeColor;
    final gradeIcon = health.gradeIcon;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.health_and_safety_rounded, color: gradeColor, size: 17),
              ),
              const SizedBox(width: 8),
              Text(
                'Financial Health',
                style: AppText.title.copyWith(color: textColor, fontSize: 14),
              ),
              const Spacer(),
              Pressable(
                onTap: () => setState(() => _showDetails = !_showDetails),
                child: Icon(
                  _showDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: mutedColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Score ring + grade
          Row(
            children: [
              // Animated score ring
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          gradeColor.withValues(alpha: 0.2),
                          gradeColor.withValues(alpha: 0.6),
                          gradeColor,
                          gradeColor.withValues(alpha: 0.6),
                          gradeColor.withValues(alpha: 0.2),
                        ],
                        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradeColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.panel : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: score / 100.0),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return Text(
                                '${(value * 100).round()}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: gradeColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(gradeIcon, color: gradeColor, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          grade,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: gradeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getScoreDescription(score),
                      style: TextStyle(fontSize: 11, color: mutedColor, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Detailed breakdown (collapsible)
          if (_showDetails) ...[
            const SizedBox(height: 14),
            Divider(color: AppColors.muted.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 12),
            _HealthBreakdownRow(
              label: 'Consistency',
              value: health.consistency,
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFFF7043),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _HealthBreakdownRow(
              label: 'Completion',
              value: health.completionRate,
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF00E676),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _HealthBreakdownRow(
              label: 'Savings Rate',
              value: health.savingsRate,
              icon: Icons.savings_rounded,
              color: const Color(0xFF00D9FF),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _HealthBreakdownRow(
              label: 'Progress',
              value: health.progressRate,
              icon: Icons.trending_up_rounded,
              color: widget.controller.accentColor,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _HealthBreakdownRow(
              label: 'Discipline',
              value: health.discipline,
              icon: Icons.military_tech_rounded,
              color: const Color(0xFF9D4EDD),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  String _getScoreDescription(int score) {
    if (score >= 90) return 'Outstanding! You\'re a savings master. Keep up the excellent work!';
    if (score >= 75) return 'Great job! Your saving habits are strong and consistent.';
    if (score >= 60) return 'Good progress! A few improvements can take you higher.';
    if (score >= 40) return 'Getting there! Try saving more consistently.';
    return 'Start building your savings habit today. Small steps lead to big results!';
  }
}

class _HealthBreakdownRow extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _HealthBreakdownRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: isDark ? AppColors.muted : AppColors.lightMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: value.clamp(0.0, 1.0),
              backgroundColor: AppColors.muted.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$pct%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
