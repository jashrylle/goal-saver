import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/goal_saver_controller.dart';
import '../../models/goal_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../common_widgets.dart';
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

class _ProductivitySheetState extends State<ProductivitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  SavingsGoal? _selectedGoal;

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
    // We need to use a root navigator context for the nested sheet
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalSaverController>();
    final goals = controller.goals;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    // Compute effective goal WITHOUT mutating _selectedGoal during build!
    // Mutating state in build() breaks Flutter's render cycle and causes black screens.
    // _selectedGoal is only updated through setState() (dropdown onChanged, _openAddProduct).
    final SavingsGoal? currentGoal = _selectedGoal != null &&
        goals.any((g) => g.id == _selectedGoal!.id)
        ? _selectedGoal
        : goals.isNotEmpty
            ? goals.first
            : null;
    final suggested = currentGoal != null
        ? currentGoal.recommendedDeposit
        : 0.0;

    // Top 3 recommended goals (sorted by urgency: least days left first, among incomplete)
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
      child: SingleChildScrollView(
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
                  // "+ Add New Product" inline button
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
                // Empty state with CTA
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
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedColor,
                        ),
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
                // Quick-pick recommended products (urgency-sorted chips)
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
                            onTap: () => setState(() => _selectedGoal = g),
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

                // Product dropdown (full list)
                DropdownButtonFormField<SavingsGoal>(
                  isExpanded: true,
                  value: goals.any((g) => g.id == currentGoal?.id)
                      ? currentGoal
                      : goals.first,
                  dropdownColor: bgColor,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: goalInputDecoration(
                    'All Products',
                    Icons.shopping_bag_rounded,
                    context: context,
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
                    setState(() => _selectedGoal = v);
                    if (v != null) _prefillRecommended(v);
                  },
                ),
                const SizedBox(height: 12),

                // Progress indicator for selected goal
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
                                  backgroundColor:
                                      AppColors.muted.withValues(alpha: 0.2),
                                  valueColor:
                                      AlwaysStoppedAnimation(currentGoal.color),
                                ),
                              ),
                              if (currentGoal.daysLeft > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${currentGoal.daysLeft} days left · ${currentGoal.timeLeft}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: mutedColor,
                                  ),
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
                  style: TextStyle(color: textColor),
                  decoration: goalInputDecoration(
                    'Amount (${controller.currencySymbol})',
                    Icons.payments_rounded,
                    context: context,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter an amount';
                    final num = double.tryParse(v);
                    if (num == null || num <= 0) return 'Enter a valid positive amount';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Quick amount chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (suggested > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            backgroundColor: AppColors.lime.withValues(alpha: 0.12),
                            side: BorderSide(
                              color: AppColors.lime.withValues(alpha: 0.3),
                            ),
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
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () {
                              final currentVal =
                                  double.tryParse(_amountController.text) ?? 0.0;
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
                    onPressed: () {
                      if (_formKey.currentState!.validate() && currentGoal != null) {
                        final amount = double.parse(_amountController.text);
                        // Capture before pop
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        final msg = 'Saved ${controller.formatMoney(amount)} for ${currentGoal.title}!';
                        controller.addSavings(currentGoal, amount);
                        Navigator.pop(context);
                        messenger?.showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: AppColors.lime,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
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
    );
  }
}
