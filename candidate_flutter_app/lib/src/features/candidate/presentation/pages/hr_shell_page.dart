import 'package:flutter/material.dart';

import '../widgets/app_bottom_navigation.dart';
import 'hr_dashboard_page.dart';
import 'hr_home_page.dart';
import 'hr_profile_page.dart';

class HrShellPage extends StatefulWidget {
  const HrShellPage({super.key});

  static const route = '/hr';

  @override
  State<HrShellPage> createState() => _HrShellPageState();
}

class _HrShellPageState extends State<HrShellPage> {
  int _selectedIndex = 0;

  static const _pages = [
    HrHomePage(),
    HrDashboardPage(showAppBar: false),
    HrProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected:
            (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
