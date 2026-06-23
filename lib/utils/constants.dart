import 'package:flutter/material.dart';
import '../models/goal_model.dart';

/// Seed data for demo and initial population
/// Move this data from main.dart to here

final seedGoals = [
  SavingsGoal(
    id: '1',
    title: 'Laptop for College',
    saved: 12500,
    target: 45000,
    icon: Icons.devices_rounded,
    color: const Color(0xFF5FDE9E),
    category: GoalCategory.technology,
    frequency: SavingFrequency.weekly,
    priority: 9,
    dueDate: DateTime.now().add(const Duration(days: 90)),
    createdDate: DateTime.now().subtract(const Duration(days: 30)),
    notes: 'Need for upcoming semester - studying computer science',
  ),
  SavingsGoal(
    id: '2',
    title: 'Summer Abroad Program',
    saved: 8200,
    target: 35000,
    icon: Icons.flight_rounded,
    color: const Color(0xFFFF6B9D),
    category: GoalCategory.travel,
    frequency: SavingFrequency.biWeekly,
    priority: 8,
    dueDate: DateTime.now().add(const Duration(days: 120)),
    createdDate: DateTime.now().subtract(const Duration(days: 45)),
    notes: '3-month exchange program in Japan',
  ),
  SavingsGoal(
    id: '3',
    title: 'Emergency Fund',
    saved: 15600,
    target: 25000,
    icon: Icons.warning_rounded,
    color: const Color(0xFFFFD93D),
    category: GoalCategory.emergency,
    frequency: SavingFrequency.monthly,
    priority: 7,
    dueDate: DateTime.now().add(const Duration(days: 60)),
    createdDate: DateTime.now().subtract(const Duration(days: 60)),
    notes: '3-month living expenses',
  ),
  SavingsGoal(
    id: '4',
    title: 'Photography Equipment',
    saved: 3400,
    target: 15000,
    icon: Icons.camera_rounded,
    color: const Color(0xFF00D9FF),
    category: GoalCategory.technology,
    frequency: SavingFrequency.weekly,
    priority: 5,
    dueDate: DateTime.now().add(const Duration(days: 150)),
    createdDate: DateTime.now().subtract(const Duration(days: 15)),
    notes: 'Professional camera and lenses',
  ),
  SavingsGoal(
    id: '5',
    title: 'Health & Wellness Retreat',
    saved: 2100,
    target: 8000,
    icon: Icons.spa_rounded,
    color: const Color(0xFF52B788),
    category: GoalCategory.health,
    frequency: SavingFrequency.weekly,
    priority: 4,
    dueDate: DateTime.now().add(const Duration(days: 180)),
    createdDate: DateTime.now().subtract(const Duration(days: 20)),
    notes: 'Yoga and meditation retreat in Bali',
  ),
  SavingsGoal(
    id: '6',
    title: 'Books & Learning Materials',
    saved: 4800,
    target: 6000,
    icon: Icons.library_books_rounded,
    color: const Color(0xFF5FDE9E),
    category: GoalCategory.education,
    frequency: SavingFrequency.biWeekly,
    priority: 6,
    dueDate: DateTime.now().add(const Duration(days: 45)),
    createdDate: DateTime.now().subtract(const Duration(days: 35)),
    notes: 'Programming books and online courses',
    completed: false,
  ),
  SavingsGoal(
    id: '7',
    title: 'Gaming Setup Upgrade',
    saved: 6200,
    target: 18000,
    icon: Icons.videogame_asset_rounded,
    color: const Color(0xFF9D4EDD),
    category: GoalCategory.entertainment,
    frequency: SavingFrequency.weekly,
    priority: 3,
    dueDate: DateTime.now().add(const Duration(days: 200)),
    createdDate: DateTime.now().subtract(const Duration(days: 25)),
    notes: 'New monitor, keyboard, mouse, and chair',
  ),
];

final seedHistory = [
  SavingsLog(
    id: '1',
    goalId: '1',
    goalTitle: 'Laptop for College',
    amount: 2500,
    date: DateTime.now().subtract(const Duration(days: 7)),
  ),
  SavingsLog(
    id: '2',
    goalId: '2',
    goalTitle: 'Summer Abroad Program',
    amount: 1500,
    date: DateTime.now().subtract(const Duration(days: 5)),
  ),
  SavingsLog(
    id: '3',
    goalId: '3',
    goalTitle: 'Emergency Fund',
    amount: 3200,
    date: DateTime.now().subtract(const Duration(days: 4)),
  ),
  SavingsLog(
    id: '4',
    goalId: '1',
    goalTitle: 'Laptop for College',
    amount: 2000,
    date: DateTime.now().subtract(const Duration(days: 3)),
  ),
  SavingsLog(
    id: '5',
    goalId: '4',
    goalTitle: 'Photography Equipment',
    amount: 1200,
    date: DateTime.now().subtract(const Duration(days: 2)),
  ),
  SavingsLog(
    id: '6',
    goalId: '6',
    goalTitle: 'Books & Learning Materials',
    amount: 800,
    date: DateTime.now().subtract(const Duration(days: 1)),
  ),
  SavingsLog(
    id: '7',
    goalId: '3',
    goalTitle: 'Emergency Fund',
    amount: 2500,
    date: DateTime.now(),
  ),
  SavingsLog(
    id: '8',
    goalId: '5',
    goalTitle: 'Health & Wellness Retreat',
    amount: 700,
    date: DateTime.now(),
  ),
  SavingsLog(
    id: '9',
    goalId: '7',
    goalTitle: 'Gaming Setup Upgrade',
    amount: 1500,
    date: DateTime.now(),
  ),
  SavingsLog(
    id: '10',
    goalId: '2',
    goalTitle: 'Summer Abroad Program',
    amount: 1200,
    date: DateTime.now(),
  ),
];

