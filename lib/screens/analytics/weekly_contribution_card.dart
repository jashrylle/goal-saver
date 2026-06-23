import 'package:flutter/material.dart';
import '../../models/goal_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Card showing per-day savings bars for the current week.
class WeeklyContributionCard extends StatelessWidget {
  const WeeklyContributionCard({super.key, required this.range});

  final AnalyticsRange range;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Contributions', style: AppText.title),
          const SizedBox(height: 12),
          SizedBox(
            height: 196,
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _ContributionRow(label: 'Mon', value: '₱420'),
                _ContributionRow(label: 'Tue', value: '₱180'),
                _ContributionRow(label: 'Wed', value: '₱650'),
                _ContributionRow(label: 'Thu', value: '₱120'),
                _ContributionRow(label: 'Fri', value: '₱500'),
                _ContributionRow(label: 'Sat', value: '₱90'),
                _ContributionRow(label: 'Sun', value: '₱0'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final parsed = double.tryParse(value.replaceAll('₱', '')) ?? 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text(label, style: AppText.caption)),
          Expanded(
            child: LinearProgressIndicator(
              minHeight: 6,
              value: parsed / 700.0,
              backgroundColor: AppColors.muted.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation(AppColors.lime),
            ),
          ),
          const SizedBox(width: 10),
          Text(value, style: AppText.caption),
        ],
      ),
    );
  }
}
