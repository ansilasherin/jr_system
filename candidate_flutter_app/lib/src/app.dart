import 'package:flutter/material.dart';

import 'features/candidate/presentation/pages/applications_page.dart';
import 'features/candidate/presentation/pages/auth_gate_page.dart';
import 'features/candidate/presentation/pages/candidate_dashboard_page.dart';
import 'features/candidate/presentation/pages/candidate_profile_page.dart';
import 'features/candidate/presentation/pages/candidate_shell_page.dart';
import 'features/candidate/presentation/pages/hr_dashboard_page.dart';
import 'features/candidate/presentation/pages/hr_profile_page.dart';
import 'features/candidate/presentation/pages/hr_shell_page.dart';
import 'features/candidate/presentation/pages/login_page.dart';
import 'features/candidate/presentation/pages/register_page.dart';

class CandidatePortalApp extends StatelessWidget {
  const CandidatePortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JR Candidate Portal',
      themeMode: ThemeMode.system,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      initialRoute: AuthGatePage.route,
      routes: {
        AuthGatePage.route: (_) => const AuthGatePage(),
        LoginPage.route: (_) => const LoginPage(),
        RegisterPage.route: (_) => const RegisterPage(),
        CandidateShellPage.route: (_) => const CandidateShellPage(),
        CandidateDashboardPage.route: (_) => const CandidateDashboardPage(),
        CandidateProfilePage.route: (_) => const CandidateProfilePage(),
        HrShellPage.route: (_) => const HrShellPage(),
        HrDashboardPage.route: (_) => const HrDashboardPage(),
        HrProfilePage.route: (_) => const HrProfilePage(),
        ApplicationsPage.route: (_) => const ApplicationsPage(),
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff2563eb),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          brightness == Brightness.light
              ? const Color(0xfff6f8fb)
              : const Color(0xff0f172a),
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
