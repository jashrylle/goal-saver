import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/extensions.dart';
import '../common_widgets.dart';
import '../confetti_widget.dart';
import '../goal_card.dart';
import 'add_goal_sheet.dart';
import 'productivity_sheet.dart';

/// Opens the goal-details bottom sheet.
Future<void> showGoalDetailsSheet(BuildContext context, SavingsGoal goal) {
  final rootContext = Navigator.of(context, rootNavigator: true).context;
  return showModalBottomSheet(
    context: rootContext,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GoalDetailsSheet(goal: goal),
  );
}

/// Bottom sheet showing full details, savings history, and options for a goal.
class GoalDetailsSheet extends StatelessWidget {
  const GoalDetailsSheet({super.key, required this.goal});

  final SavingsGoal goal;

  void _showEditSavingsDialog(BuildContext context, GoalSaverController controller, SavingsLog log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final textController = TextEditingController(text: log.amount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        title: Text(
          'Edit Savings Amount',
          style: AppText.titleMedium.copyWith(color: textColor),
        ),
        content: TextField(
          controller: textController,
          style: TextStyle(color: textColor),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: goalInputDecoration(
            'Amount (${controller.currencySymbol})',
            Icons.payments_rounded,
            context: context,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppText.body.copyWith(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () {
              final newAmount = double.tryParse(textController.text);
              if (newAmount != null && newAmount > 0) {
                controller.updateSavingsLog(log, newAmount);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Savings updated to ${controller.formatMoney(newAmount)} successfully!'),
                    backgroundColor: AppColors.lime,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.lime),
            child: Text('Save', style: AppText.body.copyWith(color: AppColors.ink)),
          ),
        ],
      ),
    );
  }

  void _showDeleteSavingsDialog(BuildContext context, GoalSaverController controller, SavingsLog log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final textColor = isDark ? AppColors.white : AppColors.lightText;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        title: Text(
          'Delete Savings Record',
          style: AppText.titleMedium.copyWith(color: textColor),
        ),
        content: Text(
          'Are you sure you want to delete this savings log of ${controller.formatMoney(log.amount)}?',
          style: AppText.body.copyWith(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppText.body.copyWith(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () {
              controller.deleteSavingsLog(log);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Savings record of ${controller.formatMoney(log.amount)} deleted!'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: AppText.body.copyWith(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteGoalDialog(BuildContext context, GoalSaverController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final textColor = isDark ? AppColors.white : AppColors.lightText;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        title: Text(
          'Delete Product',
          style: AppText.titleMedium.copyWith(color: textColor),
        ),
        content: Text(
          'Are you sure you want to delete "${goal.title}"? All savings logs for this product will be lost.',
          style: AppText.body.copyWith(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppText.body.copyWith(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () async {
              await controller.deleteGoal(goal);
              if (ctx.mounted) Navigator.pop(ctx); // Close dialog
              if (context.mounted) Navigator.maybePop(context); // Close sheet safely
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: AppText.body.copyWith(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final dividerColor = isDark ? AppColors.glass : const Color(0xFF000000).withValues(alpha: 0.08);

    // Find the latest version of this goal in the controller
    final matchingGoals = controller.allActiveGoals
        .where((g) => g.id == goal.id)
        .toList();

    // If goal is deleted or not found among active goals — auto-dismiss
    final currentGoal = matchingGoals.isNotEmpty ? matchingGoals.first : null;

    if (currentGoal == null) {
      // Schedule a post-frame pop to avoid calling Navigator during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    final progress = currentGoal.progress;
    final moneyNeeded = currentGoal.moneyNeeded;
    final goalLogs = controller.history.where((log) => log.goalId == currentGoal.id).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.muted.withValues(alpha: 0.3)
                      : AppColors.lightMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Product Photo Hero ────────────────────────────────────────
            if (currentGoal.productPhotoUrl != null && currentGoal.productPhotoUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildProductPhoto(currentGoal.productPhotoUrl!, currentGoal.color, isDark),
              ),
            // Header Row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: currentGoal.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(currentGoal.icon, color: currentGoal.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentGoal.title,
                        style: AppText.titleLarge.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentGoal.categoryName,
                        style: AppText.caption.copyWith(color: mutedColor),
                      ),
                    ],
                  ),
                ),
                GoalStatusPill(goal: currentGoal),
              ],
            ),
            const SizedBox(height: 16),
            // Info Grid - Show remaining + saved prominently
            Row(
              children: [
                Expanded(
                  child: GoalMetaTile(
                    icon: Icons.payments_rounded,
                    label: 'Money Needed',
                    value: controller.showBalance
                        ? controller.formatMoney(moneyNeeded)
                        : '${controller.currencySymbol} •••',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GoalMetaTile(
                    icon: Icons.savings_rounded,
                    label: 'Saved',
                    value: controller.showBalance
                        ? controller.formatMoney(currentGoal.saved)
                        : '${controller.currencySymbol} •••',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GoalMetaTile(
                    icon: Icons.schedule_rounded,
                    label: 'Deadline',
                    value: currentGoal.timeLeft,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GoalMetaTile(
                    icon: Icons.trending_up_rounded,
                    label: 'Progress',
                    value: currentGoal.progressPercent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress,
                backgroundColor: AppColors.muted.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(currentGoal.color),
              ),
            ),
            const SizedBox(height: 8),
            // Show exact remaining/completed amounts
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 12, color: mutedColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    currentGoal.completed
                        ? 'Goal completed!${currentGoal.excessSaved > 0 ? " +${controller.showBalance ? controller.formatMoney(currentGoal.excessSaved) : "•••"} in excess savings (target: ${controller.showBalance ? controller.formatMoney(currentGoal.target) : "•••"})" : " You saved ${controller.showBalance ? controller.formatMoney(currentGoal.saved) : "•••"}"}'
                        : 'Remaining: ${controller.showBalance ? controller.formatMoney(moneyNeeded) : "•••"} of ${controller.showBalance ? controller.formatMoney(currentGoal.target) : "•••"} needed',
                    style: TextStyle(fontSize: 11, color: mutedColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            MilestoneIndicator(goal: currentGoal),

            const SizedBox(height: 16),
            // Option buttons: Edit and Delete
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final goalToEdit = currentGoal;
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          showAddGoalSheet(context, existingGoal: goalToEdit);
                        }
                      });
                    },
                    icon: const Icon(Icons.edit_rounded, color: AppColors.lime, size: 18),
                    label: const Text('Edit Product', style: TextStyle(color: AppColors.lime)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.lime),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteGoalDialog(context, controller),
                    icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 18),
                    label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            Divider(color: dividerColor, height: 24),

            // History Title & Add button
            Row(
              children: [
                Text(
                  'Savings History',
                  style: AppText.section.copyWith(fontSize: 16, color: textColor),
                ),
                const Spacer(),
                Pressable(
                  onTap: () {
                    showProductivitySheet(
                      context,
                      title: 'Add Savings',
                      icon: Icons.savings_rounded,
                      initialGoal: currentGoal,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.lime.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: AppColors.lime, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lime),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Log items rendered inline (not in Expanded/ListView to prevent overflow)
            if (goalLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No savings entries yet.',
                    style: AppText.bodyMuted.copyWith(color: mutedColor),
                  ),
                ),
              )
            else
              ...goalLogs.map((log) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: AppColors.lime, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.showBalance
                                ? controller.formatMoney(log.amount)
                                : '${controller.currencySymbol} •••',
                            style: AppText.body.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.formattedDate,
                            style: AppText.caption.copyWith(color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: mutedColor, size: 18),
                      onPressed: () => _showEditSavingsDialog(context, controller, log),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 18),
                      onPressed: () => _showDeleteSavingsDialog(context, controller, log),
                    ),
                  ],
                ),
              )),
            const SizedBox(height: 10),
            // Complete / Undo toggle with celebration overlay
            SizedBox(
              width: double.infinity,
              child: Pressable(
                onTap: () {
                  if (currentGoal.completed) {
                    controller.undoCompletion(currentGoal);
                  } else {
                    // Show celebration + confetti before marking complete
                    CelebrationOverlay.show(
                      context,
                      message: 'You completed "${currentGoal.title}"! 🎉',
                      onTap: () {
                        controller.markCompleted(currentGoal);
                      },
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.lime.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.lime, width: 1.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        currentGoal.completed ? Icons.undo_rounded : Icons.check_circle_rounded,
                        color: AppColors.lime,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentGoal.completed ? 'Undo Completion' : 'Mark Completed',
                        style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a product hero photo shown at the top of the details sheet.
  Widget _buildProductPhoto(String photoUrl, Color categoryColor, bool isDark) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          photoUrl.startsWith('http')
              ? Image.network(photoUrl, fit: BoxFit.cover,
                  errorBuilder: (_, e, error) => _buildPhotoFallback(categoryColor))
              : Image.file(File(photoUrl), fit: BoxFit.cover,
                  errorBuilder: (_, e, error) => _buildPhotoFallback(categoryColor)),
          // Gradient overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    (isDark ? AppColors.panel : Colors.white).withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fallback when the photo fails to load.
  Widget _buildPhotoFallback(Color categoryColor) {
    return Container(
      color: categoryColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.image_not_supported_rounded, size: 48, color: categoryColor.withValues(alpha: 0.4)),
      ),
    );
  }
}
