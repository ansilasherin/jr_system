import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import 'candidate_dashboard_page.dart';
import 'hr_dashboard_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const route = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _loginRole = 'user';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: .3),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'JR Recruitment',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _loginRole == 'hr' ? 'HR sign in' : 'Candidate sign in',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Access your dashboard with your registered email.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'user',
                          icon: Icon(Icons.person_outline_rounded),
                          label: Text('Candidate'),
                        ),
                        ButtonSegment(
                          value: 'hr',
                          icon: Icon(Icons.badge_outlined),
                          label: Text('HR'),
                        ),
                      ],
                      selected: {_loginRole},
                      onSelectionChanged:
                          vm.loading
                              ? null
                              : (selection) {
                                setState(() {
                                  _loginRole = selection.first;
                                });
                              },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator:
                          (value) =>
                              value != null && value.contains('@')
                                  ? null
                                  : 'Enter a valid email',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!vm.loading) _submit();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator:
                          (value) =>
                              value != null && value.length >= 4
                                  ? null
                                  : 'Enter your password',
                    ),
                    if (vm.error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        vm.error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: vm.loading ? null : _submit,
                      child:
                          vm.loading
                              ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                _loginRole == 'hr'
                                    ? 'Sign in as HR'
                                    : 'Sign in',
                              ),
                    ),
                    const SizedBox(height: 10),
                    if (_loginRole != 'hr')
                      TextButton(
                        onPressed:
                            vm.loading
                                ? null
                                : () => Navigator.of(
                                  context,
                                ).pushNamed(RegisterPage.route),
                        child: const Text('Create an account'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthViewModel>().login(
      _emailController.text.trim(),
      _passwordController.text,
      expectedRole: _loginRole,
    );
    if (!mounted || !ok) return;
    final user = context.read<AuthViewModel>().user;
    Navigator.of(context).pushReplacementNamed(
      user?.role == 'hr' ? HrDashboardPage.route : CandidateDashboardPage.route,
    );
  }
}
