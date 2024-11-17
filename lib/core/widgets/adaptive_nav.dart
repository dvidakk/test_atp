// lib/core/widgets/adaptive_navigation.dart
import 'package:flutter/material.dart';

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class AdaptiveNavigation extends StatelessWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isDesktop;
  final bool isMediumWidth;

  const AdaptiveNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isDesktop = false,
    this.isMediumWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return NavigationRail(
        extended: isMediumWidth,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: items
            .map((item) => NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                ))
            .toList(),
      );
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
