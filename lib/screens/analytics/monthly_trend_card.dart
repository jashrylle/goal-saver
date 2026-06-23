import 'package:flutter/material.dart';
import '../../models/goal_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Card showing a simple line-chart of monthly savings trend.
class MonthlyTrendCard extends StatelessWidget {
  const MonthlyTrendCard({super.key, required this.range});

  final AnalyticsRange range;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Trend', style: AppText.title),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _TrendPainter(),
              size: const Size(double.infinity, 140),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[
      Offset(size.width * 0.1, size.height * 0.7),
      Offset(size.width * 0.3, size.height * 0.55),
      Offset(size.width * 0.5, size.height * 0.6),
      Offset(size.width * 0.7, size.height * 0.35),
      Offset(size.width * 0.9, size.height * 0.25),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
