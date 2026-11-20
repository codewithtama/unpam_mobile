import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Bilah navigasi bawah 100% Native untuk berpindah antar:
/// - Tab 0: Mentari LMS Native Hub
/// - Tab 1: MyUnpam SIAKAD Native Hub (12 Layanan Akademik)
/// - Tab 2: Jadwal & Deadline Tracker Native
/// - Tab 3: Asisten AI The PAMs
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
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded, color: AppTheme.primaryBlue),
          label: 'Jadwal',
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
