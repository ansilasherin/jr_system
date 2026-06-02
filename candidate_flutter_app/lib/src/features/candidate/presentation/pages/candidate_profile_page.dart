import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/application_model.dart';
import '../../domain/models/candidate_user.dart';
import '../../domain/models/job_model.dart';
import '../view_models/profile_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/logout_controls.dart';
import '../widgets/panel_card.dart';
import 'job_detail_page.dart';

class CandidateProfilePage extends StatefulWidget {
  const CandidateProfilePage({super.key});

  static const route = '/candidate-profile';

  @override
  State<CandidateProfilePage> createState() => _CandidateProfilePageState();
}

class _CandidateProfilePageState extends State<CandidateProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadCandidateProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final profile = vm.candidateProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: vm.loadCandidateProfile,
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
                        message: 'Pull to refresh your profile details.',
                      )
                    else ...[
                      _CandidateHeader(user: profile.user),
                      const SizedBox(height: 14),
                      _ProfileDetails(user: profile.user),
                      const SizedBox(height: 14),
                      _AppliedJobsSection(applications: profile.applications),
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

class _CandidateHeader extends StatelessWidget {
  const _CandidateHeader({required this.user});

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
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
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
          final details = Expanded(
            child: Column(
              crossAxisAlignment:
                  wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(
                  user.fullName.isEmpty ? 'Candidate' : user.fullName,
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: wide ? WrapAlignment.start : WrapAlignment.center,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.school_outlined, size: 16),
                      label: Text(_display(user.course, fallback: 'Education')),
                    ),
                    Chip(
                      avatar: const Icon(Icons.location_on_outlined, size: 16),
                      label: const Text('Location not set'),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (wide) {
            return Row(children: [avatar, const SizedBox(width: 18), details]);
          }
          return Column(
            children: [
              avatar,
              const SizedBox(height: 14),
              Row(children: [details]),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.user});

  final CandidateUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skills = user.skills;
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _InfoTile(
            icon: Icons.call_outlined,
            label: 'Phone Number',
            value: _display(user.phone),
          ),
          _InfoTile(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: 'Not specified',
          ),
          _InfoTile(
            icon: Icons.school_outlined,
            label: 'Education',
            value: _display(user.course),
          ),
          const _InfoTile(
            icon: Icons.work_outline_rounded,
            label: 'Experience',
            value: 'Fresher / Not specified',
          ),
          const SizedBox(height: 8),
          Text(
            'Skills',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (skills.isEmpty)
            const Text('No skills added yet.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  skills.map((skill) => Chip(label: Text(skill))).toList(),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  user.cvUrl == null || user.cvUrl!.isEmpty
                      ? null
                      : () => _openResume(user.cvUrl!),
              icon: const Icon(Icons.description_outlined),
              label: Text(user.cvName ?? 'View / Download Resume'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openResume(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _AppliedJobsSection extends StatelessWidget {
  const _AppliedJobsSection({required this.applications});

  final List<ApplicationModel> applications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Applied Jobs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (applications.isEmpty)
          const EmptyState(
            title: 'No applied jobs',
            message: 'Jobs you apply for will appear here.',
          )
        else
          ...applications.map(
            (application) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AppliedJobCard(application: application),
            ),
          ),
      ],
    );
  }
}

class _AppliedJobCard extends StatelessWidget {
  const _AppliedJobCard({required this.application});

  final ApplicationModel application;

  @override
  Widget build(BuildContext context) {
    final appliedDate =
        application.appliedAt == null
            ? 'Not specified'
            : DateFormat('dd MMM yyyy').format(application.appliedAt!);
    return PanelCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openJob(context),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.jobTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(application.company),
                      ],
                    ),
                  ),
                  _StatusChip(status: application.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniChip(
                    icon: Icons.location_on_outlined,
                    label: application.jobLocation ?? 'Not specified',
                  ),
                  _MiniChip(
                    icon: Icons.calendar_today_outlined,
                    label: 'Applied $appliedDate',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openJob(BuildContext context) {
    final job = JobModel(
      id: application.jobId,
      title: application.jobTitle,
      company: application.company,
      location: application.jobLocation ?? '',
      salary: application.jobStipend ?? '',
      experience: application.jobDuration ?? '',
      skills: application.jobSkills,
      description: application.jobDescription ?? '',
      matchScore: application.matchScore,
      applied: true,
      saved: false,
      department: application.jobDepartment,
      deadline: application.jobDeadline,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => JobDetailPage(
              job: job,
              onSave: () async {},
              onApply: () async {},
            ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      'under_review' => Colors.indigo,
      'approved' || 'shortlisted' || 'mcq_completed' => Colors.teal,
      'rejected' => Colors.red,
      'hired' || 'selected' => Colors.green,
      _ => theme.colorScheme.primary,
    };
    final label = switch (status) {
      'approved' || 'mcq_completed' => 'Shortlisted',
      'hired' => 'Selected',
      _ => status.replaceAll('_', ' '),
    };
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color),
      backgroundColor: color.withValues(alpha: .12),
      side: BorderSide(color: color.withValues(alpha: .24)),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
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
  if (parts.isEmpty || parts.first.isEmpty) return 'C';
  return parts
      .take(2)
      .map((part) => part.characters.first)
      .join()
      .toUpperCase();
}
