import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// A gauge-style progress indicator showing financial health score.
/// Uses a semi-circular arc with animated fill based on the score.
class FinancialHealthGauge extends StatelessWidget {
  const FinancialHealthGauge({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final health = controller.financialHealth;
    final overallScore = ((health.consistency + health.completionRate + health.savingsRate + health.progressRate + health.discipline) / 5 * 100).round();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Financial Health', style: AppText.title.copyWith(color: textColor)),
                    const SizedBox(height: 2),
                    Text('Overall score', style: TextStyle(fontSize: 11, color: mutedColor)),
                  ],
                ),
              ),
              Icon(Icons.favorite_rounded, color: _scoreColor(overallScore), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          // Gauge
          Center(
            child: SizedBox(
              width: 180,
              height: 100,
              child: CustomPaint(
                painter: _GaugePainter(
                  score: overallScore / 100.0,
                  accentColor: controller.accentColor,
                  isDark: isDark,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$overallScore',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: _scoreColor(overallScore),
                          height: 1,
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Sub-metrics
          _metricRow('Consistency', health.consistency, controller.accentColor),
          const SizedBox(height: 4),
          _metricRow('Completion Rate', health.completionRate, const Color(0xFF5FDE9E)),
          const SizedBox(height: 4),
          _metricRow('Savings Rate', health.savingsRate, const Color(0xFF00D9FF)),
          const SizedBox(height: 4),
          _metricRow('Progress Rate', health.progressRate, const Color(0xFFFFB703)),
          const SizedBox(height: 4),
          _metricRow('Discipline', health.discipline, const Color(0xFFFF6B9D)),
        ],
      ),
    );
  }

  Widget _metricRow(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).round()}%',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF5FDE9E);
    if (score >= 60) return const Color(0xFFFFD93D);
    if (score >= 40) return const Color(0xFFFF8A65);
    return const Color(0xFFFF6B6B);
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color accentColor;
  final bool isDark;

  _GaugePainter({required this.score, required this.accentColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 16;
    final strokeWidth = 16.0;

    // Background arc
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFFFFFFFF).withValues(alpha: 0.06) : const Color(0xFF000000).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Score arc
    final scorePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFF6B6B),
          const Color(0xFFFFD93D),
          const Color(0xFF5FDE9E),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * score.clamp(0.0, 1.0),
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.score != score;
}
