import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Interactive pie/donut chart showing savings allocation by category.
/// Tap a section to see detailed breakdown.
class CategoryPieChartCard extends StatefulWidget {
  const CategoryPieChartCard({super.key});

  @override
  State<CategoryPieChartCard> createState() => _CategoryPieChartCardState();
}

class _CategoryPieChartCardState extends State<CategoryPieChartCard> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final goals = controller.allActiveGoals;

    // Aggregate savings by category
    final Map<String, ({double saved, double target, Color color})> categoryData = {};
    for (final goal in goals) {
      final catName = goal.category.label;
      final existing = categoryData[catName];
      categoryData[catName] = (
        saved: (existing?.saved ?? 0) + goal.saved,
        target: (existing?.target ?? 0) + goal.target,
        color: goal.color,
      );
    }

    if (categoryData.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: _buildEmpty(mutedColor),
      );
    }

    final entries = categoryData.entries.toList();
    final totalSaved = entries.fold<double>(0, (s, e) => s + e.value.saved);
    final pieSections = <PieChartSectionData>[];
    final legendItems = <Widget>[];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final pct = totalSaved > 0 ? entry.value.saved / totalSaved : 0.0;
      final isTouched = _touchedIndex == i;

      pieSections.add(PieChartSectionData(
        color: entry.value.color,
        value: entry.value.saved,
        title: isTouched ? '${(pct * 100).toStringAsFixed(1)}%' : '',
        radius: isTouched ? 65 : 55,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        badgeWidget: isTouched
            ? Icon(Icons.circle, size: 8, color: AppColors.ink.withValues(alpha: 0.7))
            : null,
        badgePositionPercentageOffset: 0.6,
      ));

      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: entry.value.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: mutedColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                controller.showBalance
                    ? controller.formatMoney(entry.value.saved)
                    : '•••',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                    Text('Category Breakdown', style: AppText.title.copyWith(color: textColor)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          controller.showBalance
                              ? 'Total saved: ${controller.formatMoney(totalSaved)}'
                              : 'Total saved: ${controller.currencySymbol} •••',
                          style: TextStyle(fontSize: 12, color: controller.accentColor, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${entries.length} categories',
                          style: TextStyle(fontSize: 11, color: mutedColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: controller.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.pie_chart_rounded, color: controller.accentColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Pie chart with scrollable legend below ────────────────
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Pie chart takes ~45% width
                SizedBox(
                  width: 150,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            setState(() => _touchedIndex = null);
                            return;
                          }
                          setState(() {
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40, // Donut effect
                      sections: pieSections,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  ),
                ),
                const SizedBox(width: 16),
                // Legend takes remaining space — more padding, bigger text
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: legendItems,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color mutedColor) {
    return Column(
      children: [
        Icon(Icons.pie_chart_rounded, size: 36, color: mutedColor.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text('No category data yet', style: TextStyle(fontSize: 12, color: mutedColor)),
      ],
    );
  }
}

/// Stacked bar chart showing monthly savings grouped by category.
class StackedCategoryBarChart extends StatefulWidget {
  const StackedCategoryBarChart({super.key});

  @override
  State<StackedCategoryBarChart> createState() => _StackedCategoryBarChartState();
}

class _StackedCategoryBarChartState extends State<StackedCategoryBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final history = controller.history;

    // Group by month then category
    final now = DateTime.now();
    final Map<String, Map<String, double>> monthlyCategoryData = {};
    final List<String> monthLabels = [];
    
    for (int i = 5; i >= 0; i--) {
      int m = now.month - i;
      int y = now.year;
      while (m < 1) { m += 12; y -= 1; }
      final key = '$y-${m.toString().padLeft(2, '0')}';
      final label = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
      monthLabels.add(label);
      monthlyCategoryData[key] = {};
    }

    // Collect unique categories
    final Set<String> categories = {};
    for (final goal in controller.allActiveGoals) {
      categories.add(goal.category.label);
    }
    final catList = categories.toList();

    // Fill data
    for (final log in history) {
      final key = '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}';
      if (monthlyCategoryData.containsKey(key)) {
        // Find category for this goal
        String cat = 'Other';
        for (final goal in controller.allActiveGoals) {
          if (goal.id == log.goalId) {
            cat = goal.category.label;
            break;
          }
        }
        monthlyCategoryData[key]![cat] = 
          (monthlyCategoryData[key]![cat] ?? 0) + log.amount;
      }
    }

    if (catList.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: _buildEmptyChart(mutedColor),
      );
    }

    final monthKeys = monthlyCategoryData.keys.toList();
    final barGroups = <BarChartGroupData>[];
    double maxY = 0;

    for (int i = 0; i < monthKeys.length; i++) {
      final data = monthlyCategoryData[monthKeys[i]]!;
      double total = 0;
      final rodStacks = <BarChartRodStackItem>[];
      
      for (final cat in catList) {
        final val = data[cat] ?? 0;
        if (val > 0) {
          rodStacks.add(BarChartRodStackItem(total, total + val, _getCategoryColor(cat)));
          total += val;
        }
      }
      if (total > maxY) maxY = total;

      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: total,
            color: Colors.transparent,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            rodStackItems: rodStacks,
          ),
        ],
      ));
    }

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
                    Text('Monthly Breakdown', style: AppText.title.copyWith(color: textColor)),
                    const SizedBox(height: 2),
                    Text('Savings by category per month', style: TextStyle(fontSize: 11, color: mutedColor)),
                  ],
                ),
              ),
              Icon(Icons.bar_chart_rounded, color: controller.accentColor.withValues(alpha: 0.6), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          // Legend
          SizedBox(
            height: 20,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: catList.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(
                      color: _getCategoryColor(cat), borderRadius: BorderRadius.circular(2),
                    )),
                    const SizedBox(width: 4),
                    Text(cat, style: TextStyle(fontSize: 9, color: mutedColor)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.15,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.05)
                        : const Color(0xFF000000).withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i < 0 || i >= monthLabels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            monthLabels[i],
                            style: TextStyle(fontSize: 9, fontWeight: _selectedIndex == i ? FontWeight.w800 : FontWeight.normal, color: mutedColor),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    if (response == null || response.spot == null) {
                      setState(() => _selectedIndex = null);
                    } else {
                      setState(() => _selectedIndex = response.spot!.touchedBarGroup.x);
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final key = monthKeys[group.x];
                      final data = monthlyCategoryData[key]!;
                      double total = 0;
                      for (final v in data.values) {
                        total += v;
                      }
                      return BarTooltipItem(
                        '${monthLabels[group.x]}\nTotal: ${controller.formatMoney(total)}',
                        TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 11),
                      );
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String label) {
    final idx = label.hashCode % 8;
    const colors = [
      Color(0xFF5FDE9E), Color(0xFFFF6B9D), Color(0xFF00D9FF),
      Color(0xFFFFD93D), Color(0xFF9D4EDD), Color(0xFF52B788),
      Color(0xFFFF8A65), Color(0xFF3ECCC1),
    ];
    return colors[idx.abs()];
  }

  Widget _buildEmptyChart(Color mutedColor) {
    return Column(children: [
      Icon(Icons.bar_chart_rounded, size: 36, color: mutedColor.withValues(alpha: 0.5)),
      const SizedBox(height: 8),
      Text('No monthly data yet', style: TextStyle(fontSize: 12, color: mutedColor)),
    ]);
  }
}
