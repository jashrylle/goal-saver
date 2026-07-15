import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
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
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(metrics.pagePadding, 18, metrics.pagePadding, 100),
                      sliver: SliverList.list(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.lime),
                              ),
                              const Expanded(
                                child: DashboardHeader(
                                  eyebrow: 'Settings',
                                  title: 'Manage Categories',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Predefined Categories',
                            style: AppText.adaptive(context, AppText.titleMedium),
                          ),
                          const SizedBox(height: 12),
                          ...GoalCategory.predefined.map((category) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassCard(
                                  child: ListTile(
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: category.color.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        category.icon,
                                        color: category.color,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      category.label,
                                      style: AppText.body.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      category.description,
                                      style: AppText.caption.copyWith(color: mutedColor),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Pressable(
                                          onTap: () => _showUnlockCategoryDialog(context, category),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppColors.lime.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.lime.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.lock_open_rounded, color: AppColors.lime, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Unlock',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.lime),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                'Custom Categories',
                                style: AppText.adaptive(context, AppText.titleMedium),
                              ),
                              const Spacer(),
                              Pressable(
                                onTap: () => _showAddCategoryDialog(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.lime.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.lime),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_rounded, color: AppColors.lime, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Add New',
                                        style: AppText.caption.copyWith(
                                          color: AppColors.lime,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (controller.customCategories.isEmpty)
                            GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'No custom categories yet. Tap "Add New" to create one!',
                                    style: AppText.body.copyWith(
                                      color: mutedColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...controller.customCategories.map((category) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GlassCard(
                                    child: ListTile(
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: category.color.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          category.icon,
                                          color: category.color,
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        category.label,
                                        style: AppText.body.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        category.description,
                                        style: AppText.caption.copyWith(color: mutedColor),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () => _showEditCategoryDialog(context, category),
                                            icon: const Icon(
                                              Icons.edit_rounded,
                                              color: AppColors.lime,
                                              size: 20,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _showDeleteCategoryDialog(context, category),
                                            icon: const Icon(
                                              Icons.delete_rounded,
                                              color: Colors.redAccent,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )),
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

  Color _dialogBgColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.panel : Colors.white;
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    IconData selectedIcon = Icons.category_rounded;
    Color selectedColor = AppColors.lime;
    final ctrl = context.read<GoalSaverController>();
    final bgColor = _dialogBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            'Add Custom Category',
            style: AppText.titleMedium.copyWith(color: textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: textColor),
                  decoration: goalInputDecoration('Category Name', Icons.text_fields_rounded, context: ctx),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: TextStyle(color: textColor),
                  decoration: goalInputDecoration('Description', Icons.description_rounded, context: ctx),
                ),
                const SizedBox(height: 16),
                Text('Select Icon', style: AppText.caption.copyWith(color: AppColors.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Icons.category_rounded,
                    Icons.star_rounded,
                    Icons.favorite_rounded,
                    Icons.work_rounded,
                    Icons.home_rounded,
                    Icons.shopping_bag_rounded,
                    Icons.sports_rounded,
                    Icons.music_note_rounded,
                  ].map((icon) {
                    final isSelected = selectedIcon == icon;
                    return Pressable(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.lime.withValues(alpha: 0.2)
                              : (isDark
                                  ? AppColors.ink.withValues(alpha: 0.3)
                                  : const Color(0xFF000000).withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.lime : AppColors.muted.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(icon, color: isSelected ? AppColors.lime : AppColors.muted),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Select Color', style: AppText.caption.copyWith(color: AppColors.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    AppColors.lime,
                    const Color(0xFF00D9FF),
                    const Color(0xFFFF6B9D),
                    const Color(0xFFFFD93D),
                    const Color(0xFF9D4EDD),
                    const Color(0xFF52B788),
                    const Color(0xFFFFB703),
                    const Color(0xFF4CC9F0),
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return Pressable(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppText.body.copyWith(color: AppColors.muted)),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final newCategory = GoalCategory.custom(
                  name: name.toLowerCase().replaceAll(' ', '_'),
                  label: name,
                  icon: selectedIcon,
                  color: selectedColor,
                  description: descriptionController.text.trim(),
                );
                await ctrl.addCustomCategory(newCategory);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Category "${newCategory.label}" created!'),
                      backgroundColor: AppColors.lime,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.lime),
              child: Text('Create', style: AppText.body.copyWith(color: AppColors.ink)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, GoalCategory category) {
    final nameController = TextEditingController(text: category.label);
    final descriptionController = TextEditingController(text: category.description);
    IconData selectedIcon = category.icon;
    Color selectedColor = category.color;
    final ctrl = context.read<GoalSaverController>();
    final bgColor = _dialogBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            'Edit Category',
            style: AppText.titleMedium.copyWith(color: textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: textColor),
                  decoration: goalInputDecoration('Category Name', Icons.text_fields_rounded, context: ctx),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: TextStyle(color: textColor),
                  decoration: goalInputDecoration('Description', Icons.description_rounded, context: ctx),
                ),
                const SizedBox(height: 16),
                Text('Select Icon', style: AppText.caption.copyWith(color: AppColors.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Icons.category_rounded,
                    Icons.star_rounded,
                    Icons.favorite_rounded,
                    Icons.work_rounded,
                    Icons.home_rounded,
                    Icons.shopping_bag_rounded,
                    Icons.sports_rounded,
                    Icons.music_note_rounded,
                  ].map((icon) {
                    final isSelected = selectedIcon == icon;
                    return Pressable(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.lime.withValues(alpha: 0.2)
                              : (isDark
                                  ? AppColors.ink.withValues(alpha: 0.3)
                                  : const Color(0xFF000000).withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.lime : AppColors.muted.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(icon, color: isSelected ? AppColors.lime : AppColors.muted),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Select Color', style: AppText.caption.copyWith(color: AppColors.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    AppColors.lime,
                    const Color(0xFF00D9FF),
                    const Color(0xFFFF6B9D),
                    const Color(0xFFFFD93D),
                    const Color(0xFF9D4EDD),
                    const Color(0xFF52B788),
                    const Color(0xFFFFB703),
                    const Color(0xFF4CC9F0),
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return Pressable(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppText.body.copyWith(color: AppColors.muted)),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final updated = GoalCategory.custom(
                  name: name.toLowerCase().replaceAll(' ', '_'),
                  label: name,
                  icon: selectedIcon,
                  color: selectedColor,
                  description: descriptionController.text.trim(),
                );
                await ctrl.updateCustomCategory(category, updated);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category updated successfully!'),
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
      ),
    );
  }

  void _showUnlockCategoryDialog(BuildContext context, GoalCategory category) {
    final ctrl = context.read<GoalSaverController>();
    final bgColor = _dialogBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    
    // Check if already exists as custom
    final alreadyExists = ctrl.customCategories.any((c) => c.name == category.name);
    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${category.label}" is already unlocked and editable!'),
          backgroundColor: AppColors.lime,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        title: Text(
          'Unlock "${category.label}"?',
          style: AppText.titleMedium.copyWith(color: textColor),
        ),
        content: Text(
          'Unlocking this category will add it to custom categories so you can edit its name, icon, and color.',
          style: AppText.body.copyWith(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppText.body.copyWith(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () async {
              await ctrl.addCustomCategory(GoalCategory.custom(
                name: category.name,
                label: category.label,
                icon: category.icon,
                color: category.color,
                description: category.description,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${category.label}" unlocked and ready to edit!'),
                    backgroundColor: AppColors.lime,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.lime),
            child: Text('Unlock', style: AppText.body.copyWith(color: AppColors.ink)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, GoalCategory category) {
    final ctrl = context.read<GoalSaverController>();
    final bgColor = _dialogBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        title: Text(
          'Delete Category',
          style: AppText.titleMedium.copyWith(color: textColor),
        ),
        content: Text(
          'Are you sure you want to delete "${category.label}"? Goals using this category will switch to Technology.',
          style: AppText.body.copyWith(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppText.body.copyWith(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () async {
              await ctrl.deleteCustomCategory(category);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "${category.label}" deleted'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: AppText.body.copyWith(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}
