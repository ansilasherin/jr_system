import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/job_model.dart';

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({
    super.key,
    required this.job,
    required this.onSave,
    required this.onApply,
  });

  final JobModel job;
  final Future<void> Function() onSave;
  final Future<void> Function() onApply;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  bool _saving = false;
  bool _applying = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final deadline =
        job.deadline == null
            ? 'Not specified'
            : DateFormat('dd MMM yyyy').format(job.deadline!);
    final postedDate =
        job.postedDate == null
            ? 'Recently'
            : DateFormat('dd MMM yyyy').format(job.postedDate!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            tooltip: job.saved ? 'Saved' : 'Save job',
            onPressed: _saving ? null : _toggleSaved,
            icon: Icon(
              job.saved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: FilledButton.icon(
          onPressed: job.applied || _applying ? null : _confirmApply,
          icon:
              _applying
                  ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Icon(
                    job.applied
                        ? Icons.check_circle_outline_rounded
                        : Icons.send_rounded,
                  ),
          label: Text(job.applied ? 'Already Applied' : 'Apply for this job'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            job.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            job.company,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(icon: Icons.location_on_outlined, label: job.location),
              _InfoChip(icon: Icons.payments_outlined, label: job.salary),
              _InfoChip(
                icon: Icons.work_history_outlined,
                label: job.experience,
              ),
              _InfoChip(icon: Icons.schedule_rounded, label: postedDate),
              _InfoChip(icon: Icons.event_available_outlined, label: deadline),
              if (job.matchScore > 0)
                _InfoChip(
                  icon: Icons.auto_awesome_rounded,
                  label: '${job.matchScore}% profile match',
                ),
            ],
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Job Description',
            child: Text(
              job.description.trim().isEmpty
                  ? 'No detailed description has been added for this job.'
                  : job.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 22),
          _Section(
            title: 'Required Skills',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  job.skills.isEmpty
                      ? [const Chip(label: Text('Not specified'))]
                      : job.skills
                          .map((skill) => Chip(label: Text(skill)))
                          .toList(),
            ),
          ),
          const SizedBox(height: 22),
          _Section(
            title: 'Application Summary',
            child: Column(
              children: [
                _SummaryRow(label: 'Experience', value: job.experience),
                _SummaryRow(label: 'Salary / stipend', value: job.salary),
                _SummaryRow(label: 'Location', value: job.location),
                _SummaryRow(label: 'Deadline', value: deadline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSaved() async {
    setState(() => _saving = true);
    await widget.onSave();
    if (!mounted) return;
    setState(() => _saving = false);
  }

  Future<void> _confirmApply() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Submit application?'),
            content: Text(
              'Your profile and uploaded CV will be sent to ${widget.job.company} for ${widget.job.title}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Apply'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    setState(() => _applying = true);
    try {
      await widget.onApply();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit application. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label.isEmpty ? 'Not specified' : label),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not specified' : value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
