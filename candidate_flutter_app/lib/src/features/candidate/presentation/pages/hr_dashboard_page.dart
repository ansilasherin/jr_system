import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_config.dart';
import '../../domain/models/application_model.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/hr_dashboard_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/panel_card.dart';
import 'login_page.dart';

class HrDashboardPage extends StatefulWidget {
  const HrDashboardPage({super.key});

  static const route = '/hr-dashboard';

  @override
  State<HrDashboardPage> createState() => _HrDashboardPageState();
}

class _HrDashboardPageState extends State<HrDashboardPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HrDashboardViewModel>().loadApplications();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<HrDashboardViewModel>().loadApplications(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HrDashboardViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = vm.successMessage;
      if (message != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        vm.successMessage = null;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Applications'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthViewModel>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(LoginPage.route);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.loadApplications,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatusFilters(vm: vm),
            const SizedBox(height: 14),
            if (vm.loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.error != null)
              Text(
                vm.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (vm.applications.isEmpty)
              const EmptyState(
                title: 'No applications',
                message: 'Candidates who apply to your jobs will appear here.',
              )
            else
              ...vm.applications.map(
                (app) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HrApplicationCard(application: app, vm: vm),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.vm});

  final HrDashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    const filters = [
      '',
      'applied',
      'under_review',
      'approved',
      'mcq_completed',
      'hired',
      'rejected',
      // 'interview_completed',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            filters.map((status) {
              final label =
                  status.isEmpty ? 'All' : status.replaceAll('_', ' ');
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: vm.statusFilter == status,
                  onSelected: (_) => vm.setFilter(status),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _HrApplicationCard extends StatelessWidget {
  const _HrApplicationCard({required this.application, required this.vm});

  final ApplicationModel application;
  final HrDashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final status = application.status.replaceAll('_', ' ');
    final appliedDate =
        application.appliedAt == null
            ? '-'
            : DateFormat('dd MMM yyyy').format(application.appliedAt!);
    final hasMcqResult = application.mcqScore != null;
    final isFinalDecision =
        application.status == 'hired' || application.status == 'rejected';
    final canHire =
        hasMcqResult &&
        (application.mcqPassed == true || application.mcqScore! >= 60) &&
        !isFinalDecision;
    final canRejectAfterMcq = hasMcqResult && !isFinalDecision;
    final resumeUrl = _absoluteUrl(application.candidateCvUrl);
    final recordingUrl = _absoluteUrl(application.interviewRecordingUrl);

    return PanelCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.candidateName ?? 'Candidate',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    application.jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Chip(label: Text(status)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(application.candidateEmail ?? ''),
        ),
        children: [
          const Divider(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text('Applied $appliedDate'),
              ),
              Chip(label: Text('${application.matchScore}% match')),
              if (application.mcqScore != null)
                Chip(
                  avatar: Icon(
                    application.mcqPassed == true
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 16,
                  ),
                  label: Text(
                    'MCQ ${application.mcqScore!.toStringAsFixed(1)}% ${application.mcqPassed == true ? 'passed' : 'failed'}',
                  ),
                ),
              if (application.status == 'mcq_completed')
                const Chip(label: Text('Ready for HR evaluation')),
            ],
          ),
          const SizedBox(height: 14),
          _ReviewDetails(
            application: application,
            resumeUrl: resumeUrl,
            recordingUrl: recordingUrl,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed:
                    application.status == 'under_review' ||
                            hasMcqResult ||
                            isFinalDecision
                        ? null
                        : () => vm.updateStatus(application, 'under_review'),
                child: const Text('Review'),
              ),
              FilledButton(
                onPressed:
                    application.status == 'approved' || hasMcqResult
                        ? null
                        : () => vm.updateStatus(application, 'approved'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Approve for MCQ'),
              ),
              OutlinedButton(
                onPressed:
                    canRejectAfterMcq
                        ? () => vm.rejectAfterMcq(application)
                        : null,
                child: const Text('Reject after MCQ'),
              ),
              FilledButton.icon(
                onPressed: canHire ? () => vm.hire(application) : null,
                icon: const Icon(Icons.work_outline_rounded),
                label: const Text('Hire after MCQ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _absoluteUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    final slash = value.startsWith('/') ? '' : '/';
    return '${ApiConfig.rootUrl}$slash$value';
  }
}

class _ReviewDetails extends StatelessWidget {
  const _ReviewDetails({
    required this.application,
    required this.resumeUrl,
    required this.recordingUrl,
  });

  final ApplicationModel application;
  final String? resumeUrl;
  final String? recordingUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysis = application.interviewAnalysis;
    final deadline =
        application.jobDeadline == null
            ? null
            : DateFormat('dd MMM yyyy').format(application.jobDeadline!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Candidate details',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Name', value: application.candidateName),
          _InfoRow(label: 'Email', value: application.candidateEmail),
          _InfoRow(label: 'Phone', value: application.candidatePhone),
          _InfoRow(label: 'Course', value: application.candidateCourse),
          _CvViewerButton(
            resumeUrl: resumeUrl,
            resumeName: application.candidateCvName,
          ),
          if (application.candidateSkills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  application.candidateSkills
                      .map((skill) => Chip(label: Text(skill)))
                      .toList(),
            ),
          ],
          const Divider(height: 22),
          Text(
            'Applied job details',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Job title', value: application.jobTitle),
          _InfoRow(label: 'Company', value: application.company),
          _InfoRow(label: 'Location', value: application.jobLocation),
          _InfoRow(label: 'Department', value: application.jobDepartment),
          _InfoRow(label: 'Duration', value: application.jobDuration),
          _InfoRow(label: 'Stipend', value: application.jobStipend),
          _InfoRow(label: 'Deadline', value: deadline),
          _InfoRow(
            label: 'Required skills',
            value:
                application.jobSkills.isEmpty
                    ? null
                    : application.jobSkills.join(', '),
            multiline: true,
          ),
          _InfoRow(
            label: 'Description',
            value: application.jobDescription,
            multiline: true,
          ),
          const Divider(height: 22),
          Text(
            'Application status',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Status', value: application.statusLabel),
          _InfoRow(label: 'Match', value: '${application.matchScore}% match'),
          _InfoRow(
            label: 'MCQ result',
            value:
                application.mcqScore == null
                    ? 'Not completed'
                    : '${application.mcqScore!.toStringAsFixed(1)}% - ${application.mcqPassed == true ? 'Passed' : 'Failed'}',
          ),
          _InfoRow(
            label: 'HR evaluation',
            value: _evaluationMessage(application),
            multiline: true,
          ),
          _InfoRow(
            label: 'Interview result',
            value: application.interviewResult,
          ),
          _InfoRow(
            label: 'Feedback',
            value: application.interviewFeedback,
            multiline: true,
          ),
          _InfoRow(label: 'Recording', value: recordingUrl),
          if (analysis != null && analysis.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'AI analysis',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            ...analysis.entries.map(
              (entry) => _InfoRow(
                label: entry.key.replaceAll('_', ' '),
                value: entry.value?.toString(),
                multiline: true,
              ),
            ),
          ],
          if (application.interviewTranscript?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Transcript',
              value: application.interviewTranscript,
              multiline: true,
            ),
          ],
        ],
      ),
    );
  }

  String _evaluationMessage(ApplicationModel application) {
    if (application.status == 'hired') {
      return 'Final decision: hired after MCQ evaluation.';
    }
    if (application.status == 'rejected' && application.mcqScore != null) {
      return 'Final decision: rejected after MCQ evaluation.';
    }
    if (application.mcqScore == null) {
      return 'Waiting for candidate to complete the MCQ test.';
    }
    if (application.mcqPassed == true) {
      return 'Candidate passed the MCQ. HR can hire or reject based on the score and profile fit.';
    }
    return 'Candidate did not meet the MCQ pass mark. HR can reject after evaluation.';
  }
}

