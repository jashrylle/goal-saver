import '../models/goal_model.dart';

/// Extension that returns the display name for a goal (uses productName if set).
extension GoalCompatibility on SavingsGoal {
  String get categoryName => productName.isEmpty ? title : productName;
}

/// Extension for formatting doubles as money strings with comma separators.
extension MoneyFormatting on double {
  String get money {
    final rounded = round();
    final chars = rounded.toString().split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i != 0 && i % 3 == 0) buffer.write(',');
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }
}
