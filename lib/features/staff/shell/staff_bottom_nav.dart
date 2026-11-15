import 'package:flutter/material.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/theme.dart';

/// Soft-blended staff bottom nav.
/// Selected tab expands (icon + label); others stay icon-only.
class StaffBottomNav extends StatelessWidget {
  const StaffBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = <_NavItem>[
    _NavItem(
      icon: Icons.today_outlined,
      selectedIcon: Icons.today,
      labelKey: 'NAV.TODAY',
    ),
    _NavItem(
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale,
      labelKey: 'NAV.POS',
    ),
    _NavItem(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      labelKey: 'NAV.MEDICINES',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      labelKey: 'NAV.ORDERS',
    ),
    _NavItem(
      icon: Icons.more_horiz,
      selectedIcon: Icons.more_horiz,
      labelKey: 'NAV.MORE',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.82),
              Colors.white,
            ],
            stops: const <double>[0, 0.35, 1],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 6, 10, bottom > 0 ? bottom : 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              border: Border.all(
                color: Brand.themeColor.withValues(alpha: 0.08),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Brand.themeColor.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                children: <Widget>[
                  for (var i = 0; i < _destinations.length; i++)
                    Expanded(
                      flex: selectedIndex == i ? 18 : 10,
                      child: _NavButton(
                        item: _destinations[i],
                        selected: selectedIndex == i,
                        onTap: () => onDestinationSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = t(item.labelKey);
    final unselected = AppTheme.ink.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: selected ? 10 : 0),
            decoration: BoxDecoration(
              color: selected
                  ? Brand.themeColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 22,
                  color: selected ? Brand.themeColor : unselected,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Brand.themeColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
