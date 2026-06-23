import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../common_widgets.dart';

/// Opens the add-goal bottom sheet.
Future<void> showAddGoalSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AddGoalSheet(),
  );
}

/// Bottom sheet form for creating a new savings goal.
class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({super.key});

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
    '2 months', '3 months', '4 months',
  ];

  int _daysFromTimeOption(String option) {
    return switch (option) {
      '5 weeks'  => 35,
      '6 weeks'  => 42,
      '8 weeks'  => 56,
      '10 weeks' => 70,
      '2 months' => 60,
      '3 months' => 90,
      _          => 120, // 4 months
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Product', style: AppText.titleLarge),
            const SizedBox(height: 14),
            TextFormField(
              style: const TextStyle(color: AppColors.white),
              decoration: goalInputDecoration('Product name', Icons.shopping_bag_rounded),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter a product name' : null,
              onSaved: (v) => _title = v ?? '',
            ),
            const SizedBox(height: 12),
            TextFormField(
              style: const TextStyle(color: AppColors.white),
              decoration: goalInputDecoration('Target amount (₱)', Icons.payments_rounded),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (v == null || double.tryParse(v) == null) ? 'Enter a valid amount' : null,
              onSaved: (v) => _target = double.tryParse(v ?? '0') ?? 0,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SavingFrequency>(
              initialValue: _frequency,
              decoration: goalInputDecoration('Frequency', Icons.event_repeat_rounded),
              items: SavingFrequency.values
                  .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                  .toList(),
              onChanged: (v) => setState(() => _frequency = v ?? _frequency),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GoalCategory>(
              initialValue: _category,
              decoration: goalInputDecoration('Category', Icons.category_rounded),
              items: GoalCategory.predefined
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _timeLeft,
              decoration: goalInputDecoration('Time left', Icons.schedule_rounded),
              items: _timeOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _timeLeft = v ?? _timeLeft),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final goal = SavingsGoal(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      title: _title,
                      saved: 0,
                      target: _target,
                      icon: _category.icon,
                      color: _category.color,
                      dueDate: DateTime.now().add(Duration(days: _daysFromTimeOption(_timeLeft))),
                      category: _category,
                      frequency: _frequency,
                      priority: 5,
                      productName: _title,
                      productDescription: '',
                    );
                    context.read<GoalSaverController>().addGoal(goal);
                    Navigator.pop(context);
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
                  'Add Product',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
