import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/achievement_model.dart';
import '../../models/savings_plan_model.dart' show PlayerLevel;
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';
import 'notes_management_screen.dart';

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
    final accentColor = context.read<GoalSaverController>().accentColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: accentColor,
          ),
        ),
      ),
    );
  }

  // ── Badge system from AchievementBadge model ───────────────────────────
  Widget _buildBadgesSection(GoalSaverController controller) {
    // Use the controller's persisted achievement badges for accurate state
    final allBadges = Achievements.all;
    final badgeMap = {for (final b in controller.achievementBadges) b.id: b};
    final unlockedCount = controller.achievementBadges.where((b) => b.unlocked).length;

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
                '$unlockedCount/${allBadges.length}',
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
              final tracked = badgeMap[badge.id];
              final unlocked = tracked?.unlocked ?? false;
              final progress = tracked?.currentProgress ?? 0;
              return GestureDetector(
                onTap: () => _showBadgeDetail(context, badge, unlocked, progress),
                child: _BadgeItem(badge: badge, unlocked: unlocked, progress: progress),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, AchievementBadge badge, bool unlocked, int progress) {
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
            if (!unlocked && badge.requirement > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: (progress / badge.requirement).clamp(0.0, 1.0),
                  backgroundColor: AppColors.muted.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(badge.color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Progress: $progress / ${badge.requirement}',
                style: TextStyle(
                  fontSize: 11,
                  color: badge.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

                          // ── Player Level Card ────────────────────────
                          _PlayerLevelProfileCard(controller: controller),
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

                          // Notes section — clickable preview, opens dedicated screen
                          Text(
                            'Personal Notes',
                            style: AppText.adaptive(context, AppText.titleMedium),
                          ),
                          const SizedBox(height: 12),
                          _NotesPreviewSection(controller: controller),
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
              // Close dialog first, then pop to shell using root navigator
              Navigator.pop(ctx);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).maybePop();
                }
              });
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

/// Notes preview widget — clickable to open the full NotesManagementScreen
class _NotesPreviewSection extends StatelessWidget {
  final GoalSaverController controller;

  const _NotesPreviewSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final notes = controller.savedNotes;
    final latestNote = notes.isNotEmpty ? notes.first['content'] as String : '';
    final noteCount = notes.length;
    final accentColor = controller.accentColor;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotesManagementScreen(),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt_rounded, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Notes & Reminders',
                  style: AppText.adaptive(context, AppText.title),
                ),
                const Spacer(),
                if (noteCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$noteCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: mutedColor),
              ],
            ),
            const SizedBox(height: 10),
            if (latestNote.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.muted.withValues(alpha: 0.08)
                      : AppColors.lightMuted.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  latestNote,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.note_add_rounded, size: 36, color: mutedColor.withValues(alpha: 0.5)),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to add notes and reminders\nfor your savings goals',
                        style: TextStyle(fontSize: 12, color: mutedColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Player Level card shown in the Profile page — taps open a level details dialog.
class _PlayerLevelProfileCard extends StatelessWidget {
  final GoalSaverController controller;

  const _PlayerLevelProfileCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final level = controller.playerLevel;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    return Pressable(
      onTap: () => _showLevelDetails(context, controller, level),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Level badge with gradient
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    controller.accentColor.withValues(alpha: 0.7),
                    controller.accentColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: controller.accentColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${level.level}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'LEVEL',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Level ${level.level}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${level.title}',
                        style: TextStyle(fontSize: 13, color: controller.accentColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: level.progress,
                      backgroundColor: AppColors.muted.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(controller.accentColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${level.xp} / ${level.xpToNextLevel} XP',
                        style: TextStyle(fontSize: 10, color: mutedColor),
                      ),
                      const Spacer(),
                      Icon(Icons.auto_awesome_rounded, color: const Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 3),
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
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: mutedColor),
          ],
        ),
      ),
    );
  }

  void _showLevelDetails(BuildContext context, GoalSaverController controller, PlayerLevel level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final levels = ['Beginner Saver', 'Regular Saver', 'Dedicated Saver', 'Savings Pro', 'Finance Wizard',
      'Money Master', 'Wealth Builder', 'Fortune Seeker', 'Prosperity King', 'Legendary Saver'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD700), size: 24),
            const SizedBox(width: 10),
            Text(
              'Level ${level.level} — ${level.title}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textColor),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // XP progress
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: controller.accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${level.xp} / ${level.xpToNextLevel} XP',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: controller.accentColor),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: level.progress,
                          backgroundColor: AppColors.muted.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(controller.accentColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(level.progress * 100).round()}% to next level',
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Total XP
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Total XP: ${level.totalXp}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Level progression
                Text(
                  'Level Progression',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 8),
                ...levels.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final title = entry.value;
                  final isUnlocked = idx <= level.level;
                  final isCurrent = idx == level.level;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? controller.accentColor.withValues(alpha: 0.2)
                                : AppColors.muted.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '$idx',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isUnlocked ? controller.accentColor : mutedColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              color: isCurrent ? controller.accentColor : (isUnlocked ? textColor : mutedColor),
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: controller.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: controller.accentColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
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
}

/// Single badge item in the grid
class _BadgeItem extends StatelessWidget {
  final AchievementBadge badge;
  final bool unlocked;
  final int progress;

  const _BadgeItem({required this.badge, required this.unlocked, this.progress = 0});

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
          if (!unlocked && badge.requirement > 0 && progress > 0) ...[
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 2,
                value: (progress / badge.requirement).clamp(0.0, 1.0),
                backgroundColor: AppColors.muted.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(badge.color.withValues(alpha: 0.5)),
              ),
            ),
          ],
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
