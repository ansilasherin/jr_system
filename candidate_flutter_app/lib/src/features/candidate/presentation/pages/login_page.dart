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

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: .35),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _loginRole == 'hr' ? 'HR Login' : 'Candidate Login',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Continue to candidate matching or HR review.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
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
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
                                    ? 'Login as HR'
                                    : 'Login as Candidate',
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
                        child: const Text('Create candidate account'),
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
