import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/login_page.dart';
import '../view_models/applications_view_model.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/dashboard_view_model.dart';
import '../view_models/hr_dashboard_view_model.dart';
import '../view_models/profile_view_model.dart';

class LogoutIconButton extends StatelessWidget {
  const LogoutIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthViewModel, bool>((vm) => vm.loading);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton.filledTonal(
        tooltip: loading ? 'Logging out' : 'Logout',
        onPressed: loading ? null : () => confirmAndLogout(context),
        icon:
            loading
                ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
                : const Icon(Icons.logout_rounded),
      ),
    );
  }
}

class ProfileLogoutSection extends StatelessWidget {
  const ProfileLogoutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthViewModel, bool>((vm) => vm.loading);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: .32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: .18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Account Session',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Logout from this device and return to the login screen.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: loading ? null : () => confirmAndLogout(context),
            icon:
                loading
                    ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: theme.colorScheme.onError,
                      ),
                    )
                    : const Icon(Icons.logout_rounded),
            label: Text(loading ? 'Logging out' : 'Logout'),
          ),
        ],
      ),
    );
  }
}

Future<void> confirmAndLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          icon: const Icon(Icons.logout_rounded),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        ),
  );

  if (confirmed != true || !context.mounted) return;

  final auth = context.read<AuthViewModel>();
  final profiles = context.read<ProfileViewModel>();
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final success = await auth.logout();
  if (!context.mounted) return;

  if (success) {
    profiles.clearCachedProfiles();
    context.read<DashboardViewModel>().clearCachedDashboard();
    context.read<ApplicationsViewModel>().clearCachedApplications();
    context.read<HrDashboardViewModel>().clearCachedApplications();
    navigator.pushNamedAndRemoveUntil(LoginPage.route, (route) => false);
    return;
  }

  messenger.showSnackBar(
    SnackBar(
      content: Text(auth.error ?? 'Could not logout. Please try again.'),
    ),
  );
}
