import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import 'candidate_dashboard_page.dart';
import 'hr_dashboard_page.dart';
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
    _safetyTimer = Timer(const Duration(seconds: 6), _forceLoginIfStuck);
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
    String? role;
    try {
      role = await auth.savedSessionRoute().timeout(const Duration(seconds: 5));
    } catch (_) {
      role = null;
    }
    if (!mounted || _navigated) return;

    final route = switch (role) {
      'hr' => HrDashboardPage.route,
      'user' => CandidateDashboardPage.route,
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
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
