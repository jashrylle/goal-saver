import 'package:intl/intl.dart';

/// Formats DateTime values into human-readable 12-hour AM/PM strings.
///
/// Examples:
/// - "January 15, 2026 • 10:35 AM"
/// - "Today • 2:30 PM"
/// - "Yesterday • 8:15 AM"
class TimestampFormatter {
  /// Full date with 12-hour time.
  /// e.g. "July 17, 2026 • 10:35 AM"
  static String full(DateTime date) {
    final dateStr = DateFormat('MMMM d, yyyy').format(date);
    final timeStr = _formatTime(date);
    return '$dateStr • $timeStr';
  }

  /// Short date with 12-hour time (relative for today/yesterday).
  /// e.g. "Today • 10:35 AM" or "Jul 17 • 10:35 AM"
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today • ${_formatTime(date)}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (dateDay == yesterday) {
      return 'Yesterday • ${_formatTime(date)}';
    }
    final dateStr = DateFormat('MMM d').format(date);
    return '$dateStr • ${_formatTime(date)}';
  }

  /// Just the time portion in 12-hour format.
  /// e.g. "10:35 AM", "2:30 PM"
  static String timeOnly(DateTime date) {
    return _formatTime(date);
  }

  /// Just the date portion.
  /// e.g. "July 17, 2026"
  static String dateOnly(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  /// Parse a timestamp string stored in ISO 8601 format.
  static DateTime? parseStored(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString);
    } catch (_) {
      return null;
    }
  }

  /// Format the time portion in 12-hour AM/PM.
  static String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final amPm = hour < 12 ? 'AM' : 'PM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $amPm';
  }

  /// Format a duration as a human-readable string.
  /// e.g. "2 hours ago", "3 days ago", "Just now"
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).round()}mo ago';
    return '${(diff.inDays / 365).round()}y ago';
  }
}
