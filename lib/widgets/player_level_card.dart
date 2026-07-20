import 'package:flutter/material.dart';
import '../state/goal_saver_controller.dart';
import '../utils/app_colors.dart';
import 'common_widgets.dart';

/// Card showing the player's level, XP progress bar, and title.
class PlayerLevelCard extends StatelessWidget {
  final GoalSaverController controller;

  const PlayerLevelCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final level = controller.playerLevel;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Level badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  controller.accentColor.withValues(alpha: 0.7),
                  controller.accentColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: controller.accentColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${level.level}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Level ${level.level}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '· ${level.title}',
                        style: TextStyle(fontSize: 11, color: controller.accentColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: level.progress,
                    backgroundColor: AppColors.muted.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(controller.accentColor),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${level.xp} / ${level.xpToNextLevel} XP to next level',
                  style: TextStyle(fontSize: 9, color: mutedColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD700), size: 16),
              const SizedBox(height: 2),
              Text(
                '${level.totalXp} XP',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFD700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
