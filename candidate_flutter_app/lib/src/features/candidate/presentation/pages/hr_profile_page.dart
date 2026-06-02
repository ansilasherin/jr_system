import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/candidate_user.dart';
import '../../domain/models/profile_summary.dart';
import '../view_models/profile_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/logout_controls.dart';
import '../widgets/panel_card.dart';

class HrProfilePage extends StatefulWidget {
  const HrProfilePage({super.key});

  static const route = '/hr-profile';

  @override
  State<HrProfilePage> createState() => _HrProfilePageState();
}

class _HrProfilePageState extends State<HrProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadHrProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final profile = vm.hrProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('HR Profile')),
      body: RefreshIndicator(
        onRefresh: vm.loadHrProfile,
        child:
            vm.loading && profile == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (vm.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          vm.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (profile == null)
                      const EmptyState(
                        title: 'Profile unavailable',
                        message: 'Pull to refresh your HR profile.',
                      )
                    else ...[
                      _HrHeader(user: profile.user),
                      const SizedBox(height: 14),
                      _JobStats(profile: profile),
                      const SizedBox(height: 14),
                      _PostedJobsSection(jobs: profile.postedJobs),
                    ],
                    const SizedBox(height: 32),
                    const ProfileLogoutSection(),
                    const SizedBox(height: 16),
                  ],
                ),
      ),
    );
  }
}

class _HrHeader extends StatelessWidget {
  const _HrHeader({required this.user});

  final CandidateUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PanelCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          final avatar = CircleAvatar(
            radius: 42,
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            backgroundImage:
                user.profileUrl == null || user.profileUrl!.isEmpty
                    ? null
                    : NetworkImage(user.profileUrl!),
            child:
                user.profileUrl == null || user.profileUrl!.isEmpty
                    ? Text(
                      _initials(user.fullName),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    )
                    : null,
          );
          final content = Expanded(
            child: Column(
              crossAxisAlignment:
                  wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(
                  user.fullName.isEmpty ? 'HR Manager' : user.fullName,
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'JR System',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: wide ? WrapAlignment.start : WrapAlignment.center,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.mail_outline_rounded, size: 16),
                      label: Text(user.email),
                    ),
                    Chip(
                      avatar: const Icon(Icons.call_outlined, size: 16),
                      label: Text(_display(user.phone)),
                    ),
                    const Chip(
                      avatar: Icon(Icons.badge_outlined, size: 16),
                      label: Text('HR Manager'),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (wide) {
            return Row(children: [avatar, const SizedBox(width: 18), content]);
          }
          return Column(
            children: [
              avatar,
              const SizedBox(height: 14),
              Row(children: [content]),
            ],
          );
        },
      ),
    );
  }
}

class _JobStats extends StatelessWidget {
  const _JobStats({required this.profile});

  final HrProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 3 : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 3.4 : 1.9,
          children: [
            _StatCard(
              label: 'Total Jobs Posted',
              value: profile.totalJobsPosted.toString(),
              icon: Icons.work_outline_rounded,
            ),
            _StatCard(
              label: 'Active Jobs',
              value: profile.activeJobs.toString(),
              icon: Icons.play_circle_outline_rounded,
            ),
            _StatCard(
              label: 'Closed Jobs',
              value: profile.closedJobs.toString(),
              icon: Icons.task_alt_rounded,
            ),
          ],
        );
      },
    );
  }
}

class _PostedJobsSection extends StatelessWidget {
  const _PostedJobsSection({required this.jobs});

  final List<HrPostedJobSummary> jobs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posted Jobs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (jobs.isEmpty)
          const EmptyState(
            title: 'No posted jobs',
            message: 'Jobs posted by your company will appear here.',
          )
        else
          ...jobs.map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PanelCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      child: Icon(
                        job.status == 'active'
                            ? Icons.work_outline_rounded
                            : Icons.task_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${job.company} • ${job.location}'),
                          const SizedBox(height: 8),
                          Text('${job.applicationCount} applications'),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(job.status),
                      backgroundColor:
                          job.status == 'active'
                              ? Colors.green.withValues(alpha: .12)
                              : Colors.blueGrey.withValues(alpha: .12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PanelCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _display(String? value, {String fallback = 'Not specified'}) {
  if (value == null || value.trim().isEmpty) return fallback;
  return value.trim();
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'H';
  return parts
      .take(2)
      .map((part) => part.characters.first)
      .join()
      .toUpperCase();
}
