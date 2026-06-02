import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models/application_model.dart';
import '../view_models/applications_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/panel_card.dart';
import 'mcq_exam_page.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key, this.showAppBar = true});

  static const route = '/applications';

  final bool showAppBar;

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationsViewModel>().loadApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ApplicationsViewModel>();

    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(title: const Text('My Applications'))
              : null,
      body: RefreshIndicator(
        onRefresh: vm.loadApplications,
        child:
            vm.loading
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
                    if (vm.applications.isEmpty)
                      const EmptyState(
                        title: 'No applications yet',
                        message:
                            'Jobs you apply to will appear here with full job details.',
                      )
                    else
                      ...vm.applications.map(
                        (app) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ApplicationCard(
                            application: app,
                            loading: vm.examLoading,
                            onStartMcq: () => _startMcq(context, vm, app),
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }

  Future<void> _startMcq(
    BuildContext context,
    ApplicationsViewModel vm,
    ApplicationModel application,
  ) async {
    final ok = await vm.startMcq(application);
    if (!context.mounted || !ok) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const McqExamPage()));
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.loading,
    required this.onStartMcq,
  });

  final ApplicationModel application;
  final bool loading;
  final VoidCallback onStartMcq;

  @override
  Widget build(BuildContext context) {
    final appliedDate =
        application.appliedAt == null
            ? '-'
            : DateFormat('dd MMM yyyy').format(application.appliedAt!);
    final deadline =
        application.jobDeadline == null
            ? 'Not specified'
            : DateFormat('dd MMM yyyy').format(application.jobDeadline!);

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  application.jobTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Chip(label: Text(application.statusLabel)),
            ],
          ),
          const SizedBox(height: 6),
          Text(application.company),
          if (application.jobLocation != null &&
              application.jobLocation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(application.jobLocation!),
          ],
          const SizedBox(height: 10),
          if (application.statusMessage != null &&
              application.statusMessage!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(application.statusMessage!),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                text: 'Applied $appliedDate',
              ),
              if (application.jobDepartment != null &&
                  application.jobDepartment!.isNotEmpty)
                _InfoChip(
                  icon: Icons.school_outlined,
                  text: application.jobDepartment!,
                ),
              if (application.jobStipend != null &&
                  application.jobStipend!.isNotEmpty)
                _InfoChip(
                  icon: Icons.payments_outlined,
                  text: application.jobStipend!,
                ),
              if (application.jobDuration != null &&
                  application.jobDuration!.isNotEmpty)
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  text: application.jobDuration!,
                ),
              _InfoChip(icon: Icons.event_outlined, text: 'Deadline $deadline'),
            ],
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('View applied job details'),
            children: [
              if (application.jobDescription != null &&
                  application.jobDescription!.isNotEmpty)
                _DetailRow(
                  label: 'Description',
                  value: application.jobDescription,
                ),
              if (application.jobSkills.isNotEmpty)
                _DetailRow(
                  label: 'Required skills',
                  value: application.jobSkills.join(', '),
                ),
              _DetailRow(label: 'Candidate', value: application.candidateName),
              _DetailRow(label: 'Email', value: application.candidateEmail),
              _DetailRow(label: 'Phone', value: application.candidatePhone),
              _DetailRow(
                label: 'CV',
                value:
                    application.candidateCvName != null &&
                            application.candidateCvName!.isNotEmpty
                        ? application.candidateCvName
                        : application.candidateCvUrl == null ||
                            application.candidateCvUrl!.isEmpty
                        ? 'Not uploaded'
                        : application.candidateCvUrl!.split('/').last,
              ),
              if (application.candidateSkills.isNotEmpty)
                _DetailRow(
                  label: 'Your skills',
                  value: application.candidateSkills.join(', '),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${application.matchScore}% match',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (application.mcqScore != null)
                Text('MCQ ${application.mcqScore!.toStringAsFixed(1)}%')
              else if (application.canTakeMcq)
                FilledButton.icon(
                  onPressed: loading ? null : onStartMcq,
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('Take MCQ'),
                )
              else if (application.status == 'rejected')
                const Text('Application rejected')
              else if (application.isPendingHrReview)
                const Text('MCQ locked until HR approval')
              else
                const Text('MCQ not available'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value == null || value!.isEmpty ? '-' : value!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
