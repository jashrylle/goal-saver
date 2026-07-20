import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../common_widgets.dart';

/// A bottom sheet that lets users rearrange (via drag handle) and show/hide
/// summary cards on the home dashboard.
Future<void> showCustomizeDashboardSheet(BuildContext context) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bgColor = isDark ? const Color(0xFF0D1A1A) : const Color(0xFFF8F9FA);
  final ctrl = context.read<GoalSaverController>();
  final accentColor = ctrl.accentColor;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDarkLocal = Theme.of(ctx).brightness == Brightness.dark;
          final textColor = isDarkLocal ? AppColors.white : AppColors.lightText;
          final mutedColor = isDarkLocal ? AppColors.muted : AppColors.lightMuted;

          return DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (ctx, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // Drag indicator
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: mutedColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.dashboard_customize_rounded, color: accentColor, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Customize Dashboard',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                          // Reset button
                          if (ctrl.visibleCardOrder.length != kDefaultCardOrder.length ||
                              ctrl.visibleCardOrder.any((c) => c != kDefaultCardOrder[kDefaultCardOrder.indexOf(c)]))
                            Pressable(
                              onTap: () async {
                                await ctrl.resetCardOrder();
                                setSheetState(() {});
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: const Text('Dashboard layout reset to default'),
                                      backgroundColor: accentColor,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Reset',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Drag to reorder · Toggle to show/hide cards',
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Instruction chip
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5FDE9E).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${ctrl.visibleCardOrder.length} of ${kDefaultCardOrder.length} cards visible',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF5FDE9E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Divider
                    Divider(color: mutedColor.withValues(alpha: 0.15), height: 1),
                    const SizedBox(height: 4),
                    // Scrollable content area
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        children: [
                          // ── Visible cards (reorderable) ────────────────────────
                          if (ctrl.visibleCardOrder.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5FDE9E).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'VISIBLE — drag to reorder',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF5FDE9E), letterSpacing: 0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              proxyDecorator: (child, index, animation) => AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) {
                                  return Material(
                                    color: Colors.transparent,
                                    elevation: 4,
                                    shadowColor: Colors.black26,
                                    borderRadius: BorderRadius.circular(16),
                                    child: child,
                                  );
                                },
                                child: child,
                              ),
                              itemCount: ctrl.visibleCardOrder.length,
                              onReorderItem: (oldIndex, newIndex) async {
                                await ctrl.reorderCards(oldIndex, newIndex);
                                setSheetState(() {});
                              },
                              itemBuilder: (ctx, index) {
                                final cardType = ctrl.visibleCardOrder[index];
                                return _DashboardCardItem(
                                  key: ValueKey('visible_${cardType.name}'),
                                  cardType: cardType,
                                  isVisible: true,
                                  orderIndex: index,
                                  showDragHandle: true,
                                  onToggle: () async {
                                    await ctrl.toggleCardVisibility(cardType);
                                    setSheetState(() {});
                                  },
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          // ── Hidden cards (static) ─────────────────────────────
                          if (kDefaultCardOrder.any((c) => ctrl.isCardHidden(c))) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: mutedColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'HIDDEN — tap to show',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: mutedColor, letterSpacing: 0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...kDefaultCardOrder.where((c) => ctrl.isCardHidden(c)).map((cardType) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _DashboardCardItem(
                                  key: ValueKey('hidden_${cardType.name}'),
                                  cardType: cardType,
                                  isVisible: false,
                                  orderIndex: null,
                                  showDragHandle: false,
                                  onToggle: () async {
                                    await ctrl.toggleCardVisibility(cardType);
                                    setSheetState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Done button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: AppColors.ink,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

class _DashboardCardItem extends StatelessWidget {
  final DashboardCardType cardType;
  final bool isVisible;
  final int? orderIndex;
  final bool showDragHandle;
  final VoidCallback onToggle;

  const _DashboardCardItem({
    super.key,
    required this.cardType,
    required this.isVisible,
    this.orderIndex,
    this.showDragHandle = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final accentColor = context.watch<GoalSaverController>().accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFFFFFFFF).withValues(alpha: 0.05)
              : const Color(0xFF000000).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
                : const Color(0xFF000000).withValues(alpha: 0.06),
          ),
        ),
        child: ListTile(
          tileColor: Colors.transparent,
          contentPadding: const EdgeInsets.only(left: 4, right: 8),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle (only shown on visible cards)
              if (showDragHandle)
                ReorderableDragStartListener(
                  index: orderIndex ?? 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.drag_handle_rounded, color: mutedColor, size: 22),
                  ),
                ),
              if (!showDragHandle)
                const SizedBox(width: 12),
              // Card icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isVisible
                      ? accentColor.withValues(alpha: 0.15)
                      : mutedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  cardType.icon,
                  color: isVisible ? accentColor : mutedColor,
                  size: 20,
                ),
              ),
            ],
          ),
          title: Text(
            cardType.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isVisible ? textColor : mutedColor,
            ),
          ),
          subtitle: Text(
            cardType.description,
            style: TextStyle(
              fontSize: 11,
              color: mutedColor.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isVisible && orderIndex != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5FDE9E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${orderIndex! + 1}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF5FDE9E)),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 44,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: isVisible ? accentColor : mutedColor.withValues(alpha: 0.3),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    alignment: isVisible ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
