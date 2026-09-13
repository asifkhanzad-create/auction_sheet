import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'nav_icons.dart';

class FloatingNavItem {
  final NavIconType icon;
  final String label;

  const FloatingNavItem({required this.icon, required this.label});
}

/// Modern floating "card" bottom nav — fully rounded corners, detached
/// from the screen edges with margin + shadow. A single pill indicator
/// slides between equal-width slots (rather than each item fading its
/// own capsule in/out independently, which caused two pills to be
/// visible at once mid-transition).
class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<FloatingNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
  });

  static const _capsuleMargin = 4.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
                // Single sliding indicator, positioned behind the row.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: slotWidth * selectedIndex + _capsuleMargin,
                  top: 0,
                  bottom: 0,
                  width: slotWidth - (_capsuleMargin * 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.lilac,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (i) {
                    final selected = i == selectedIndex;
                    final item = items[i];
                    return _NavItem(
                      icon: item.icon,
                      label: item.label,
                      selected: selected,
                      onTap: () => onSelect(i),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavIconType icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              NavIcon(type: icon, selected: selected, size: 22),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? const Color(0xFF6C63FF) : context.textSecondary,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}