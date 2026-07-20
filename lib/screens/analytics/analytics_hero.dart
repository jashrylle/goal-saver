import 'package:flutter/material.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Hero summary card for the analytics tab — shows total saved vs target with
/// an animated ring chart and smart insight labels.
class AnalyticsHero extends StatefulWidget {
  const AnalyticsHero({super.key, required this.controller});

  final GoalSaverController controller;

  @override
  State<AnalyticsHero> createState() => _AnalyticsHeroState();
}

class _AnalyticsHeroState extends State<AnalyticsHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );
    _ringController.forward();
  }

  @override
  void didUpdateWidget(AnalyticsHero old) {
    super.didUpdateWidget(old);
    if (old.controller.savedInSelectedRange !=
        widget.controller.savedInSelectedRange) {
      _ringController.reset();
      _ringController.forward();
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  void _showInsightDetails(BuildContext context) {
    final ctrl = widget.controller;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSaved = ctrl.savedInSelectedRange;
    final totalTarget = ctrl.targetInSelectedRange;
    final progress =
        totalTarget == 0 ? 0.0 : (totalSaved / totalTarget).clamp(0.0, 1.0);
    final pct = (progress * 100).round();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.panel : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.lightbulb_rounded,
                color: Color(0xFFFFD93D), size: 22),
            const SizedBox(width: 10),
            const Text('Savings Insight',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ctrl.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('$pct% Complete',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: ctrl.accentColor)),
                  const SizedBox(height: 4),
                  Text(
                    '${ctrl.range.label} Overview',
                    style: TextStyle(
                        fontSize: 13,
                        color: ctrl.accentColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _insightRow(Icons.savings_rounded, 'Saved',
                ctrl.formatMoney(totalSaved), ctrl.accentColor),
            const SizedBox(height: 8),
            _insightRow(Icons.flag_rounded, 'Target',
                ctrl.formatMoney(totalTarget), AppColors.lime),
            const SizedBox(height: 8),
            _insightRow(Icons.trending_up_rounded, 'Remaining',
                ctrl.formatMoney((totalTarget - totalSaved).clamp(0, totalTarget)),
                const Color(0xFFFF7043)),
            const SizedBox(height: 16),
            Text(
              pct >= 100
                  ? '🎉 Goal reached! You\'ve exceeded your target.'
                  : pct >= 80
                      ? '🔥 Almost there! Just ${(100 - pct)}% to go — push through!'
                      : pct >= 50
                          ? '💪 More than halfway! Keep the momentum going.'
                          : '🎯 You\'ve started strong. Small deposits add up fast!',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.muted : AppColors.lightMuted,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Close', style: TextStyle(color: AppColors.lime)),
          ),
        ],
      ),
    );
  }

  Widget _insightRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
            child:
                Text(label, style: const TextStyle(fontSize: 13))),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    final totalSaved = ctrl.goals.isNotEmpty ? ctrl.savedInSelectedRange : 0.0;
    final totalTarget = ctrl.goals.isNotEmpty ? ctrl.targetInSelectedRange : 0.0;
    final progress =
        totalTarget == 0 ? 0.0 : (totalSaved / totalTarget).clamp(0.0, 1.0);
    final pct = (progress * 100).round();

    final statusColor = pct >= 100
        ? const Color(0xFF00E676)
        : pct >= 60
            ? ctrl.accentColor
            : const Color(0xFFFF7043);
    final statusLabel = pct >= 100
        ? 'Goal Reached!'
        : pct >= 80
            ? 'Almost There'
            : pct >= 60
                ? 'On Track'
                : pct >= 30
                    ? 'Getting Started'
                    : 'Needs Attention';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ctrl.range.label} Overview',
                      style: AppText.caption.copyWith(color: mutedColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ctrl.showBalance
                          ? ctrl.formatMoney(totalSaved)
                          : '${ctrl.currencySymbol} •••',
                      style: AppText.hero.copyWith(
                        fontSize: 32,
                        color: ctrl.accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ctrl.showBalance
                          ? 'of ${ctrl.formatMoney(totalTarget)} target'
                          : 'of ••• target',
                      style: AppText.caption.copyWith(color: mutedColor),
                    ),
                  ],
                ),
              ),
              // Animated ring chart
              SizedBox(
                width: 80,
                height: 80,
                child: AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (context, child) {
                    final animatedProgress =
                        (progress * _ringAnimation.value).clamp(0.0, 1.0);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 8,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.muted.withValues(alpha: 0.15),
                          ),
                        ),
                        CircularProgressIndicator(
                          value: animatedProgress,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$pct%',
                              style: AppText.body.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status row — tappable for detailed insight
          Pressable(
            onTap: () => _showInsightDetails(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pct >= 100
                        ? Icons.emoji_events_rounded
                        : pct >= 60
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusLabel,
                    style: AppText.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: statusColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
