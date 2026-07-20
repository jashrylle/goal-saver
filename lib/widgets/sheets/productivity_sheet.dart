import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/goal_saver_controller.dart';
import '../../models/goal_model.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../common_widgets.dart';
import '../achievement_celebration.dart';
import 'add_goal_sheet.dart';

/// Opens the productivity (add savings) bottom sheet.
/// Always uses the root navigator to work correctly from within other bottom sheets.
Future<void> showProductivitySheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  SavingsGoal? initialGoal,
}) {
  final rootContext = Navigator.of(context, rootNavigator: true).context;
  return showModalBottomSheet(
    context: rootContext,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProductivitySheet(
      title: title,
      icon: icon,
      initialGoal: initialGoal,
    ),
  );
}

/// Bottom sheet allowing manual savings deposits with custom amount and quick actions.
class ProductivitySheet extends StatefulWidget {
  const ProductivitySheet({
    super.key,
    required this.title,
    required this.icon,
    this.initialGoal,
  });

  final String title;
  final IconData icon;
  final SavingsGoal? initialGoal;

  @override
  State<ProductivitySheet> createState() => _ProductivitySheetState();
}

class _ProductivitySheetState extends State<ProductivitySheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  SavingsGoal? _selectedGoal;
  String? _validationError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.initialGoal;
    // Pre-fill with recommended deposit if initial goal is provided
    if (widget.initialGoal != null && widget.initialGoal!.recommendedDeposit > 0) {
      _amountController.text = widget.initialGoal!.recommendedDeposit.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(double val) {
    setState(() {
      _amountController.text = val.toStringAsFixed(0);
      _validationError = null;
    });
  }

  /// Pre-fill the amount field with the recommended deposit for the selected goal.
  void _prefillRecommended(SavingsGoal goal) {
    if (goal.recommendedDeposit > 0) {
      _setAmount(goal.recommendedDeposit);
    }
  }

  /// Opens AddGoalSheet to create a product, then waits for it to close
  /// and refreshes the goal list so the new product is pre-selected.
  Future<void> _openAddProduct() async {
    if (!mounted) return;
    await showAddGoalSheet(context);
    // After adding, select the newest goal (inserted at index 0)
    if (mounted) {
      final controller = context.read<GoalSaverController>();
      final goals = controller.goals;
      if (goals.isNotEmpty) {
        setState(() => _selectedGoal = goals.first);
      }
    }
  }

  /// Show a professional Material 3 success dialog after a successful deposit.
  /// Uses [dialogContext] which should be the root navigator context (persists
  /// after the bottom sheet is closed).
  /// Returns a Future that completes when the user dismisses the dialog.
  Future<void> _showSuccessDialog({
    required BuildContext dialogContext,
    required GoalSaverController controller,
    required SavingsGoal goal,
    required double depositedAmount,
    required bool goalCompleted,
  }) async {
    await showDialog(
      context: dialogContext,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.panel
                      : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: goalCompleted
                        ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                        : goal.color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (goalCompleted ? const Color(0xFFFFD700) : AppColors.lime)
                          .withValues(alpha: 0.25),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 32),
                    // Success icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: goalCompleted
                                ? [const Color(0xFFFFD700), const Color(0xFFFFA726)]
                                : [AppColors.lime, const Color(0xFF5FDE9E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (goalCompleted ? const Color(0xFFFFD700) : AppColors.lime)
                                  .withValues(alpha: 0.4),
                              blurRadius: 25,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          goalCompleted ? Icons.emoji_events_rounded : Icons.check_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      goalCompleted ? '🎉 Goal Complete!' : '✅ Savings Added!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.white
                            : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Goal name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        goal.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: goal.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Amount saved
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: (goalCompleted ? const Color(0xFFFFD700) : AppColors.lime)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (goalCompleted ? const Color(0xFFFFD700) : AppColors.lime)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.savings_rounded,
                            size: 18,
                            color: goalCompleted ? const Color(0xFFFFD700) : AppColors.lime,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Deposited: ${controller.formatMoney(depositedAmount)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: goalCompleted ? const Color(0xFFFFD700) : AppColors.lime,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: (goal.saved / goal.target).clamp(0.0, 1.0),
                              backgroundColor: AppColors.muted.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation(goal.color),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(goal.progress * 100).round()}% complete',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${controller.formatMoney(goal.remaining)} remaining',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: goal.remaining <= 0
                                      ? const Color(0xFF00E676)
                                      : AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.muted,
                                side: BorderSide(
                                  color: AppColors.muted.withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Done',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: goalCompleted
                                    ? const Color(0xFFFFD700)
                                    : AppColors.lime,
                                foregroundColor: AppColors.ink,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                goalCompleted ? '🎉 View Goal' : 'View Goal',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show a dialog when the entered deposit exceeds the remaining goal amount.
  /// The dialog shows the allowed amount (remaining) and the excess amount.
  /// Users can choose to deposit only the allowed amount or cancel.
  Future<bool> _showExcessDepositDialog({
    required GoalSaverController controller,
    required SavingsGoal goal,
    required double enteredAmount,
    required double remaining,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final excessAmount = enteredAmount - remaining;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFFFA726).withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA726).withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 28),
                    // Warning icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFA726).withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFFFA726),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      'Deposit Limit Notice',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Explanation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'You entered ${controller.formatMoney(enteredAmount)}, but only ${controller.formatMoney(remaining)} is needed to complete this goal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: mutedColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Amount breakdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Allowed Amount', style: TextStyle(fontSize: 13, color: mutedColor)),
                                Text(
                                  controller.formatMoney(remaining),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.lime,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Excess Amount', style: TextStyle(fontSize: 13, color: mutedColor)),
                                Text(
                                  controller.formatMoney(excessAmount),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFA726),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Entered Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                                Text(
                                  controller.formatMoney(enteredAmount),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFFFA726),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.lime,
                                foregroundColor: AppColors.ink,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Deposit ${controller.formatMoney(remaining)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final goals = controller.allActiveGoals;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    // Compute effective goal WITHOUT mutating _selectedGoal during build!
    final SavingsGoal? currentGoal = _selectedGoal != null &&
        goals.any((g) => g.id == _selectedGoal!.id)
        ? _selectedGoal
        : goals.isNotEmpty
            ? goals.first
            : null;
    final suggested = currentGoal != null
        ? currentGoal.recommendedDeposit
        : 0.0;
    final remaining = currentGoal != null
        ? (currentGoal.target - currentGoal.saved).clamp(0.0, currentGoal.target)
        : 0.0;

    // Top 3 recommended goals (sorted by urgency)
    final recommendedGoals = [...goals]
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    final topRecommended = recommendedGoals
        .where((g) => !g.completed)
        .take(3)
        .toList();

    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.muted.withValues(alpha: 0.3)
                            : AppColors.lightMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(widget.icon, color: AppColors.lime),
                      const SizedBox(width: 10),
                      Text(
                        widget.title,
                        style: AppText.titleLarge.copyWith(color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── Select Product Section ─────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'Select Product',
                        style: AppText.caption.copyWith(color: mutedColor),
                      ),
                      const Spacer(),
                      Pressable(
                        onTap: _openAddProduct,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.lime.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.lime.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: AppColors.lime, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Add New',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.lime,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (goals.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.shopping_bag_rounded,
                              color: AppColors.muted, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'No products yet',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add a product first to start tracking savings.',
                            style: TextStyle(fontSize: 12, color: mutedColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _openAddProduct,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add First Product'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.lime,
                              foregroundColor: AppColors.ink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    if (topRecommended.isNotEmpty && goals.length > 1) ...[
                      Text(
                        'Recommended',
                        style: TextStyle(fontSize: 10, color: mutedColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: topRecommended.map((g) {
                            final isSelected = currentGoal?.id == g.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Pressable(
                                onTap: () => setState(() {
                                  _selectedGoal = g;
                                  _validationError = null;
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? g.color.withValues(alpha: 0.2)
                                        : (isDark
                                            ? const Color(0xFFFFFFFF).withValues(alpha: 0.06)
                                            : const Color(0xFF000000).withValues(alpha: 0.04)),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? g.color
                                          : (isDark
                                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.12)
                                              : const Color(0xFF000000).withValues(alpha: 0.1)),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(g.icon, color: g.color, size: 13),
                                      const SizedBox(width: 5),
                                      Text(
                                        g.title,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? g.color : textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        g.progressPercent,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: g.color.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    DropdownButtonFormField<SavingsGoal>(
                      isExpanded: true,
                      initialValue: currentGoal != null && goals.any((g) => g.id == currentGoal.id)
                          ? goals.firstWhere((g) => g.id == currentGoal.id)
                          : (goals.isNotEmpty ? goals.first : null),
                      dropdownColor: bgColor,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: goalInputDecoration(
                        'All Products',
                        Icons.shopping_bag_rounded,
                      ),
                      items: goals.map((goal) {
                        return DropdownMenuItem<SavingsGoal>(
                          value: goal,
                          child: SizedBox(
                            width: MediaQuery.sizeOf(context).width - 100,
                            child: Row(
                              children: [
                                Icon(goal.icon, color: goal.color, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    goal.title,
                                    style: TextStyle(color: textColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  goal.progressPercent,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: goal.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedGoal = v;
                            _validationError = null;
                          });
                          _prefillRecommended(v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    if (currentGoal != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: currentGoal.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: currentGoal.color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.showBalance
                                        ? '${controller.formatMoney(currentGoal.saved)} / ${controller.formatMoney(currentGoal.target)}'
                                        : '${controller.currencySymbol} ••• / •••',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: currentGoal.color,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      minHeight: 5,
                                      value: currentGoal.progress,
                                      backgroundColor: AppColors.muted.withValues(alpha: 0.2),
                                      valueColor: AlwaysStoppedAnimation(currentGoal.color),
                                    ),
                                  ),
                                  if (currentGoal.daysLeft > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${currentGoal.daysLeft} days left · ${currentGoal.timeLeft}',
                                      style: TextStyle(fontSize: 10, color: mutedColor),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              currentGoal.progressPercent,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: currentGoal.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      'Savings Amount',
                      style: AppText.caption.copyWith(color: mutedColor),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.start,
                      decoration: InputDecoration(
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 4),
                          child: Text(
                            controller.currencySymbol,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        hintText: 'Amount',
                        hintStyle: TextStyle(
                          color: mutedColor.withValues(alpha: 0.4),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                                : const Color(0xFF000000).withValues(alpha: 0.12),
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                                : const Color(0xFF000000).withValues(alpha: 0.12),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.lime, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.error, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFFFFFFFF).withValues(alpha: 0.05)
                            : const Color(0xFF000000).withValues(alpha: 0.03),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        setState(() => _validationError = null);
                      },
                      validator: (v) {
                        if (_validationError != null) return _validationError;
                        if (v == null || v.isEmpty) return 'Enter an amount';
                        final num = double.tryParse(v);
                        if (num == null || num <= 0) return 'Enter a valid positive amount';
                        if (currentGoal != null) {
                          final remaining = (currentGoal.target - currentGoal.saved)
                              .clamp(0.0, currentGoal.target);
                          if (num > remaining) {
                            return 'Deposit exceeds remaining goal amount. Max: ${controller.formatMoney(remaining)}';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (suggested > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                backgroundColor: AppColors.lime.withValues(alpha: 0.12),
                                side: BorderSide(color: AppColors.lime.withValues(alpha: 0.3)),
                                label: Text(
                                  'Suggested (${controller.formatMoney(suggested)})',
                                  style: const TextStyle(
                                    color: AppColors.lime,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: () => _setAmount(suggested),
                              ),
                            ),
                          ...[100, 500, 1000, 5000].map((amt) {
                            // Don't show quick buttons that exceed remaining
                            if (remaining > 0 && amt > remaining) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                backgroundColor: isDark
                                    ? AppColors.muted.withValues(alpha: 0.1)
                                    : AppColors.lightMuted.withValues(alpha: 0.1),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.muted.withValues(alpha: 0.2)
                                      : AppColors.lightMuted.withValues(alpha: 0.2),
                                ),
                                label: Text(
                                  '+${controller.currencySymbol}$amt',
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                onPressed: () {
                                  final currentVal = double.tryParse(_amountController.text) ?? 0.0;
                                  _setAmount(currentVal + amt);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : () async {
                          if (currentGoal == null || !mounted) return;
                          
                          // Prevent double-tap
                          setState(() => _isSaving = true);
                          
                          // Capture messenger before async gaps for safe use in catch block
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          
                          try {
                            // Validate manually to show remaining-capped error
                            final rawAmount = _amountController.text.trim();
                            if (rawAmount.isEmpty) {
                              if (mounted) setState(() { _isSaving = false; _validationError = 'Enter an amount'; });
                              return;
                            }
                            final parsed = double.tryParse(rawAmount);
                            if (parsed == null || parsed <= 0) {
                              if (mounted) setState(() { _isSaving = false; _validationError = 'Enter a valid positive amount'; });
                              return;
                            }
                            
                            final remainingLocal = (currentGoal.target - currentGoal.saved)
                                .clamp(0.0, currentGoal.target);
                            
                            // If the entered amount exceeds the remaining goal amount,
                            // show the excess deposit dialog before proceeding
                            if (parsed > remainingLocal && remainingLocal > 0) {
                              final shouldDeposit = await _showExcessDepositDialog(
                                controller: controller,
                                goal: currentGoal,
                                enteredAmount: parsed,
                                remaining: remainingLocal,
                              );
                              if (!shouldDeposit) {
                                if (mounted) setState(() => _isSaving = false);
                                return; // User cancelled
                              }
                              // Use the capped remaining amount
                              _amountController.text = remainingLocal.toStringAsFixed(0);
                            }

                            final amount = double.parse(_amountController.text);
                            if (amount <= 0) {
                              if (mounted) setState(() => _isSaving = false);
                              return;
                            }
                            
                            // Capture any pending achievements BEFORE the shell can consume them
                            await controller.addSavings(currentGoal, amount);
                            final pendingAchievements = controller.consumePendingAchievements();

                            if (!context.mounted) return;

                            final updatedGoal = controller.latestGoal(currentGoal.id);
                            final goalCompleted = updatedGoal?.completed ?? false;

                            // Capture the root navigator context BEFORE closing the sheet
                            final rootContext = Navigator.of(context, rootNavigator: true).context;

                            // Close the bottom sheet
                            Navigator.pop(context);

                            // Show the success dialog with a brief entrance delay
                            await Future.delayed(const Duration(milliseconds: 300));
                            if (rootContext.mounted) {
                              await _showSuccessDialog(
                                dialogContext: rootContext,
                                controller: controller,
                                goal: updatedGoal ?? currentGoal,
                                depositedAmount: amount,
                                goalCompleted: goalCompleted,
                              );
                              
                              // After the success dialog is fully dismissed,
                              // show achievement popup(s) if any were unlocked
                              if (pendingAchievements.isNotEmpty && rootContext.mounted) {
                                for (final badge in pendingAchievements) {
                                  await Future.delayed(const Duration(milliseconds: 400));
                                  if (!rootContext.mounted) break;
                                  await showDialog(
                                    context: rootContext,
                                    barrierDismissible: false,
                                    barrierColor: Colors.black54,
                                    builder: (ctx) => AchievementCelebration(
                                      badge: badge,
                                      onDismiss: () => Navigator.pop(ctx),
                                    ),
                                  );
                                }
                              }
                            }
                          } catch (e) {
                            debugPrint('Save Money error: $e');
                            if (mounted) {
                              setState(() => _isSaving = false);
                            }
                            messenger?.showSnackBar(
                              SnackBar(
                                content: Text('Failed to save: $e'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _isSaving ? AppColors.lime.withValues(alpha: 0.5) : AppColors.lime,
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                              )
                            : const Text(
                                'Save Money',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
