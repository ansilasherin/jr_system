import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/hr_dashboard_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/logout_controls.dart';
import '../widgets/panel_card.dart';

class HrHomePage extends StatefulWidget {
  const HrHomePage({super.key});

  @override
  State<HrHomePage> createState() => _HrHomePageState();
}

class _HrHomePageState extends State<HrHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HrDashboardViewModel>().loadApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HrDashboardViewModel>();
    final theme = Theme.of(context);
    final pending =
        vm.applications
            .where(
              (item) =>
                  item.status == 'applied' || item.status == 'under_review',
            )
            .length;
    final completed =
        vm.applications
            .where(
              (item) => item.status == 'hired' || item.status == 'rejected',
            )
            .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Home'),
        actions: const [LogoutIconButton()],
      ),
      body: RefreshIndicator(
        onRefresh: vm.loadApplications,
        child:
            vm.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Recruitment Overview',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track candidates, approvals, MCQs, and hiring decisions.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 720 ? 3 : 1;
                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: columns == 1 ? 3.4 : 1.9,
                          children: [
                            _MetricCard(
                              label: 'Total Applications',
                              value: vm.applications.length.toString(),
                              icon: Icons.assignment_outlined,
                            ),
                            _MetricCard(
                              label: 'Pending Review',
                              value: pending.toString(),
                              icon: Icons.hourglass_top_rounded,
                            ),
                            _MetricCard(
                              label: 'Final Decisions',
                              value: completed.toString(),
                              icon: Icons.verified_outlined,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    if (vm.error != null)
                      Text(
                        vm.error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      )
                    else if (vm.applications.isEmpty)
                      const EmptyState(
                        title: 'No applications yet',
                        message: 'Candidate applications will appear here.',
                      )
                    else
                      PanelCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latest Applications',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...vm.applications
                                .take(5)
                                .map(
                                  (item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      child: Text(
                                        (item.candidateName ?? 'C')
                                            .trim()
                                            .characters
                                            .first
                                            .toUpperCase(),
                                      ),
                                    ),
                                    title: Text(
                                      item.candidateName ?? 'Candidate',
                                    ),
                                    subtitle: Text(item.jobTitle),
                                    trailing: Chip(
                                      label: Text(item.statusLabel),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
