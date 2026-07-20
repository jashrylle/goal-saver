import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../models/achievement_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common_widgets.dart';

/// Shows achievement progress, challenge stats, streak performance,
/// and discipline trends in a compact card.
class AchievementStatsCard extends StatelessWidget {
  const AchievementStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    final unlockedBadges = controller.achievementBadges.where((b) => b.unlocked).length;
    final totalBadges = Achievements.totalCount;

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
                    Text('Achievements & Stats', style: AppText.title.copyWith(color: textColor)),
                    const SizedBox(height: 2),
                    Text('Your progress at a glance', style: TextStyle(fontSize: 11, color: mutedColor)),
                  ],
                ),
              ),
              Icon(Icons.emoji_events_rounded, color: controller.accentColor.withValues(alpha: 0.6), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          // Stats grid
          Row(
            children: [
              Expanded(child: _statCard(
                icon: Icons.emoji_events_rounded,
                label: 'Badges',
                value: '$unlockedBadges / $totalBadges',
                color: const Color(0xFFFFD93D),
                subtext: '${(unlockedBadges / totalBadges * 100).round()}% unlocked',
                isDark: isDark,
              )),
              const SizedBox(width: 8),
              Expanded(child: _statCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: '${controller.streakDays}',
                color: const Color(0xFFFF6B6B),
                subtext: 'Best: ${controller.longestStreak} days',
                isDark: isDark,
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _statCard(
                icon: Icons.speed_rounded,
                label: 'Discipline',
                value: '${controller.disciplineScore}',
                color: const Color(0xFF00D9FF),
                subtext: '/ 100',
                isDark: isDark,
              )),
            ],
          ),
          const SizedBox(height: 12),
          // Level XP bar
          _levelSection(controller, isDark, mutedColor),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String subtext,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFFFFFFF).withValues(alpha: 0.04) : const Color(0xFF000000).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1)),
          const SizedBox(height: 2),
          Text(subtext, style: TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _levelSection(GoalSaverController controller, bool isDark, Color mutedColor) {
    final level = controller.playerLevel;
    final xpPct = level.xpToNextLevel > 0 ? (level.xp / level.xpToNextLevel).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            controller.accentColor.withValues(alpha: 0.1),
            controller.accentColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Level badge
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: controller.accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: controller.accentColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                '${level.level}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: controller.accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Level ${level.level}', style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.lightText,
                )),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: xpPct,
                    backgroundColor: isDark ? const Color(0xFFFFFFFF).withValues(alpha: 0.08) : const Color(0xFF000000).withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(controller.accentColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${level.xp} / ${level.xpToNextLevel} XP',
                  style: TextStyle(fontSize: 9, color: mutedColor),
                ),
              ],
            ),
          ),
          Text(
            'Lv.${level.level + 1}',
            style: TextStyle(fontSize: 10, color: mutedColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
