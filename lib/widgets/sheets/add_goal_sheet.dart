import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal_model.dart';
import '../../models/savings_plan_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/extensions.dart';
import '../common_widgets.dart';

/// Opens the add or edit goal bottom sheet — now a multi-step wizard.
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

/// Multi-step wizard for creating or editing a savings goal.
class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({super.key, this.existingGoal});

  final SavingsGoal? existingGoal;

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 4;

  // Step 1 — Product
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  GoalCategory _category = GoalCategory.technology;

  // Step 2 — Price
  final _priceController = TextEditingController();

  // Step 3 — Timeline
  SavingFrequency _frequency = SavingFrequency.weekly;
  bool _useDuration = true;
  String _durationOption = '3 months';
  DateTime _customDate = DateTime.now().add(const Duration(days: 90));
  DateTime? _pickedCustomDate;

  // Computed plan preview (live)
  bool _isEdit = false;

  static const _durationOptions = [
    '5 weeks', '6 weeks', '8 weeks', '10 weeks',
    '2 months', '3 months', '4 months', '6 months', '1 year',
  ];

  int get _durationDays {
    return switch (_durationOption) {
      '5 weeks' => 35,  '6 weeks' => 42,  '8 weeks' => 56,
      '10 weeks' => 70, '2 months' => 60, '3 months' => 90,
      '4 months' => 120, '6 months' => 180, _ => 365,
    };
  }

  DateTime get _effectiveDueDate => _useDuration
      ? DateTime.now().add(Duration(days: _durationDays))
      : _pickedCustomDate ?? _customDate;

  SavingsPlan? get _previewPlan {
    final price = double.tryParse(_priceController.text) ?? 0;
    if (price <= 0) return null;
    return SavingsPlan.create(
      startDate: DateTime.now(),
      targetDate: _effectiveDueDate,
      frequency: _frequency,
      targetAmount: price,
    );
  }

  @override
  void initState() {
    super.initState();
    final goal = widget.existingGoal;
    if (goal != null) {
      _isEdit = true;
      _titleController.text = goal.title;
      _descriptionController.text = goal.productDescription;
      _category = goal.category;
      _priceController.text = goal.target.toStringAsFixed(0);
      _frequency = goal.frequency;
      _customDate = goal.dueDate ?? DateTime.now().add(const Duration(days: 90));
      _pickedCustomDate = goal.dueDate;
      _useDuration = goal.dueDate == null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _canProceedFromStep {
    switch (_currentStep) {
      case 0:
        return _titleController.text.trim().isNotEmpty;
      case 1:
        final price = double.tryParse(_priceController.text) ?? 0;
        return price > 0;
      case 2:
        return !_useDuration || _effectiveDueDate.isAfter(DateTime.now());
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _submit(GoalSaverController controller) {
    final price = double.tryParse(_priceController.text) ?? 0;
    final title = _titleController.text.trim();
    if (title.isEmpty || price <= 0) return;

    final dueDate = _effectiveDueDate;

    if (_isEdit && widget.existingGoal != null) {
      final updated = widget.existingGoal!.copyWith(
        title: title,
        target: price,
        category: _category,
        frequency: _frequency,
        icon: _category.icon,
        color: _category.color,
        dueDate: dueDate,
        productName: title,
        productDescription: _descriptionController.text.trim(),
        plan: SavingsPlan.create(
          startDate: DateTime.now(),
          targetDate: dueDate,
          frequency: _frequency,
          targetAmount: price,
        ),
      );
      controller.updateGoal(updated);
    } else {
      final goal = SavingsGoal.withPlan(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        target: price,
        icon: _category.icon,
        color: _category.color,
        category: _category,
        frequency: _frequency,
        dueDate: dueDate,
        priority: 5,
        productName: title,
        productDescription: _descriptionController.text.trim(),
      );
      controller.createGoalWithPlan(goal);
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    final snackMessage = _isEdit
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
    final controller = context.read<GoalSaverController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final availableCategories = controller.allCategories;

    if (!availableCategories.any((c) => c.name == _category.name)) {
      _category = availableCategories.first;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Step indicator
          _StepIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            isDark: isDark,
            limeColor: AppColors.lime,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 16),

          // Title + step label
          Row(
            children: [
              Text(
                _isEdit ? 'Edit Product' : 'New Product',
                style: AppText.titleLarge.copyWith(color: textColor),
              ),
              const Spacer(),
              Text(
                'Step ${_currentStep + 1}/$_totalSteps',
                style: AppText.caption.copyWith(color: mutedColor),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _stepSubtitle,
            style: AppText.caption.copyWith(color: mutedColor),
          ),
          const SizedBox(height: 16),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _buildStep1(isDark, textColor, mutedColor, availableCategories),
                _buildStep2(isDark, textColor, mutedColor, controller),
                _buildStep3(isDark, textColor, mutedColor),
                _buildStep4(isDark, textColor, mutedColor, controller),
              ],
            ),
          ),

          // Navigation buttons
          const SizedBox(height: 12),
          _buildNavigation(controller, isDark, textColor),
        ],
      ),
    );
  }

  String get _stepSubtitle => switch (_currentStep) {
    0 => 'What product are you saving for?',
    1 => 'How much does it cost?',
    2 => 'When do you want it?',
    3 => 'Review your savings plan',
    _ => '',
  };

  // ── Step 1: Product ──────────────────────────────────────────────────────

  Widget _buildStep1(bool isDark, Color textColor, Color mutedColor, List<GoalCategory> categories) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            style: TextStyle(color: textColor),
            decoration: goalInputDecoration(
              'Product name',
              Icons.shopping_bag_rounded,
              context: context,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            style: TextStyle(color: textColor),
            maxLines: 2,
            decoration: goalInputDecoration(
              'Description (optional)',
              Icons.description_rounded,
              context: context,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<GoalCategory>(
            value: categories.firstWhere(
              (c) => c.name == _category.name,
              orElse: () => categories.first,
            ),
            dropdownColor: isDark ? AppColors.panel : Colors.white,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: goalInputDecoration(
              'Category',
              Icons.category_rounded,
              context: context,
            ),
            items: categories
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
        ],
      ),
    );
  }

  // ── Step 2: Price ────────────────────────────────────────────────────────

  Widget _buildStep2(bool isDark, Color textColor, Color mutedColor, GoalSaverController controller) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          TextFormField(
            controller: _priceController,
            style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            decoration: goalInputDecoration(
              '0',
              Icons.payments_rounded,
              context: context,
              prefix: Text(
                controller.currencySymbol,
                style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [500, 1000, 5000, 10000, 25000, 50000, 100000]
                .map((amt) => ActionChip(
                      backgroundColor: AppColors.lime.withValues(alpha: 0.12),
                      side: BorderSide(color: AppColors.lime.withValues(alpha: 0.3)),
                      label: Text(
                        '${controller.currencySymbol}${(amt as num).toDouble().money}',
                        style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      onPressed: () {
                        _priceController.text = amt.toString();
                        setState(() {});
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Timeline ─────────────────────────────────────────────────────

  Widget _buildStep3(bool isDark, Color textColor, Color mutedColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle: Duration vs Custom Date
          Row(
            children: [
              Expanded(
                child: _TimelineToggle(
                  label: 'Set Duration',
                  icon: Icons.timer_rounded,
                  selected: _useDuration,
                  onTap: () => setState(() => _useDuration = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimelineToggle(
                  label: 'Pick Date',
                  icon: Icons.calendar_month_rounded,
                  selected: !_useDuration,
                  onTap: () => setState(() => _useDuration = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_useDuration) ...[
            DropdownButtonFormField<String>(
              value: _durationOption,
              dropdownColor: isDark ? AppColors.panel : Colors.white,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: goalInputDecoration(
                'Time to reach goal',
                Icons.schedule_rounded,
                context: context,
              ),
              items: _durationOptions
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: TextStyle(color: textColor)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _durationOption = v ?? _durationOption),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lime.withValues(alpha: 0.2)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _pickedCustomDate ?? DateTime.now().add(const Duration(days: 90)),
                    firstDate: DateTime.now().add(const Duration(days: 7)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: AppColors.lime,
                            brightness: isDark ? Brightness.dark : Brightness.light,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _pickedCustomDate = picked);
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: AppColors.lime, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pickedCustomDate != null
                            ? 'Target: ${_pickedCustomDate!.day}/${_pickedCustomDate!.month}/${_pickedCustomDate!.year}'
                            : 'Tap to select a target date',
                        style: TextStyle(
                          color: _pickedCustomDate != null ? textColor : mutedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.edit_rounded, color: AppColors.lime, size: 16),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Frequency selector
          Text('Saving Frequency', style: AppText.caption.copyWith(color: mutedColor)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SavingFrequency.values.map((f) {
              final isSelected = _frequency == f;
              return ChoiceChip(
                label: Text(
                  f.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.ink : textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _frequency = f),
                selectedColor: AppColors.lime,
                backgroundColor: isDark
                    ? AppColors.muted.withValues(alpha: 0.15)
                    : AppColors.lightMuted.withValues(alpha: 0.15),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Plan Preview ─────────────────────────────────────────────────

  Widget _buildStep4(bool isDark, Color textColor, Color mutedColor, GoalSaverController controller) {
    final plan = _previewPlan;
    final price = double.tryParse(_priceController.text) ?? 0;
    final title = _titleController.text.trim();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Live plan summary card
          if (plan != null && title.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _category.color.withValues(alpha: 0.2),
                    _category.color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _category.color.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  // Product icon + name
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _category.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_category.icon, color: _category.color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppText.titleLarge.copyWith(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // The core plan statement
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.savings_rounded, color: AppColors.lime, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: textColor, fontSize: 14, height: 1.5),
                              children: [
                                TextSpan(
                                  text: 'Save ',
                                ),
                                TextSpan(
                                  text: '${controller.currencySymbol}${plan.currentIntervalAmount.money}',
                                  style: TextStyle(
                                    color: AppColors.lime,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                TextSpan(
                                  text: ' every ${_frequency.label.toLowerCase()} ',
                                ),
                                TextSpan(
                                  text: 'to get your $title',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail breakdown in a card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _PlanDetailRow(
                    icon: Icons.monetization_on_rounded,
                    label: 'Target Price',
                    value: '${controller.currencySymbol}${price.money}',
                    color: textColor,
                    mutedColor: mutedColor,
                  ),
                  Divider(height: 20, color: AppColors.muted.withValues(alpha: 0.15)),
                  _PlanDetailRow(
                    icon: Icons.event_repeat_rounded,
                    label: 'Frequency',
                    value: _frequency.label,
                    color: textColor,
                    mutedColor: mutedColor,
                  ),
                  Divider(height: 20, color: AppColors.muted.withValues(alpha: 0.15)),
                  _PlanDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Target Date',
                    value: '${_effectiveDueDate.day}/${_effectiveDueDate.month}/${_effectiveDueDate.year}',
                    color: textColor,
                    mutedColor: mutedColor,
                  ),
                  Divider(height: 20, color: AppColors.muted.withValues(alpha: 0.15)),
                  _PlanDetailRow(
                    icon: Icons.repeat_rounded,
                    label: 'Total Intervals',
                    value: '${plan.totalIntervals} ${_frequency.label.toLowerCase()}',
                    color: textColor,
                    mutedColor: mutedColor,
                  ),
                  Divider(height: 20, color: AppColors.muted.withValues(alpha: 0.15)),
                  _PlanDetailRow(
                    icon: Icons.emoji_events_rounded,
                    label: 'Per Interval',
                    value: '${controller.currencySymbol}${plan.baseIntervalAmount.money}',
                    color: AppColors.lime,
                    mutedColor: mutedColor,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Empty state — fill in previous steps
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.auto_graph_rounded, size: 64, color: AppColors.muted.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'Fill in the previous steps\nto see your savings plan',
                      style: TextStyle(color: mutedColor, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  Widget _buildNavigation(GoalSaverController controller, bool isDark, Color textColor) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.lime.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Back', style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700)),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: _currentStep == 0 ? 1 : 2,
          child: FilledButton(
            onPressed: _currentStep < _totalSteps - 1
                ? (_canProceedFromStep ? _nextStep : null)
                : _canProceedFromStep
                    ? () => _submit(controller)
                    : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lime,
              foregroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _currentStep < _totalSteps - 1 ? 'Next' : (_isEdit ? 'Save Changes' : 'Create Plan'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helper widgets ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isDark;
  final Color limeColor;
  final Color mutedColor;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.isDark,
    required this.limeColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isActive = i <= currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: i == currentStep ? 28 : 8,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive ? limeColor : mutedColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _TimelineToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TimelineToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.lime.withValues(alpha: 0.12)
              : (isDark ? AppColors.muted.withValues(alpha: 0.08) : AppColors.lightMuted.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.lime : AppColors.muted.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.lime : AppColors.muted, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.lime : textColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color mutedColor;

  const _PlanDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: mutedColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: mutedColor)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
