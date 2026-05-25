import 'package:flutter/material.dart';

import 'empty_state.dart';
import 'panel_card.dart';

class SkillPanel extends StatelessWidget {
  const SkillPanel({
    super.key,
    required this.skills,
    required this.loading,
    this.error,
  });

  final List<String> skills;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Extracted Skills',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (skills.isEmpty)
            const EmptyState(
              title: 'No skills yet',
              message: 'Upload your CV to extract skills automatically.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  skills
                      .map(
                        (skill) => Chip(
                          avatar: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                          ),
                          label: Text(skill),
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }
}
