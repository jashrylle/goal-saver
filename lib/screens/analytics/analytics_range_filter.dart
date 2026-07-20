import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/goal_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';

/// Range filter for the analytics dashboard.
/// Supports: daily, weekly, monthly, yearly, and custom date range.
class AnalyticsRangeFilter extends StatefulWidget {
  const AnalyticsRangeFilter({super.key});

  @override
  State<AnalyticsRangeFilter> createState() => _AnalyticsRangeFilterState();
}

class _AnalyticsRangeFilterState extends State<AnalyticsRangeFilter> {
  DateTime? _customStart;
  DateTime? _customEnd;

  void _showCustomRangePicker(BuildContext context, GoalSaverController controller) {
    showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: controller.accentColor,
              brightness: controller.isDarkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    ).then((range) {
      if (range != null) {
        setState(() {
          _customStart = range.start;
          _customEnd = range.end;
        });
        controller.setRange(AnalyticsRange.values.first); // Reset to daily to trigger rebuild
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          ...AnalyticsRange.values.map((range) {
            final isSelected = controller.range == range && _customStart == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  range.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.ink : (isDark ? AppColors.white : AppColors.lightText),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _customStart = null;
                    _customEnd = null;
                  });
                  controller.setRange(range);
                },
                selectedColor: controller.accentColor,
                checkmarkColor: AppColors.ink,
                backgroundColor: isDark
                    ? const Color(0xFFFFFFFF).withValues(alpha: 0.06)
                    : const Color(0xFF000000).withValues(alpha: 0.04),
                side: BorderSide(
                  color: isSelected
                      ? controller.accentColor
                      : (isDark
                          ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                          : const Color(0xFF000000).withValues(alpha: 0.1)),
                  width: isSelected ? 1.5 : 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            );
          }),
          // Custom range button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(
                Icons.date_range_rounded,
                size: 14,
                color: _customStart != null ? AppColors.ink : (isDark ? AppColors.white : AppColors.lightText),
              ),
              label: Text(
                _customStart != null
                    ? '${DateFormat.Md().format(_customStart!)} - ${DateFormat.Md().format(_customEnd!)}'
                    : 'Custom',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: _customStart != null ? FontWeight.w700 : FontWeight.w500,
                  color: _customStart != null ? AppColors.ink : (isDark ? AppColors.white : AppColors.lightText),
                ),
              ),
              onPressed: () => _showCustomRangePicker(context, controller),
              backgroundColor: _customStart != null
                  ? controller.accentColor
                  : (isDark
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.06)
                      : const Color(0xFF000000).withValues(alpha: 0.04)),
              side: BorderSide(
                color: _customStart != null
                    ? controller.accentColor
                    : (isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                        : const Color(0xFF000000).withValues(alpha: 0.1)),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}
