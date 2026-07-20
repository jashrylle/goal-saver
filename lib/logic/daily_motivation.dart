import 'dart:math' as math;

/// Generates personalized daily motivational messages based on the user's
/// current savings data, streak, goals, and achievements.
class DailyMotivation {
  static final math.Random _random = math.Random();

  /// General motivational quotes.
  static const List<String> _generalQuotes = [
    'Every small contribution counts! Keep saving. 💪',
    'Your future self will thank you for saving today. 🙏',
    'Discipline is the bridge between goals and achievement. 🌉',
    'One day closer to your goal. Keep going! 🚀',
    'Consistency is the key to financial freedom. 🔑',
    'Small steps lead to big dreams. You\'re on your way! 🌈',
    'Savings today = freedom tomorrow. ✨',
    'You\'re building something amazing. Keep going! 🌟',
    'Every peso saved is a step toward your dreams. 💫',
    'The habit of saving is itself an education. 📚',
    'Don\'t tell me what you value, show me your budget. 📊',
    'Financial freedom is available to those who learn about it and work for it. 🔓',
    'Do not save what is left after spending, but spend what is left after saving. 🎯',
    'A penny saved is a penny earned. 💰',
    'The art is not in making money, but in keeping it. 🏛️',
    'Wealth consists not in having great possessions, but in having few wants. 🌿',
    'It\'s not about having money. It\'s about having freedom. 🕊️',
    'The best time to start saving was yesterday. The next best time is now. ⏰',
    'Your savings journey is unique — embrace it! 🌟',
    'Be proud of every peso you save. It adds up! 💪',
  ];

  /// Streak-based motivational messages.
  static const List<String> _streakQuotes = [
    '🔥 Incredible! You\'re on fire! Keep that streak going!',
    '⚡ Another day, another savings win! You\'re unstoppable!',
    '🌟 Your consistency is inspiring! Keep showing up!',
    '💪 Day after day, you\'re building wealth!',
    '🔥 You\'re in the zone! Nothing can stop you now!',
    '🎯 Your streak is growing, and so is your future!',
    '🏆 Each day you save, you\'re getting stronger!',
    '📈 Your savings streak is climbing higher!',
  ];

  /// Milestone-based messages for specific progress percentages.
  static const Map<int, String> _milestoneMessages = {
    25: '🎉 25% complete! You\'re a quarter of the way there! Keep pushing!',
    50: '🏆 Halfway there! 50% complete! You\'ve got this!',
    75: '🚀 75% complete! The finish line is in sight! Almost there!',
    100: '🎊 100%! You did it! Goal completed! You\'re amazing!',
  };

  /// Get a personalized message based on current state.
  static String getMessage({
    required int streakDays,
    required int activeGoals,
    required int disciplineScore,
    required double totalSaved,
    required int completedGoals,
    required bool hasCheckedInToday,
  }) {
    final messages = <String>[];

    // Add streak-based message if streak is active
    if (streakDays >= 7 && hasCheckedInToday) {
      messages.add(_streakQuotes[_random.nextInt(_streakQuotes.length)]);
    }

    // Add milestone message if user just completed something
    if (completedGoals > 0 && completedGoals % 3 == 0) {
      messages.add(
          '🏅 You\'ve completed $completedGoals goals! That\'s incredible!');
    }

    // Add discipline-based message
    if (disciplineScore >= 80) {
      messages.add(
          '🌟 Your discipline score of $disciplineScore is outstanding! Keep it up!');
    } else if (disciplineScore >= 50) {
      messages.add(
          '📈 Your discipline score is $disciplineScore. You\'re improving!');
    }

    // Add encouragement based on today's check-in
    if (hasCheckedInToday) {
      messages.add(
          '✅ Great job checking in today! Your consistency is paying off!');
    } else {
      messages.add(
          '🎯 Start today! Every journey begins with a single step.');
    }

    // Add general quote as fallback
    messages.add(_generalQuotes[_random.nextInt(_generalQuotes.length)]);

    return messages[_random.nextInt(messages.length)];
  }

  /// Get a milestone celebration message.
  static String getMilestoneMessage(int percentage) {
    return _milestoneMessages[percentage] ??
        '🎉 $percentage% complete! Keep going!';
  }

  /// Get a tip based on current savings habits.
  static String getTip({
    required int streakDays,
    required int activeGoals,
    required double totalSaved,
  }) {
    final tips = <String>[];

    if (streakDays < 3) {
      tips.add(
        '💡 Tip: Try to save a small amount every day to build your streak. '
        'Even ₱10 counts!',
      );
    }
    if (activeGoals > 5) {
      tips.add(
        '💡 Tip: You have $activeGoals active goals. Consider focusing on '
        'fewer goals to make faster progress!',
      );
    }
    if (totalSaved > 0 && streakDays == 0) {
      tips.add(
        '💡 Tip: Log your savings today to start your streak. '
        'Consistency is key!',
      );
    }
    tips.add(
      '💡 Tip: Review your goals weekly to stay on track with your savings plan.',
    );
    tips.add(
      '💡 Tip: Set up automatic savings reminders to never miss a contribution.',
    );

    return tips[_random.nextInt(tips.length)];
  }
}
