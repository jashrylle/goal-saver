import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common_widgets.dart';

/// Bottom navigation bar with Home / Analytics / Settings tabs.
class GoalSaverNavBar extends StatelessWidget {
  const GoalSaverNavBar({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark
        ? const Color(0xFF0D1D19).withValues(alpha: 0.95)
        : const Color(0xFFF5FAF1).withValues(alpha: 0.95);
    final navBorder = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
        : const Color(0xFF000000).withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          top: BorderSide(color: navBorder),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(icon: Icons.home_rounded,      label: 'Home',      selected: index == 0, onTap: () => onChanged(0)),
              _NavItem(icon: Icons.analytics_rounded, label: 'Analytics', selected: index == 1, onTap: () => onChanged(1)),
              _NavItem(icon: Icons.settings_rounded,  label: 'Settings',  selected: index == 2, onTap: () => onChanged(2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: selected ? AppColors.lime : AppColors.muted),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.lime : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
