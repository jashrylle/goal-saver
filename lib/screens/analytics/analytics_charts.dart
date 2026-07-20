import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

// ─── Line Chart: Monthly Savings Trends ───────────────────────────────────

/// Interactive line chart showing monthly savings data over time.
/// Touch a point to see exact values.
class MonthlyTrendLineChart extends StatefulWidget {
  const MonthlyTrendLineChart({super.key});

  @override
  State<MonthlyTrendLineChart> createState() => _MonthlyTrendLineChartState();
}

class _MonthlyTrendLineChartState extends State<MonthlyTrendLineChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final rawData = controller.monthlySavingsData;

    // Sanitize data: ensure all values are valid finite numbers (no NaN/Infinity)
    final data = rawData.map((d) {
      final rawAmt = (d['amount'] as num?)?.toDouble() ?? 0.0;
      return {
        ...d,
        'amount': rawAmt.isFinite && rawAmt >= 0 ? rawAmt : 0.0,
      };
    }).toList();

    if (data.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: _buildEmptyState(mutedColor),
      );
    }

    final spots = <FlSpot>[];
    double maxY = 1;
    bool hasData = false;
    for (int i = 0; i < data.length; i++) {
      final amt = (data[i]['amount'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), amt));
      if (amt > maxY) {
        maxY = amt;
        hasData = true;
      }
    }
    if (!hasData) maxY = 1;
    maxY = maxY * 1.15; // Add 15% headroom

    // Trend direction
    final recentTotal = data.length >= 3
        ? data.sublist(data.length - 3).fold<double>(0, (s, d) => s + ((d['amount'] as num?)?.toDouble() ?? 0.0))
        : 0.0;
    final priorTotal = data.length >= 6
        ? data.sublist(0, data.length - 3).fold<double>(0, (s, d) => s + ((d['amount'] as num?)?.toDouble() ?? 0.0))
        : 0.0;
    final trendUp = recentTotal >= priorTotal;

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
                    Text('Monthly Trend', style: AppText.title.copyWith(color: textColor)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          trendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 14,
                          color: trendUp ? const Color(0xFF00E676) : const Color(0xFFFF7043),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trendUp ? 'Upward trend' : 'Downward trend',
                          style: TextStyle(
                            fontSize: 11,
                            color: trendUp ? const Color(0xFF00E676) : const Color(0xFFFF7043),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_selectedIndex != null && _selectedIndex! < data.length)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: controller.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.showBalance
                          ? controller.formatMoney(((data[_selectedIndex!]['amount'] as num?)?.toDouble() ?? 0.0))
                          : '•••',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: controller.accentColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              else
                Icon(Icons.show_chart_rounded, color: controller.accentColor.withValues(alpha: 0.6), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.05)
                        : const Color(0xFF000000).withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                        final formatted = controller.showBalance
                            ? _compactMoney(value)
                            : '•••';
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            formatted,
                            style: TextStyle(fontSize: 9, color: mutedColor),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox.shrink();
                        final month = data[i]['month'] as String;
                        final label = month.length >= 3 ? month.substring(0, 3) : month;
                        final isSelected = _selectedIndex == i;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                              color: isSelected ? controller.accentColor : mutedColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final i = spot.spotIndex;
                        final label = i < data.length ? data[i]['month'] as String : '';
                        final amount = controller.showBalance ? controller.formatMoney(spot.y) : '•••';
                        return LineTooltipItem(
                          '$label\n$amount',
                          TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            background: Paint()..color = AppColors.lime,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  getTouchedSpotIndicator: (LineChartBarData chartData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(color: AppColors.lime.withValues(alpha: 0.3), strokeWidth: 1),
                        FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 5,
                          color: AppColors.lime,
                          strokeWidth: 2,
                          strokeColor: AppColors.ink,
                        )),
                      );
                    }).toList();
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: controller.accentColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final isSelected = _selectedIndex == index;
                        return FlDotCirclePainter(
                          radius: isSelected ? 5 : 3,
                          color: isSelected ? controller.accentColor : controller.accentColor.withValues(alpha: 0.3),
                          strokeWidth: isSelected ? 2 : 0,
                          strokeColor: isSelected ? AppColors.ink : Colors.transparent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          controller.accentColor.withValues(alpha: 0.25),
                          controller.accentColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  String _compactMoney(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  Widget _buildEmptyState(Color mutedColor) {
    return Column(
      children: [
        Icon(Icons.show_chart_rounded, size: 36, color: mutedColor.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text('Add savings data to see monthly trends', style: TextStyle(fontSize: 12, color: mutedColor)),
      ],
    );
  }
}

// ─── Bar Chart: Weekly Contributions ───────────────────────────────────────

/// Interactive grouped bar chart showing daily savings for the current week.
class WeeklyContributionBarChart extends StatefulWidget {
  const WeeklyContributionBarChart({super.key});

  @override
  State<WeeklyContributionBarChart> createState() => _WeeklyContributionBarChartState();
}

class _WeeklyContributionBarChartState extends State<WeeklyContributionBarChart> {
  int? _selectedBar;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final rawData = controller.weeklyContributions;

    // Sanitize data: ensure all values are valid finite numbers (no NaN/Infinity)
    final data = rawData.map((d) {
      final rawV = (d['value'] as num?)?.toDouble() ?? 0.0;
      return {
        ...d,
        'value': rawV.isFinite && rawV >= 0 ? rawV : 0.0,
      };
    }).toList();

    if (data.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: _buildEmptyState(mutedColor),
      );
    }

    double total = 0;
    double maxY = 1;
    bool hasData = false;
    for (final d in data) {
      final v = (d['value'] as num).toDouble();
      total += v;
      if (v > maxY) {
        maxY = v;
        hasData = true;
      }
    }
    if (!hasData) maxY = 1;
    maxY = maxY * 1.2;

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
                    Text('This Week', style: AppText.title.copyWith(color: textColor)),
                    const SizedBox(height: 2),
                    Text(
                      controller.showBalance
                        ? 'Total: ${controller.formatMoney(total)}'
                        : 'Total: ${controller.currencySymbol} •••',
                      style: TextStyle(fontSize: 11, color: controller.accentColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (_selectedBar != null && _selectedBar! < data.length)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: controller.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data[_selectedBar!]['label'] as String,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: controller.accentColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              else
                Icon(Icons.bar_chart_rounded, color: controller.accentColor.withValues(alpha: 0.6), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.05)
                        : const Color(0xFF000000).withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _compactMoney(value),
                            style: TextStyle(fontSize: 9, color: mutedColor),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox.shrink();
                        final label = data[i]['label'] as String;
                        final isToday = _isToday(label);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label.substring(0, 1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.normal,
                              color: isToday ? controller.accentColor : mutedColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayLabel = groupIndex < data.length ? data[groupIndex]['label'] as String : '';
                      final amount = controller.showBalance ? controller.formatMoney(rod.toY) : '•••';
                      return BarTooltipItem(
                        '$dayLabel\n$amount',
                        TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          background: Paint()..color = AppColors.lime,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (response != null && response.spot != null) {
                      setState(() => _selectedBar = response.spot!.touchedBarGroupIndex);
                    } else {
                      setState(() => _selectedBar = null);
                    }
                  },
                ),
                barGroups: List.generate(data.length, (i) {
                  final value = (data[i]['value'] as num).toDouble();
                  final isToday = _isToday(data[i]['label'] as String);
                  final isSelected = _selectedBar == i;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: value.clamp(0.01, double.infinity),
                        color: isToday
                            ? controller.accentColor
                            : isSelected
                                ? controller.accentColor.withValues(alpha: 0.8)
                                : controller.accentColor.withValues(alpha: 0.35),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(String label) {
    final today = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return label == days[(today.weekday - 1) % 7];
  }

  String _compactMoney(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  Widget _buildEmptyState(Color mutedColor) {
    return Column(
      children: [
        Icon(Icons.bar_chart_rounded, size: 36, color: mutedColor.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text('No weekly data yet', style: TextStyle(fontSize: 12, color: mutedColor)),
      ],
    );
  }
}

// ─── Pie Chart: Goal Allocation ────────────────────────────────────────────

/// Interactive pie chart showing how savings are distributed across goals.
/// Tap a section to see its details.
class GoalAllocationPieChart extends StatefulWidget {
  const GoalAllocationPieChart({super.key});

  @override
  State<GoalAllocationPieChart> createState() => _GoalAllocationPieChartState();
}

class _GoalAllocationPieChartState extends State<GoalAllocationPieChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final goals = controller.allActiveGoals.where((g) => g.target > 0).toList();

    if (goals.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.pie_chart_rounded, size: 36, color: mutedColor.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text('No goals to display', style: TextStyle(fontSize: 12, color: mutedColor)),
          ],
        ),
      );
    }

    final totalTarget = goals.fold<double>(0, (s, g) => s + g.target);

    if (totalTarget <= 0) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.pie_chart_rounded, size: 36, color: mutedColor.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text('No goal targets set', style: TextStyle(fontSize: 12, color: mutedColor)),
          ],
        ),
      );
    }
    final selectedGoal = _selectedIndex != null && _selectedIndex! < goals.length
        ? goals[_selectedIndex!]
        : null;

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
                    Text('Allocation', style: AppText.title.copyWith(color: textColor)),
                    const SizedBox(height: 2),
                    if (selectedGoal != null)
                      Text(
                        '${selectedGoal.title}: ${totalTarget > 0 ? (selectedGoal.target / totalTarget * 100).round() : 0}%',
                        style: TextStyle(fontSize: 11, color: selectedGoal.color, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      )
                      else
                      Text(
                        'Tap a slice for details',
                        style: TextStyle(fontSize: 11, color: mutedColor),
                      ),
                  ],
                ),
              ),
              Icon(Icons.pie_chart_rounded, color: controller.accentColor.withValues(alpha: 0.6), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (response != null && response.touchedSection != null) {
                            setState(() => _selectedIndex = response.touchedSection!.touchedSectionIndex);
                          } else {
                            setState(() => _selectedIndex = null);
                          }
                        },
                        enabled: true,
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(goals.length, (i) {
                        final goal = goals[i];
                        final share = totalTarget > 0 ? (goal.target / totalTarget).clamp(0.0, 1.0) : 0.0;
                        final isSelected = _selectedIndex == i;
                        return PieChartSectionData(
                          color: goal.color,
                          value: share > 0 ? share : 1.0,
                          title: isSelected ? '${(share * 100).round()}%' : '',
                          radius: isSelected ? 55 : 45,
                          titleStyle: TextStyle(
                            fontSize: isSelected ? 14 : 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),

                        );
                      }),
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  ),
                ),
                const SizedBox(width: 12),
                // Legend
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: goals.take(6).map((goal) {
                        final share = totalTarget > 0 ? goal.target / totalTarget * 100 : 0.0;
                        final isSelected = goals.indexOf(goal) == _selectedIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedIndex = goals.indexOf(goal)),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: goal.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    goal.title,
                                    style: TextStyle(
                                      fontSize: isSelected ? 11 : 10,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                      color: isSelected ? goal.color : mutedColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${share.round()}%',
                                  style: TextStyle(
                                    fontSize: isSelected ? 11 : 9,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    color: isSelected ? goal.color : mutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Total summary
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.05)
                  : const Color(0xFF000000).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 14, color: AppColors.lime),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Total target: ${controller.showBalance ? controller.formatMoney(totalTarget) : '•••'}',
                    style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
