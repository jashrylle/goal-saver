import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/achievement_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';

/// Dedicated user profile page showing personal info, badges, and savings streak.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? _selectedPhotoUrl;
  File? _pickedImageFile;

  final List<String> _presets = ["🦊", "🦁", "🐼", "🐨", "🤖", "🚀", "💡", "💰", "🐷", "🍕"];

  @override
  void initState() {
    super.initState();
    final controller = context.read<GoalSaverController>();
    _nameController = TextEditingController(text: controller.userName);
    _emailController = TextEditingController(text: controller.userEmail);
    _selectedPhotoUrl = controller.userPhotoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(GoalSaverController controller) async {
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    if (newName.isEmpty) return;
    
    // If user picked a real image, store as file path
    String? photoUrl = _selectedPhotoUrl;
    if (_pickedImageFile != null) {
      photoUrl = _pickedImageFile!.path;
    }
    
    await controller.updateProfile(
      name: newName,
      email: newEmail,
      photoUrl: photoUrl,
    );
    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.lime,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = File(pickedFile.path);
          _selectedPhotoUrl = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildAvatar(String? photoUrl, String name, {double size = 80, double fontSize = 32}) {
    // If user picked a real image file
    if (_pickedImageFile != null || (photoUrl != null && photoUrl.isNotEmpty && !_presets.contains(photoUrl) && !photoUrl.startsWith('http'))) {
      try {
        final path = _pickedImageFile?.path ?? photoUrl!;
        if (File(path).existsSync()) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.lime.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size / 2 - 2),
              child: Image.file(
                File(path),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(name, size: size, fontSize: fontSize),
              ),
            ),
          );
        }
      } catch (_) {}
    }

    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.lime.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2 - 2),
            child: Image.network(
              photoUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(name, size: size, fontSize: fontSize),
            ),
          ),
        );
      } else if (_presets.contains(photoUrl)) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.lime.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.lime.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              photoUrl,
              style: TextStyle(fontSize: fontSize + 8),
            ),
          ),
        );
      }
    }
    return _buildDefaultAvatar(name, size: size, fontSize: fontSize);
  }

  Widget _buildDefaultAvatar(String name, {double size = 80, double fontSize = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.lime.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: AppColors.lime,
          ),
        ),
      ),
    );
  }

  // ── Badge system from AchievementBadge model ───────────────────────────
  Widget _buildBadgesSection(GoalSaverController controller) {
    final totalSaved = controller.totalSaved;
    final completedCount = controller.allActiveGoals.where((g) => g.completed).length;
    final activeCount = controller.allActiveGoals.length;
    final score = controller.disciplineScore;

    // Determine which badges are unlocked based on actual data
    final allBadges = Achievements.all;
    final unlockedBadgeIds = <String>{};

    if (activeCount >= 1) unlockedBadgeIds.add('first_goal');
    if (activeCount >= 3) unlockedBadgeIds.add('three_goals');
    if (activeCount >= 5) unlockedBadgeIds.add('five_goals');
    if (controller.streakDays >= 7) unlockedBadgeIds.add('seven_day_streak');
    if (controller.streakDays >= 30) unlockedBadgeIds.add('thirty_day_streak');
    if (totalSaved >= 1000) unlockedBadgeIds.add('thousand_saved');
    if (totalSaved >= 10000) unlockedBadgeIds.add('ten_thousand_saved');
    if (completedCount >= 1) unlockedBadgeIds.add('first_goal_complete');
    if (completedCount >= 3) unlockedBadgeIds.add('three_goals_complete');
    if (score >= 90) unlockedBadgeIds.add('discipline_expert');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.lime, size: 20),
              const SizedBox(width: 8),
              Text(
                'Badges & Achievements',
                style: AppText.adaptive(context, AppText.title),
              ),
              const Spacer(),
              Text(
                '${unlockedBadgeIds.length}/${allBadges.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final unlocked = unlockedBadgeIds.contains(badge.id);
              return GestureDetector(
                onTap: () => _showBadgeDetail(context, badge, unlocked),
                child: _BadgeItem(badge: badge, unlocked: unlocked),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, AchievementBadge badge, bool unlocked) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.panel : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(badge.icon, color: badge.color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                badge.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Icon(badge.icon, size: 64, color: unlocked ? badge.color : AppColors.muted.withValues(alpha: 0.4)),
              ),
            ),
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.muted : AppColors.lightMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                  size: 16,
                  color: unlocked ? AppColors.lime : AppColors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  unlocked ? 'Unlocked' : 'Not yet unlocked',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: unlocked ? AppColors.lime : AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.lime)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Consumer<GoalSaverController>(
              builder: (context, controller, _) {
                final completedCount = controller.allActiveGoals
                    .where((g) => g.completed)
                    .length;
                final totalSaved = controller.totalSaved;
                final totalGoals = controller.allActiveGoals.length;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        metrics.pagePadding, 18, metrics.pagePadding, 48,
                      ),
                      sliver: SliverList.list(
                        children: [
                          // Header
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.lime,
                                ),
                              ),
                              const Expanded(
                                child: DashboardHeader(
                                  eyebrow: 'Account',
                                  title: 'My Profile',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Avatar & Name card
                          GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                if (_isEditing) ...[
                                  // Preview with tappable image
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Stack(
                                      children: [
                                        _buildAvatar(_selectedPhotoUrl, controller.userName, size: 90, fontSize: 36),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.lime,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: bgColor(isDark), width: 2),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_rounded,
                                              color: AppColors.ink,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap avatar to upload photo',
                                    style: TextStyle(fontSize: 11, color: mutedColor),
                                  ),
                                  const SizedBox(height: 12),

                                  // Emoji preset picker
                                  Text('Or choose a preset avatar', style: AppText.caption.copyWith(color: mutedColor)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    alignment: WrapAlignment.center,
                                    children: _presets.map((emoji) {
                                      final isSelected = _selectedPhotoUrl == emoji;
                                      return Pressable(
                                        onTap: () {
                                          setState(() {
                                            _selectedPhotoUrl = emoji;
                                            _pickedImageFile = null;
                                          });
                                        },
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.lime.withValues(alpha: 0.25) : Colors.transparent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? AppColors.lime : (isDark ? Colors.white24 : Colors.black12),
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),

                                  // Name Field
                                  TextField(
                                    controller: _nameController,
                                    style: TextStyle(color: textColor),
                                    decoration: goalInputDecoration(
                                      'Name',
                                      Icons.person_rounded,
                                      context: context,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Email Field
                                  TextField(
                                    controller: _emailController,
                                    style: TextStyle(color: textColor),
                                    decoration: goalInputDecoration(
                                      'Email Address',
                                      Icons.email_rounded,
                                      context: context,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 20),

                                  // Buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _isEditing = false;
                                            _nameController.text = controller.userName;
                                            _emailController.text = controller.userEmail;
                                            _selectedPhotoUrl = controller.userPhotoUrl;
                                            _pickedImageFile = null;
                                          });
                                        },
                                        child: Text('Cancel', style: TextStyle(color: mutedColor)),
                                      ),
                                      const SizedBox(width: 16),
                                      FilledButton(
                                        onPressed: () => _saveProfile(controller),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.lime,
                                          foregroundColor: AppColors.ink,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  )
                                ] else ...[
                                  // Read-only profile view with camera hint
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _nameController.text = controller.userName;
                                        _emailController.text = controller.userEmail;
                                        _selectedPhotoUrl = controller.userPhotoUrl;
                                        _isEditing = true;
                                      });
                                    },
                                    child: Stack(
                                      children: [
                                        _buildAvatar(controller.userPhotoUrl, controller.userName, size: 90, fontSize: 36),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.lime,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.edit_rounded,
                                              color: AppColors.ink,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    controller.userName,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  if (controller.userEmail.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      controller.userEmail,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Stats row (enhanced with streak details) - all clickable
                          Row(
                            children: [
                              Expanded(
                                child: Pressable(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$totalGoals active goal${
                                          totalGoals != 1 ? "s" : ""
                                        }'),
                                        backgroundColor: AppColors.lime,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: _StatCard(
                                    icon: Icons.flag_rounded,
                                    value: '$totalGoals',
                                    label: 'Active Goals',
                                    color: AppColors.lime,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Pressable(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$completedCount goal${
                                          completedCount != 1 ? "s" : ""
                                        } completed!'),
                                        backgroundColor: const Color(0xFF00E676),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: _StatCard(
                                    icon: Icons.check_circle_rounded,
                                    value: '$completedCount',
                                    label: 'Completed',
                                    color: const Color(0xFF00E676),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Pressable(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Streak: ${controller.streakDays} day${
                                          controller.streakDays != 1 ? "s" : ""
                                        }! Keep saving!'),
                                        backgroundColor: const Color(0xFFFF7043),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: _StatCard(
                                    icon: Icons.local_fire_department_rounded,
                                    value: '${controller.streakDays}d',
                                    label: 'Streak',
                                    color: const Color(0xFFFF7043),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Total saved with discipline
                          GlassCard(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.lime.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.savings_rounded,
                                    color: AppColors.lime,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Saved',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mutedColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        controller.showBalance
                                            ? controller.formatMoney(totalSaved)
                                            : '${controller.currencySymbol} •••',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.lime,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.lime.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${controller.disciplineScore}/100',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.lime,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Savings Streak section ──────────────────
                          _buildStreakSection(controller),
                          const SizedBox(height: 20),

                          // ── Badges section ──────────────────────────
                          _buildBadgesSection(controller),
                          const SizedBox(height: 20),

                          // Notes section
                          Text(
                            'Personal Notes',
                            style: AppText.adaptive(context, AppText.titleMedium),
                          ),
                          const SizedBox(height: 12),
                          _NotesSection(controller: controller),
                          const SizedBox(height: 20),

                          // Goals progress section
                          if (controller.allActiveGoals.isNotEmpty) ...[
                            Text(
                              'Goals Overview',
                              style: AppText.adaptive(context, AppText.titleMedium),
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: controller.allActiveGoals.take(5).map((goal) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: goal.color.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                goal.icon,
                                                size: 16,
                                                color: goal.color,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    goal.title,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                      color: textColor,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    controller.showBalance
                                                        ? '${controller.formatMoney(goal.saved)} / ${controller.formatMoney(goal.target)}'
                                                        : '••• / •••',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: mutedColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              goal.progressPercent,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: goal.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            minHeight: 6,
                                            value: goal.progress,
                                            backgroundColor:
                                                AppColors.muted.withValues(alpha: 0.2),
                                            valueColor: AlwaysStoppedAnimation(goal.color),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(GoalSaverController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streakDays = controller.streakDays;
    
    // Generate mini calendar for last 7 days
    final today = DateTime.now();
    final weekDays = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final hasActivity = controller.history.any((log) =>
        log.date.day == day.day &&
        log.date.month == day.month &&
        log.date.year == day.year
      );
      weekDays.add({
        'label': ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day.weekday % 7],
        'day': day.day,
        'active': hasActivity,
        'isToday': i == 0,
      });
    }

    return Pressable(
      onTap: () => _showStreakDetails(context, controller, streakDays),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7043), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Savings Streak',
                  style: AppText.adaptive(context, AppText.title),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: streakDays >= 7 
                      ? const Color(0xFFFF7043).withValues(alpha: 0.2)
                      : AppColors.muted.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$streakDays day${streakDays != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: streakDays >= 7 ? const Color(0xFFFF7043) : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mini week calendar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekDays.map((day) {
                final isActive = day['active'] as bool;
                final isToday = day['isToday'] as bool;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isToday ? AppColors.lime : (isDark ? AppColors.muted : AppColors.lightMuted),
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isToday ? AppColors.lime : const Color(0xFFFF7043).withValues(alpha: 0.6))
                            : (isDark ? AppColors.panel : Colors.grey.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(10),
                        border: isToday ? Border.all(color: AppColors.lime, width: 1.5) : null,
                      ),
                      child: Center(
                        child: Text(
                          '${day['day']}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                            color: isActive ? AppColors.ink : (isDark ? AppColors.muted : AppColors.lightMuted),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  streakDays >= 30
                      ? Icons.local_fire_department_rounded
                      : streakDays >= 7
                          ? Icons.local_fire_department_rounded
                          : streakDays >= 3
                              ? Icons.thumb_up_alt_rounded
                              : Icons.fitness_center_rounded,
                  size: 14,
                  color: streakDays >= 3 ? const Color(0xFFFF7043) : AppColors.muted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    streakDays >= 30
                        ? 'Incredible! You have saved consistently for over a month!'
                        : streakDays >= 7
                            ? 'Great streak! Keep it going to unlock more badges!'
                            : streakDays >= 3
                                ? 'Good start! Save daily to build your streak!'
                                : 'Start your streak today! Log your savings now.',
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedColor(isDark),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: mutedColor(isDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakDetails(BuildContext context, GoalSaverController controller, int streakDays) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = controller.history;
    final last7Days = history.where((log) {
      final diff = DateTime.now().difference(log.date).inDays;
      return diff < 7;
    }).length;
    final totalLogs = history.length;
    final discipline = controller.disciplineScore;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.panel : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              streakDays >= 30
                  ? Icons.local_fire_department_rounded
                  : streakDays >= 7
                      ? Icons.local_fire_department_rounded
                      : Icons.fitness_center_rounded,
              color: streakDays >= 3 ? const Color(0xFFFF7043) : AppColors.muted,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text('Streak Details', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _streakStatRow(Icons.local_fire_department_rounded, 'Current Streak', '$streakDays days', const Color(0xFFFF7043)),
            const SizedBox(height: 12),
            _streakStatRow(Icons.history_rounded, 'Total Logs', '$totalLogs entries', AppColors.lime),
            const SizedBox(height: 12),
            _streakStatRow(Icons.date_range_rounded, 'Last 7 Days', '$last7Days savings', const Color(0xFF00D9FF)),
            const SizedBox(height: 12),
            _streakStatRow(Icons.military_tech_rounded, 'Discipline Score', '$discipline/100', AppColors.lime),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: streakDays >= 7
                    ? const Color(0xFFFF7043).withValues(alpha: 0.1)
                    : AppColors.muted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                streakDays >= 30
                    ? '🔥 Unstoppable! Over a month of consistent savings!'
                    : streakDays >= 7
                        ? '🔥 Great momentum! Keep saving daily to reach 30 days!'
                        : streakDays >= 3
                            ? '💪 Good start! Save every day to build a strong habit.'
                            : '🎯 Start today! Log your first savings to begin your streak.',
                style: TextStyle(
                  fontSize: 12,
                  color: streakDays >= 3 ? const Color(0xFFFF7043) : AppColors.muted,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.lime)),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to shell, then switch to analytics tab
            },
            icon: const Icon(Icons.bar_chart_rounded, size: 16),
            label: const Text('Go Back', style: TextStyle(color: AppColors.lime)),
          ),
        ],
      ),
    );
  }

  Widget _streakStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color),
        ),
      ],
    );
  }

  Color bgColor(bool isDark) => isDark ? AppColors.panel : Colors.white;
  Color mutedColor(bool isDark) => isDark ? AppColors.muted : AppColors.lightMuted;
}

/// Notes section widget for saving and managing multiple notes
class _NotesSection extends StatefulWidget {
  final GoalSaverController controller;

  const _NotesSection({required this.controller});

  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  final TextEditingController _newNoteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _newNoteController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final content = _newNoteController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSaving = true);
    await widget.controller.addNote(content);
    _newNoteController.clear();
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note added!'),
          backgroundColor: AppColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteNote(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.panel : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.controller.deleteNote(id);
    }
  }

  Future<void> _editNote(String id, String currentContent) async {
    final editController = TextEditingController(text: currentContent);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.panel : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Note'),
        content: TextField(
          controller: editController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Edit your note...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, editController.text.trim()),
            child: const Text('Save', style: TextStyle(color: AppColors.lime)),
          ),
        ],
      ),
    );
    editController.dispose();
    if (result != null && result.isNotEmpty) {
      await widget.controller.updateNote(id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final notes = widget.controller.savedNotes;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note_alt_rounded, color: AppColors.lime, size: 20),
              const SizedBox(width: 8),
              Text(
                'Notes & Reminders',
                style: AppText.adaptive(context, AppText.title),
              ),
              const Spacer(),
              if (notes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${notes.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lime),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Add new note input
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _newNoteController,
                  style: TextStyle(color: textColor, fontSize: 13),
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Write a new note...',
                    hintStyle: TextStyle(color: mutedColor, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.muted.withValues(alpha: 0.2) : AppColors.lightMuted.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.muted.withValues(alpha: 0.2) : AppColors.lightMuted.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.lime, width: 1.5),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.muted.withValues(alpha: 0.08) : AppColors.lightMuted.withValues(alpha: 0.08),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: _isSaving ? null : _addNote,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                          ),
                        )
                      : const Icon(Icons.add_rounded, color: AppColors.ink, size: 22),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Notes list
          if (notes.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.note_add_rounded, size: 40, color: mutedColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'No notes yet. Add your first note above!',
                      style: TextStyle(fontSize: 12, color: mutedColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...notes.map((note) {
              final id = note['id'] as String;
              final content = note['content'] as String;
              final createdAt = note['createdAt'] as String?;
              final dateStr = createdAt != null
                  ? _formatDate(DateTime.parse(createdAt))
                  : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.muted.withValues(alpha: 0.08)
                        : AppColors.lightMuted.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.muted.withValues(alpha: 0.12)
                          : AppColors.lightMuted.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              content,
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              Pressable(
                                onTap: () => _editNote(id, content),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.lime.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.edit_rounded, size: 14, color: AppColors.lime),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Pressable(
                                onTap: () => _deleteNote(id),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete_rounded, size: 14, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          dateStr,
                          style: TextStyle(fontSize: 10, color: mutedColor),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(noteDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Single badge item in the grid
class _BadgeItem extends StatelessWidget {
  final AchievementBadge badge;
  final bool unlocked;

  const _BadgeItem({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: unlocked
            ? badge.color.withValues(alpha: 0.12)
            : (isDark ? const Color(0xFFFFFFFF).withValues(alpha: 0.04) : const Color(0xFF000000).withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? badge.color.withValues(alpha: 0.3)
              : (isDark ? const Color(0xFFFFFFFF).withValues(alpha: 0.08) : const Color(0xFF000000).withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            badge.icon,
            size: 24,
            color: unlocked ? badge.color : AppColors.muted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: unlocked ? badge.color : (isDark ? AppColors.muted : AppColors.lightMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.muted : AppColors.lightMuted,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
