import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/brand_mark.dart';
import 'candidate_shell_page.dart';
import 'hr_shell_page.dart';
import 'login_page.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  static const route = '/';

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  bool _navigated = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveSession());
    _safetyTimer = Timer(const Duration(seconds: 8), _forceLoginIfStuck);
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    super.dispose();
  }

  void _forceLoginIfStuck() {
    if (!mounted || _navigated) return;
    _goTo(LoginPage.route);
  }

  Future<void> _resolveSession() async {
    final auth = context.read<AuthViewModel>();
    final minSplash = Future<void>.delayed(const Duration(seconds: 4));
    String? role;
    try {
      role = await auth.savedSessionRoute().timeout(const Duration(seconds: 5));
    } catch (_) {
      role = null;
    }
    await minSplash;
    if (!mounted || _navigated) return;

    final route = switch (role) {
      'hr' => HrShellPage.route,
      'user' => CandidateShellPage.route,
      _ => LoginPage.route,
    };
    _goTo(route);
  }

  void _goTo(String route) {
    if (_navigated || !mounted) return;
    _safetyTimer?.cancel();
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 76),
              const SizedBox(height: 18),
              Text(
                'SmartHire',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AI-powered jobs, applications, and hiring',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              SpinKitWanderingCubes(
                color: theme.colorScheme.primary,
                size: 42,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
