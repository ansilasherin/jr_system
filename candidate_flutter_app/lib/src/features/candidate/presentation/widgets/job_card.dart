import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/job_model.dart';
import 'panel_card.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.onSave,
    required this.onApply,
    required this.onOpen,
  });

  final JobModel job;
  final VoidCallback onSave;
  final VoidCallback? onApply;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final postedDate =
        job.postedDate == null
            ? 'Recently'
            : DateFormat('dd MMM yyyy').format(job.postedDate!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: job.saved ? 'Saved' : 'Save job',
                    onPressed: onSave,
                    icon: Icon(
                      job.saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                  ),
                ],
              ),
              Text(
                job.company,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _IconText(
                    icon: Icons.location_on_outlined,
                    text: job.location,
                  ),
                  _IconText(icon: Icons.payments_outlined, text: job.salary),
                  _IconText(
                    icon: Icons.work_history_outlined,
                    text: job.experience,
                  ),
                  _IconText(icon: Icons.schedule_rounded, text: postedDate),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    job.skills
                        .map((skill) => Chip(label: Text(skill)))
                        .toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (job.matchScore > 0)
                    Text(
                      '${job.matchScore}% match',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: onOpen,
                    child: const Text('View details'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onApply,
                    child: Text(job.applied ? 'Applied' : 'Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 17), const SizedBox(width: 5), Text(text)],
    );
  }
}
