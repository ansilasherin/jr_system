import 'package:flutter/material.dart';

import '../widgets/app_bottom_navigation.dart';
import 'applications_page.dart';
import 'candidate_dashboard_page.dart';
import 'candidate_profile_page.dart';

class CandidateShellPage extends StatefulWidget {
  const CandidateShellPage({super.key});

  static const route = '/candidate';

  @override
  State<CandidateShellPage> createState() => _CandidateShellPageState();
}

class _CandidateShellPageState extends State<CandidateShellPage> {
  int _selectedIndex = 0;

  static const _pages = [
    CandidateDashboardPage(showApplicationsAction: false),
    ApplicationsPage(showAppBar: false),
    CandidateProfilePage(),
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
