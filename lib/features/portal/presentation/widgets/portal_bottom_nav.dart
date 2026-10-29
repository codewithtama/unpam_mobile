import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Bilah navigasi bawah untuk berpindah antar portal Mentari, MyUnpam,
/// Akademik Native Hub, dan Asisten AI The PAMs.
class PortalBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const PortalBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex.clamp(0, 3),
      backgroundColor: Colors.white,
      elevation: 3,
      indicatorColor: AppTheme.primaryLight.withOpacity(0.15),
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded, color: AppTheme.primaryBlue),
          label: 'Mentari',
        ),
        NavigationDestination(
          icon: Icon(Icons.badge_outlined),
          selectedIcon: Icon(Icons.badge_rounded, color: AppTheme.primaryBlue),
          label: 'MyUnpam',
        ),
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryBlue),
          label: 'Akademik',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome, color: AppTheme.accentGold),
          label: 'The PAMs AI',
        ),
      ],
    );
  }
}
