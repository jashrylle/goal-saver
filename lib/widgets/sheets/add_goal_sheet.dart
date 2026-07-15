import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../common_widgets.dart';

/// Opens the add or edit goal bottom sheet.
Future<void> showAddGoalSheet(BuildContext context, {SavingsGoal? existingGoal}) {
  final rootContext = Navigator.of(context, rootNavigator: true).context;
  return showModalBottomSheet(
    context: rootContext,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddGoalSheet(existingGoal: existingGoal),
  );
}

/// Bottom sheet form for creating or editing a savings goal (product).
class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({super.key, this.existingGoal});

  final SavingsGoal? existingGoal;

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _target = 0;
  SavingFrequency _frequency = SavingFrequency.weekly;
  GoalCategory _category = GoalCategory.technology;
  String _timeLeft = '3 months';

  static const _timeOptions = [
    '5 weeks', '6 weeks', '8 weeks', '10 weeks',
    '2 months', '3 months', '4 months', '6 months', '1 year',
  ];

  int _daysFromTimeOption(String option) {
    return switch (option) {
      '5 weeks'  => 35,
      '6 weeks'  => 42,
      '8 weeks'  => 56,
      '10 weeks' => 70,
      '2 months' => 60,
      '3 months' => 90,
      '4 months' => 120,
      '6 months' => 180,
      _          => 365, // 1 year
    };
  }

  @override
  void initState() {
    super.initState();
    final goal = widget.existingGoal;
    if (goal != null) {
      _title = goal.title;
      _target = goal.target;
      _frequency = goal.frequency;
      _category = goal.category;

      // Match daysLeft to closest option
      final days = goal.daysLeft;
      if (days <= 35) {
        _timeLeft = '5 weeks';
      } else if (days <= 42) {
        _timeLeft = '6 weeks';
      } else if (days <= 56) {
        _timeLeft = '8 weeks';
      } else if (days <= 60) {
        _timeLeft = '2 months';
      } else if (days <= 70) {
        _timeLeft = '10 weeks';
      } else if (days <= 90) {
        _timeLeft = '3 months';
      } else if (days <= 120) {
        _timeLeft = '4 months';
      } else if (days <= 180) {
        _timeLeft = '6 months';
      } else {
        _timeLeft = '1 year';
      }
    }
  }

  void _submit(GoalSaverController controller) {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final isEdit = widget.existingGoal != null;
    final String title = _title;

    if (isEdit) {
      final updated = widget.existingGoal!.copyWith(
        title: title,
        target: _target,
        category: _category,
        frequency: _frequency,
        icon: _category.icon,
        color: _category.color,
        dueDate: DateTime.now().add(Duration(days: _daysFromTimeOption(_timeLeft))),
        productName: title,
      );
      controller.updateGoal(updated);
    } else {
      final goal = SavingsGoal(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        saved: 0,
        target: _target,
        icon: _category.icon,
        color: _category.color,
        dueDate: DateTime.now().add(Duration(days: _daysFromTimeOption(_timeLeft))),
        category: _category,
        frequency: _frequency,
        priority: 5,
        productName: title,
        productDescription: '',
        createdDate: DateTime.now(),
      );
      controller.addGoal(goal);
    }

    // Capture messenger BEFORE popping to avoid using a popped context
    final messenger = ScaffoldMessenger.maybeOf(context);
    final snackMessage = isEdit
        ? 'Product "$title" updated successfully!'
        : 'Product "$title" added successfully!';

    Navigator.pop(context);

    messenger?.showSnackBar(
      SnackBar(
        content: Text(snackMessage),
        backgroundColor: AppColors.lime,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingGoal != null;
    final controller = context.read<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    // All available categories: predefined + custom
    final availableCategories = controller.allCategories;

    // Make sure _category is valid in the available list
    if (!availableCategories.any((c) => c.name == _category.name)) {
      _category = availableCategories.first;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
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
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.muted.withValues(alpha: 0.3)
                        : AppColors.lightMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEdit ? 'Edit Product' : 'Add Product',
                style: AppText.titleLarge.copyWith(color: textColor),
              ),
              const SizedBox(height: 6),
              Text(
                isEdit
                    ? 'Update the details of your savings goal'
                    : 'Set up a new product to save for',
                style: AppText.caption.copyWith(color: mutedColor),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _title,
                style: TextStyle(color: textColor),
                decoration: goalInputDecoration(
                  'Product name',
                  Icons.shopping_bag_rounded,
                  context: context,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a product name' : null,
                onSaved: (v) => _title = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: isEdit ? _target.toStringAsFixed(0) : '',
                style: TextStyle(color: textColor),
                decoration: goalInputDecoration(
                  'Target amount (${controller.currencySymbol})',
                  Icons.payments_rounded,
                  context: context,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a target amount';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) return 'Enter a valid positive amount';
                  return null;
                },
                onSaved: (v) => _target = double.tryParse(v?.trim() ?? '0') ?? 0,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SavingFrequency>(
                value: _frequency,
                dropdownColor: bgColor,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: goalInputDecoration(
                  'Saving Frequency',
                  Icons.event_repeat_rounded,
                  context: context,
                ),
                items: SavingFrequency.values
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.label, style: TextStyle(color: textColor)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _frequency = v ?? _frequency),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GoalCategory>(
                value: availableCategories.firstWhere(
                  (c) => c.name == _category.name,
                  orElse: () => availableCategories.first,
                ),
                dropdownColor: bgColor,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: goalInputDecoration(
                  'Category',
                  Icons.category_rounded,
                  context: context,
                ),
                items: availableCategories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Icon(c.icon, color: c.color, size: 16),
                              const SizedBox(width: 8),
                              Text(c.label, style: TextStyle(color: textColor)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _timeLeft,
                dropdownColor: bgColor,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: goalInputDecoration(
                  'Time to reach goal',
                  Icons.schedule_rounded,
                  context: context,
                ),
                items: _timeOptions
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: TextStyle(color: textColor)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _timeLeft = v ?? _timeLeft),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _submit(controller),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lime,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Save Changes' : 'Add Product',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
