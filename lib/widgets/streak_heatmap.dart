import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// GitHub-style contribution heatmap for tracking daily savings streaks.
///
/// Displays a grid of colored squares representing each day's savings activity
/// over a configurable time period (default 52 weeks / 364 days).
class StreakHeatmap extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final int weeksToShow;

  const StreakHeatmap({
    super.key,
    required this.data,
    this.weeksToShow = 26, // Show 26 weeks (half a year) by default
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cellSize = 12.0;
    final cellSpacing = 3.0;
    final totalWeeks = weeksToShow;
    final totalData = data.length >= totalWeeks * 7
        ? data.sublist(data.length - totalWeeks * 7)
        : data;

    // Group data by weeks
    final List<List<Map<String, dynamic>>> weeks = [];
    for (int w = 0; w < totalWeeks; w++) {
      final startIndex = w * 7;
      final weekData = <Map<String, dynamic>>[];
      for (int d = 0; d < 7; d++) {
        final index = startIndex + d;
        if (index < totalData.length) {
          weekData.add(totalData[index]);
        } else {
          weekData.add({'active': false, 'count': 0, 'amount': 0.0});
        }
      }
      weeks.add(weekData);
    }

    // Day labels
    const dayLabels = ['Mon', '', 'Wed', '', 'Fri', '', ''];

    return SizedBox(
      height: 7 * (cellSize + cellSpacing) + 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day labels column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (index) {
              if (dayLabels[index].isEmpty) {
                return SizedBox(height: cellSize + cellSpacing);
              }
              return SizedBox(
                height: cellSize + cellSpacing,
                child: Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Text(
                    dayLabels[index],
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark ? AppColors.muted : AppColors.lightMuted,
                      height: 1,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 6),
          // Heatmap grid
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weeks.length,
              itemBuilder: (context, weekIndex) {
                final week = weeks[weekIndex];
                return Padding(
                  padding: EdgeInsets.only(right: cellSpacing),
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      final dayData = week[dayIndex];
                      final active = dayData['active'] as bool? ?? false;
                      final amount = dayData['amount'] as double? ?? 0.0;
                      final date = dayData['date'] as DateTime?;

                      // Determine color intensity based on amount
                      Color cellColor;
                      if (!active) {
                        cellColor = isDark
                            ? const Color(0xFF1A2A24)
                            : const Color(0xFFEDF0ED);
                      } else if (amount >= 1000) {
                        cellColor = const Color(0xFF1B5E20);
                      } else if (amount >= 500) {
                        cellColor = const Color(0xFF2E7D32);
                      } else if (amount >= 100) {
                        cellColor = const Color(0xFF43A047);
                      } else {
                        cellColor = const Color(0xFF66BB6A);
                      }

                      return Padding(
                        padding: EdgeInsets.only(bottom: cellSpacing),
                        child: Tooltip(
                          message: date != null
                              ? '${date.month}/${date.day}: ${amount.toStringAsFixed(0)} saved'
                              : 'No data',
                          preferBelow: false,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF07100E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.muted.withValues(alpha: 0.2)
                                  : AppColors.lightMuted.withValues(alpha: 0.2),
                            ),
                          ),
                          textStyle: TextStyle(
                            color: isDark ? AppColors.white : AppColors.lightText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact streak statistics widget showing current and longest streak.
class StreakStats extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final int totalSavingsDays;
  final int totalLogs;

  const StreakStats({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalSavingsDays,
    required this.totalLogs,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    return Row(
      children: [
        _StatItem(
          icon: Icons.local_fire_department_rounded,
          value: '$currentStreak',
          label: 'Current Streak',
          color: currentStreak >= 7
              ? const Color(0xFFFF7043)
              : mutedColor,
          textColor: textColor,
        ),
        _StatItem(
          icon: Icons.trending_up_rounded,
          value: '$longestStreak',
          label: 'Longest Streak',
          color: const Color(0xFF5FDE9E),
          textColor: textColor,
        ),
        _StatItem(
          icon: Icons.calendar_view_day_rounded,
          value: '$totalSavingsDays',
          label: 'Active Days',
          color: mutedColor,
          textColor: textColor,
        ),
        _StatItem(
          icon: Icons.history_rounded,
          value: '$totalLogs',
          label: 'Total Logs',
          color: mutedColor,
          textColor: textColor,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color textColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
