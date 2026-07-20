import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// GitHub-style contribution heatmap showing daily savings activity.
/// Each cell represents a day, with color intensity based on amount saved.
class SavingsHeatmap extends StatefulWidget {
  const SavingsHeatmap({super.key});

  @override
  State<SavingsHeatmap> createState() => _SavingsHeatmapState();
}

class _SavingsHeatmapState extends State<SavingsHeatmap> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final data = controller.streakHeatmapData;
    streakHeatmapDataCache = data;

    if (data.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: _buildEmpty(mutedColor),
      );
    }

    // Find max amount for color scaling — with NaN/Infinity guards
    final maxAmount = data.fold<double>(0, (max, d) {
      final raw = (d['amount'] as num?)?.toDouble() ?? 0.0;
      final amt = raw.isFinite && raw >= 0 ? raw : 0.0;
      return amt > max ? amt : max;
    });
    final now = DateTime.now();

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
                    Text('Savings Heatmap', style: AppText.title.copyWith(color: textColor)),
                    const SizedBox(height: 2),                      Text(
                      '${controller.streakDays}-day streak · ${data.where((d) => (d['active'] as bool?) == true).length} active days',
                      style: TextStyle(fontSize: 11, color: controller.accentColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.grid_on_rounded, color: controller.accentColor.withValues(alpha: 0.6), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          // Selected date info
          if (_selectedDate != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: controller.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: controller.accentColor),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedDate!.month}/${_selectedDate!.day} — ${controller.showBalance ? controller.formatMoney(_selectedAmount) : "•••"}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: controller.accentColor),
                  ),
                ],
              ),
            ),
          // Heatmap grid
          SizedBox(
            height: 112,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: (data.length / 7).ceil() * 15.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize = 13.0;
                    final cellGap = 2.0;

                    return Wrap(
                      direction: Axis.vertical,
                      spacing: cellGap,
                      runSpacing: cellGap,
                      children: List.generate(data.length, (i) {
                        final entry = data[i];
                        final active = (entry['active'] as bool?) ?? false;
                        final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
                        final date = (entry['date'] as DateTime?) ?? now;
                        final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
                        final isSelected = _selectedDate != null &&
                            date.day == _selectedDate!.day &&
                            date.month == _selectedDate!.month &&
                            date.year == _selectedDate!.year;
                        final color = _getHeatColor(amount, maxAmount, isDark, active);

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedDate = isSelected ? null : date);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: cellSize,
                            height: cellSize,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                              border: isToday || isSelected
                                  ? Border.all(color: controller.accentColor, width: isSelected ? 2 : 1)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: TextStyle(fontSize: 9, color: mutedColor)),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                final level = i / 4;
                return Container(
                  width: 10, height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _getHeatColor(level * maxAmount, maxAmount, isDark, true),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text('More', style: TextStyle(fontSize: 9, color: mutedColor)),
            ],
          ),
        ],
      ),
    );
  }    double get _selectedAmount {
    if (_selectedDate == null) return 0;
    for (final entry in streakHeatmapDataCache) {
      final date = (entry['date'] as DateTime?) ?? DateTime(2000);
      if (date.day == _selectedDate!.day &&
          date.month == _selectedDate!.month &&
          date.year == _selectedDate!.year) {
        return (entry['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    return 0;
  }

  /// Cache of heatmap data for use in the getter (updated each build).
  List<Map<String, dynamic>> streakHeatmapDataCache = [];

  Color _getHeatColor(double amount, double maxAmount, bool isDark, bool active) {
    if (!active) {
      return isDark ? const Color(0xFFFFFFFF).withValues(alpha: 0.05) : const Color(0xFF000000).withValues(alpha: 0.04);
    }
    if (maxAmount <= 0) return const Color(0xFF5FDE9E).withValues(alpha: 0.3);
    final ratio = (amount / maxAmount).clamp(0.0, 1.0);
    if (ratio < 0.2) return const Color(0xFF5FDE9E).withValues(alpha: 0.15);
    if (ratio < 0.4) return const Color(0xFF5FDE9E).withValues(alpha: 0.3);
    if (ratio < 0.6) return const Color(0xFF5FDE9E).withValues(alpha: 0.5);
    if (ratio < 0.8) return const Color(0xFF5FDE9E).withValues(alpha: 0.7);
    return const Color(0xFF5FDE9E);
  }

  Widget _buildEmpty(Color mutedColor) {
    return Column(children: [
      Icon(Icons.grid_on_rounded, size: 36, color: mutedColor.withValues(alpha: 0.5)),
      const SizedBox(height: 8),
      Text('No heatmap data yet', style: TextStyle(fontSize: 12, color: mutedColor)),
    ]);
  }
}
