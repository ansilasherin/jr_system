import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/brand_mark.dart';
import 'candidate_shell_page.dart';
import 'hr_shell_page.dart';
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            final form = _LoginFormPanel(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              loginRole: _loginRole,
              loading: vm.loading,
              error: vm.error,
              onRoleChanged: (role) => setState(() => _loginRole = role),
              onSubmit: _submit,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 24,
                vertical: wide ? 36 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child:
                      wide
                          ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(child: _SmartHireHero()),
                              const SizedBox(width: 34),
                              Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 430,
                                  ),
                                  child: form,
                                ),
                              ),
                            ],
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(
                                child: SmartHireLockup(
                                  center: true,
                                  markSize: 64,
                                ),
                              ),
                              const SizedBox(height: 24),
                              form,
                            ],
                          ),
                ),
              ),
            );
          },
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
      user?.role == 'hr' ? HrShellPage.route : CandidateShellPage.route,
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.loginRole,
    required this.loading,
    required this.error,
    required this.onRoleChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String loginRole;
  final bool loading;
  final String? error;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loginRole == 'hr' ? 'HR sign in' : 'Candidate sign in',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loginRole == 'hr'
                ? 'Review candidates, MCQ results, and hiring decisions.'
                : 'Find matched roles and track every application.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),
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
            selected: {loginRole},
            onSelectionChanged:
                loading ? null : (selection) => onRoleChanged(selection.first),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Email',
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
            controller: passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!loading) onSubmit();
            },
            decoration: const InputDecoration(
              hintText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            validator:
                (value) =>
                    value != null && value.length >= 4
                        ? null
                        : 'Enter your password',
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: loading ? null : onSubmit,
            child:
                loading
                    ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(loginRole == 'hr' ? 'Sign in as HR' : 'Sign in'),
          ),
          const SizedBox(height: 12),
          if (loginRole != 'hr')
            TextButton(
              onPressed:
                  loading
                      ? null
                      : () =>
                          Navigator.of(context).pushNamed(RegisterPage.route),
              child: const Text('Create an account'),
            ),
        ],
      ),
    );
  }
}

class _SmartHireHero extends StatelessWidget {
  const _SmartHireHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SmartHireLockup(markSize: 64),
        const SizedBox(height: 34),
        Text(
          'Hire smarter. Get hired faster.',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'SmartHire connects candidate profiles, CV skills, job matches, MCQ screening, and HR decisions in one focused workflow.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 26),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _FeaturePill(
              icon: Icons.manage_search_rounded,
              label: 'AI job matching',
            ),
            _FeaturePill(
              icon: Icons.description_outlined,
              label: 'CV skill extraction',
            ),
            _FeaturePill(
              icon: Icons.fact_check_outlined,
              label: 'MCQ screening',
            ),
          ],
        ),
        const SizedBox(height: 30),
        _HiringFlowPreview(),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: theme.colorScheme.primary.withValues(alpha: .08),
      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: .14)),
    );
  }
}

class _HiringFlowPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      (Icons.person_search_outlined, 'Profile'),
      (Icons.auto_awesome_rounded, 'Match'),
      (Icons.assignment_turned_in_outlined, 'Apply'),
      (Icons.handshake_outlined, 'Hire'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              theme.brightness == Brightness.light
                  ? const Color(0xffedf0f7)
                  : const Color(0xff282b3a),
        ),
      ),
      child: Row(
        children:
            steps.map((step) {
              final index = steps.indexOf(step);
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: .12),
                            foregroundColor: theme.colorScheme.primary,
                            child: Icon(step.$1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.$2,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index != steps.length - 1)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
