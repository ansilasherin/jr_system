import 'package:flutter/material.dart';

import '../../domain/models/application_model.dart';
import '../pages/applications_page.dart';
import 'empty_state.dart';
import 'panel_card.dart';

class RecentApplicationsPanel extends StatelessWidget {
  const RecentApplicationsPanel({super.key, required this.applications});

  final List<ApplicationModel> applications;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recently Applied',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
           SizedBox(height: 10),
          if (applications.isEmpty)
             EmptyState(
              title: 'No applications',
              message: 'Jobs you apply to will appear here.',
            )
          else
            ...applications.map(
              (app) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  app.jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${app.company} · ${app.statusLabel}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap:
                    () => Navigator.of(
                      context,
                    ).pushNamed(ApplicationsPage.route),
              ),
            ),
        ],
      ),
    );
  }
}
