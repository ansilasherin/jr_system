import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme_view_model.dart';
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
    final themeMode = context.watch<AppThemeViewModel>().themeMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartHire',
      themeMode: themeMode,
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
      seedColor: const Color(0xff4f46e5),
      brightness: brightness,
    );
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? const Color(0xfff7f8fc) : const Color(0xff11131f),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
            isLight ? const Color(0xfff7f8fc) : const Color(0xff11131f),
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : const Color(0xff1b1d2a),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isLight ? const Color(0xffedf0f7) : const Color(0xff262938),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: isLight ? const Color(0xffe5e8f2) : const Color(0xff303344),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(
          color: isLight ? const Color(0xffeaedf5) : const Color(0xff303344),
        ),
        backgroundColor: isLight ? Colors.white : const Color(0xff1b1d2a),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: isLight ? Colors.white : const Color(0xff171927),
        indicatorColor: colorScheme.primary.withValues(alpha: .12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight:
                states.contains(WidgetState.selected)
                    ? FontWeight.w900
                    : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// python manage.py runserver 0.0.0.0:8000