class _CvViewerButton extends StatefulWidget {
  const _CvViewerButton({required this.resumeUrl, required this.resumeName});

  final String? resumeUrl;
  final String? resumeName;

  @override
  State<_CvViewerButton> createState() => _CvViewerButtonState();
}

class _CvViewerButtonState extends State<_CvViewerButton> {
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final hasResume = widget.resumeUrl?.trim().isNotEmpty == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 118,
            child: Text(
              'Resume',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              hasResume ? _displayName(widget.resumeUrl!) : 'Not uploaded',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: hasResume && !_opening ? _openResume : null,
            icon:
                _opening
                    ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.visibility_outlined),
            label: const Text('View CV'),
          ),
        ],
      ),
    );
  }

  Future<void> _openResume() async {
    setState(() => _opening = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final opened = await launchUrl(
        Uri.parse(Uri.encodeFull(widget.resumeUrl!)),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open this CV.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open this CV.')),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  String _displayName(String value) {
    final providedName = widget.resumeName?.trim();
    if (providedName != null && providedName.isNotEmpty) {
      return providedName;
    }
    final uri = Uri.tryParse(value);
    final path = uri?.path.isNotEmpty == true ? uri!.path : value;
    final parts = path.split('/');
    return parts.isEmpty ? 'Uploaded CV' : Uri.decodeComponent(parts.last);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String? value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final display = value == null || value!.trim().isEmpty ? '-' : value!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child:
          multiline
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(display),
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 118,
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(child: SelectableText(display)),
                ],
              ),
    );
  }
}