/// Get goal icon based on category for quick lookup
IconData getGoalIcon(String categoryName) {
  return switch (categoryName) {
    'education' => Icons.school_rounded,
    'technology' => Icons.devices_rounded,
    'travel' => Icons.flight_rounded,
    'emergency' => Icons.warning_rounded,
    'health' => Icons.favorite_rounded,
    'entertainment' => Icons.movie_rounded,
    'savings' => Icons.savings_rounded,
    'investment' => Icons.trending_up_rounded,
    _ => Icons.flag_rounded,
  };
}

/// Get category color for quick lookup
Color getCategoryColor(String categoryName) {
  return switch (categoryName) {
    'education' => const Color(0xFF5FDE9E),
    'technology' => const Color(0xFF00D9FF),
    'travel' => const Color(0xFFFF6B9D),
    'emergency' => const Color(0xFFFFD93D),
    'health' => const Color(0xFF52B788),
    'entertainment' => const Color(0xFF9D4EDD),
    'savings' => const Color(0xFF3ECCC1),
    'investment' => const Color(0xFFFFB703),
    _ => const Color(0xFF5FDE9E),
  };
}

/// Demo messaging templates for quick actions
const demoMessages = {
  'celebration': 'Savings added to {goal}. Keep the streak alive! 🎉',
  'goalCreated': '{goal} added to your savings plan.',
  'goalCompleted': '{goal} completed! Achievement unlocked! 🏆',
  'goalPaused': '{goal} paused from active planning.',
  'goalResumed': 'You\'re back on track with {goal}! 💪',
  'goalArchived': '{goal} archived from active planning.',
  'priorityUpdated': '{goal} priority updated.',
  'milestoneReached': 'Milestone! You\'ve reached {percent}% of {goal}!',
};

/// Quick savings suggestions
const quickSavingsSuggestions = [
  ('100', 'Small contribution'),
  ('500', 'Weekly target'),
  ('1000', 'Bi-weekly boost'),
  ('2500', 'Monthly push'),
  ('5000', 'Major milestone'),
];

/// Achievement unlock messages
const achievementMessages = {
  'first_goal': 'You\'ve created your first goal! 🎯',
  'three_goals': 'Goal Setter - 3 active goals! 📚',
  'five_goals': 'Master Planner - 5 active goals! 🎪',
  'thousand_saved': 'Saver - You\'ve saved ₱1,000! 💰',
  'ten_thousand_saved': 'Big Saver - ₱10,000 milestone! 🚀',
  'first_goal_complete': 'Goal Completed - First win! 🏅',
  'three_goals_complete': 'Achiever - 3 goals completed! 👑',
  'seven_day_streak': 'On Fire - 7-day streak! 🔥',
  'thirty_day_streak': 'Unstoppable - 30-day streak! ⚡',
  'discipline_expert': 'Discipline Expert - 90+ score! 🏆',
};

/// Motivational reminder templates
const motivationalReminders = [
  'Every small contribution counts! Keep saving. 💪',
  'You\'re {percent}% of the way there. Stay focused! 🎯',
  'Discipline is the bridge between goals and achievement. 🌉',
  'Your future self will thank you for saving today. 🙏',
  'One day closer to your goal. Keep going! 🚀',
  'Consistency is key. You\'ve got this! 🔑',
  'This week\'s savings will compound into big wins! 📈',
  'Remember why you started. Keep the momentum! 💫',
  'Your savings journey matters. Keep contributing! 🌟',
  'Small steps lead to big dreams. You\'re on your way! 🌈',
];

/// Category descriptions for onboarding
const categoryDescriptions = {
  'education': 'Learning, courses, textbooks, and academic goals',
  'technology': 'Gadgets, equipment, software, and tech upgrades',
  'travel': 'Trips, vacations, flights, and travel experiences',
  'emergency': 'Financial safety net for unexpected expenses',
  'health': 'Wellness, fitness, medical, and health-related goals',
  'entertainment': 'Entertainment, hobbies, events, and fun',
  'savings': 'General savings and financial security',
  'investment': 'Investments, stocks, crypto, and wealth building',
};
