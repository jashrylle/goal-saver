import 'package:flutter/material.dart';
import '../models/achievement_model.dart';
import '../utils/app_colors.dart';
import 'confetti_widget.dart';

/// Rarity tier definition for achievements.
class BadgeRarity {
  final String name;
  final Color color;
  final Color glowColor;
  final int minRequirement;

  const BadgeRarity({
    required this.name,
    required this.color,
    required this.glowColor,
    required this.minRequirement,
  });

  static const common = BadgeRarity(
    name: 'Common',
    color: Color(0xFF9E9E9E),
    glowColor: Color(0xFF9E9E9E),
    minRequirement: 0,
  );
  static const rare = BadgeRarity(
    name: 'Rare',
    color: Color(0xFF2196F3),
    glowColor: Color(0xFF2196F3),
    minRequirement: 10000,
  );
  static const epic = BadgeRarity(
    name: 'Epic',
    color: Color(0xFF9C27B0),
    glowColor: Color(0xFFCE93D8),
    minRequirement: 100000,
  );
  static const legendary = BadgeRarity(
    name: 'Legendary',
    color: Color(0xFFFF6F00),
    glowColor: Color(0xFFFFD700),
    minRequirement: 1000000,
  );

  static BadgeRarity fromRequirement(int requirement) {
    if (requirement >= 1000000) return legendary;
    if (requirement >= 100000) return epic;
    if (requirement >= 10000) return rare;
    return common;
  }
}

/// Professional achievement unlock popup with badge details, rarity, and confetti.
/// Stays visible until the user explicitly dismisses it.
class AchievementCelebration extends StatefulWidget {
  final AchievementBadge badge;
  final VoidCallback onDismiss;

  const AchievementCelebration({
    super.key,
    required this.badge,
    required this.onDismiss,
  });

  /// Show the celebration dialog from any context.
  static void show(BuildContext context, AchievementBadge badge) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => AchievementCelebration(
        badge: badge,
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  State<AchievementCelebration> createState() => _AchievementCelebrationState();
}

class _AchievementCelebrationState extends State<AchievementCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final rarity = BadgeRarity.fromRequirement(badge.requirement);

    // Rarity icons
    final rarityIcon = switch (rarity) {
      BadgeRarity.common => Icons.circle_outlined,
      BadgeRarity.rare => Icons.star_rounded,
      BadgeRarity.epic => Icons.diamond_rounded,
      BadgeRarity.legendary => Icons.auto_awesome_rounded,
      _ => Icons.circle_outlined,
    };

    // XP reward
    final xpReward = _rewardXp(badge.requirement);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Stack(
        children: [
          // Backdrop - tappable background
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.panel : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: rarity.color.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rarity.glowColor.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trophy icon with glow
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            rarity.color.withValues(alpha: 0.8),
                            rarity.color.withValues(alpha: 0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: rarity.glowColor.withValues(alpha: 0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        badge.icon,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // "Achievement Unlocked!"
                    Text(
                      '🏆 Achievement Unlocked!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: rarity.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Badge Title
                    Text(
                      badge.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Rarity badge with icon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: rarity.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: rarity.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(rarityIcon, size: 14, color: rarity.color),
                          const SizedBox(width: 6),
                          Text(
                            rarity.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: rarity.color,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        badge.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: mutedColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // XP Reward
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFFD700).withValues(alpha: 0.12),
                            const Color(0xFFFFA726).withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: const Color(0xFFFFD700), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '+$xpReward XP Reward',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Awesome! button - must stay visible, user must tap to dismiss
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.onDismiss,
                        style: FilledButton.styleFrom(
                          backgroundColor: rarity.color,
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor: rarity.color.withValues(alpha: 0.3),
                        ),
                        child: const Text(
                          '🎉 Awesome!',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confetti overlay (positioned over everything)
          if (_controller.value > 0.1)
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiOverlay(
                  show: true,
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _rewardXp(int requirement) {
    if (requirement >= 1000000) return 500;
    if (requirement >= 100000) return 250;
    if (requirement >= 10000) return 100;
    if (requirement >= 1000) return 50;
    return 25;
  }
}
