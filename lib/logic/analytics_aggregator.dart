import '../models/goal_model.dart';

/// Shared analytics aggregation functions.
///
/// All charts read from the same aggregation pipeline so numbers are always
/// consistent with goal cards and the dashboard.
class AnalyticsAggregator {
  /// Bucket [logs] into time units of the given [granularity].
  ///
  /// Returns a list of maps with 'label' and 'amount' keys, sorted chronologically.
  static List<Map<String, dynamic>> aggregate(
    List<SavingsLog> logs, {
    required AnalyticsRange granularity,
    int maxBuckets = 12,
  }) {
    return switch (granularity) {
      AnalyticsRange.daily => _aggregateDaily(logs, maxBuckets),
      AnalyticsRange.weekly => _aggregateWeekly(logs, maxBuckets),
      AnalyticsRange.monthly => _aggregateMonthly(logs, maxBuckets),
      AnalyticsRange.yearly => _aggregateYearly(logs, maxBuckets),
    };
  }

  /// Daily aggregation — last [maxBuckets] days.
  static List<Map<String, dynamic>> _aggregateDaily(
    List<SavingsLog> logs,
    int maxBuckets,
  ) {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var i = maxBuckets - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final total = logs
          .where((log) =>
              log.date.day == day.day &&
              log.date.month == day.month &&
              log.date.year == day.year)
          .fold<double>(0.0, (sum, log) => sum + log.amount);

      final weekday = const [
        'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
      ][day.weekday % 7];
      final label = i == 0
          ? 'Today'
          : i == 1
              ? 'Yesterday'
               : '$weekday ${day.day}';

      result.add({'label': label, 'amount': total, 'date': day});
    }
    return result;
  }

  /// Weekly aggregation — last [maxBuckets] weeks.
  static List<Map<String, dynamic>> _aggregateWeekly(
    List<SavingsLog> logs,
    int maxBuckets,
  ) {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final startOfWeek =
        DateTime(now.year, now.month, now.day - currentWeekday + 1);

    for (var i = maxBuckets - 1; i >= 0; i--) {
      final weekStart = startOfWeek.subtract(Duration(days: 7 * i));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final total = logs
          .where((log) =>
              !log.date.isBefore(weekStart) && !log.date.isAfter(weekEnd))
          .fold<double>(0.0, (sum, log) => sum + log.amount);

      result.add({
        'label': 'Week ${weekStart.day}/${weekStart.month}',
        'amount': total,
        'startDate': weekStart,
        'endDate': weekEnd,
      });
    }
    return result;
  }

  /// Monthly aggregation — last [maxBuckets] months.
  static List<Map<String, dynamic>> _aggregateMonthly(
    List<SavingsLog> logs,
    int maxBuckets,
  ) {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    for (var i = maxBuckets - 1; i >= 0; i--) {
      int targetMonth = now.month - i;
      int targetYear = now.year;
      while (targetMonth < 1) {
        targetMonth += 12;
        targetYear -= 1;
      }
      final targetDate = DateTime(targetYear, targetMonth, 1);

      final total = logs
          .where((log) =>
              log.date.month == targetDate.month &&
              log.date.year == targetDate.year)
          .fold<double>(0.0, (sum, log) => sum + log.amount);

      result.add({
        'month': '${monthNames[targetDate.month - 1]} ${targetDate.year}',
        'amount': total,
        'year': targetYear,
        'monthNum': targetDate.month,
      });
    }
    return result;
  }

  /// Yearly aggregation — last [maxBuckets] years.
  static List<Map<String, dynamic>> _aggregateYearly(
    List<SavingsLog> logs,
    int maxBuckets,
  ) {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (var i = maxBuckets - 1; i >= 0; i--) {
      final year = now.year - i;
      final total = logs
          .where((log) => log.date.year == year)
          .fold<double>(0.0, (sum, log) => sum + log.amount);

      result.add({
        'label': '$year',
        'amount': total,
        'year': year,
      });
    }
    return result;
  }

  /// Get the maximum amount across all buckets in an aggregation
  /// (useful for scaling chart axes).
  static double maxAmount(List<Map<String, dynamic>> data) {
    double max = 0;
    for (final entry in data) {
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
      if (amount > max) max = amount;
    }
    return max;
  }
}
