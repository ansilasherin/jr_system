import 'dart:async';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_config.dart';
import '../../domain/models/job_model.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/dashboard_view_model.dart';
import '../widgets/cv_upload_card.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/empty_state.dart';
import '../widgets/job_card.dart';
import '../widgets/panel_card.dart';
import '../widgets/recent_applications_panel.dart';
import '../widgets/skill_panel.dart';
import 'applications_page.dart';
import 'job_detail_page.dart';

class CandidateDashboardPage extends StatefulWidget {
  const CandidateDashboardPage({super.key, this.showApplicationsAction = true});

  static const route = '/candidate-dashboard';

  final bool showApplicationsAction;

  @override
  State<CandidateDashboardPage> createState() => _CandidateDashboardPageState();
}

class _CandidateDashboardPageState extends State<CandidateDashboardPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthViewModel>().ensureUserLoaded();
      if (!mounted) return;
      context.read<DashboardViewModel>().loadDashboard();
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 420) {
        context.read<DashboardViewModel>().loadMoreJobs();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();

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
        title: const Text('Candidate Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed:
                vm.loading || !vm.hasUploadedCvThisSession
                    ? null
                    : () => _showFilters(vm),
            icon: const Icon(Icons.tune_rounded),
          ),
          if (widget.showApplicationsAction)
            IconButton(
              tooltip: 'Applications',
              onPressed:
                  () => Navigator.of(context).pushNamed(ApplicationsPage.route),
              icon: const Icon(Icons.assignment_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.refreshAll,
        child:
            vm.loading
                ? const DashboardSkeleton()
                : LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth >= 820;
                    final padding = isTablet ? 28.0 : 16.0;

                    return ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.all(padding),
                      children: [
                        _HeroHeader(name: vm.profile?.fullName ?? 'Candidate'),
                        const SizedBox(height: 18),
                        if (isTablet)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: _SideColumn(vm: vm)),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 7,
                                child: _JobsColumn(
                                  vm: vm,
                                  searchController: _searchController,
                                  onSearch: _onSearch,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _SideColumn(vm: vm),
                          const SizedBox(height: 18),
                          _JobsColumn(
                            vm: vm,
                            searchController: _searchController,
                            onSearch: _onSearch,
                          ),
                        ],
                      ],
                    );
                  },
                ),
      ),
    );
  }

  void _onSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      context.read<DashboardViewModel>().updateSearch(value);
    });
  }

  Future<void> _showFilters(DashboardViewModel vm) async {
    final locationController = TextEditingController(text: vm.locationFilter);
    final selectedSkills = <String>{...vm.skillFilters};
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter Jobs',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        vm.skills.map((skill) {
                          final selected = selectedSkills.contains(skill);
                          return FilterChip(
                            label: Text(skill),
                            selected: selected,
                            onSelected:
                                (_) => setSheetState(() {
                                  selected
                                      ? selectedSkills.remove(skill)
                                      : selectedSkills.add(skill);
                                }),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      vm.updateFilters(
                        locationController.text.trim(),
                        selectedSkills,
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Apply filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SideColumn extends StatelessWidget {
  const _SideColumn({required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final fileName =
        vm.selectedCv?.name ??
        _storedCvName(vm.profile?.cvName, vm.profile?.cvUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileSummaryPanel(vm: vm, cvFileName: fileName),
        const SizedBox(height: 16),
        CvUploadCard(
          fileName: fileName,
          uploaded: vm.hasUploadedCvThisSession,
          extracting: vm.extracting,
          progress: vm.uploadProgress,
          onUpload: vm.pickAndUploadCv,
          onPreview: _previewAction(vm),
        ),
        const SizedBox(height: 16),
        if (vm.hasUploadedCvThisSession || vm.extracting) ...[
          SkillPanel(
            skills: vm.skills,
            loading: vm.extracting,
            error: vm.error,
          ),
          const SizedBox(height: 16),
        ],
        _SavedJobsPanel(jobs: vm.savedJobs),
        const SizedBox(height: 16),
        RecentApplicationsPanel(applications: vm.recentApplications),
      ],
    );
  }

  String? _storedCvName(String? cvName, String? url) {
    if (cvName != null && cvName.trim().isNotEmpty) return cvName.trim();
    if (url == null || url.isEmpty) return null;
    return Uri.tryParse(url)?.pathSegments.last ?? url.split('/').last;
  }

  VoidCallback? _previewAction(DashboardViewModel vm) {
    final localPath = vm.selectedCv?.path;
    if (localPath != null && localPath.isNotEmpty) {
      return () => OpenFilex.open(localPath);
    }

    final cvUrl = vm.profile?.cvUrl;
    if (cvUrl == null || cvUrl.isEmpty) return null;
    return () async {
      final uri = Uri.parse(
        cvUrl.startsWith('http') ? cvUrl : '${ApiConfig.rootUrl}$cvUrl',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    };
  }
}

class _ProfileSummaryPanel extends StatelessWidget {
  const _ProfileSummaryPanel({required this.vm, required this.cvFileName});

  final DashboardViewModel vm;
  final String? cvFileName;

  @override
  Widget build(BuildContext context) {
    final profile = vm.profile;
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _ProfileRow(
            icon: Icons.person_outline_rounded,
            label: 'Candidate',
            value: profile?.fullName ?? 'Candidate',
          ),
          _ProfileRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: profile?.email ?? '-',
          ),
          if (profile?.phone != null && profile!.phone!.isNotEmpty)
            _ProfileRow(
              icon: Icons.call_outlined,
              label: 'Phone',
              value: profile.phone!,
            ),
          if (profile?.course != null && profile!.course!.isNotEmpty)
            _ProfileRow(
              icon: Icons.school_outlined,
              label: 'Department',
              value: profile.course!,
            ),
          _ProfileRow(
            icon: Icons.description_outlined,
            label: 'Uploaded CV',
            value: cvFileName ?? 'No CV uploaded',
          ),
          _ProfileRow(
            icon: Icons.assignment_outlined,
            label: 'Applied jobs',
            value: vm.recentApplications.length.toString(),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
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

class _SavedJobsPanel extends StatelessWidget {
  const _SavedJobsPanel({required this.jobs});

  final List<JobModel> jobs;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved Jobs',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (jobs.isEmpty)
            const EmptyState(
              title: 'No saved jobs',
              message: 'Saved jobs will stay handy here.',
            )
          else
            ...jobs
                .take(5)
                .map(
                  (job) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(job.company),
                    trailing: Text('${job.matchScore}%'),
                  ),
                ),
        ],
      ),
    );
  }
}

class _JobsColumn extends StatelessWidget {
  const _JobsColumn({
    required this.vm,
    required this.searchController,
    required this.onSearch,
  });

  final DashboardViewModel vm;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!vm.canRecommendJobs)
          const EmptyState(
            title: 'Upload your CV',
            message:
                'Upload your CV or set your department to see AI-ranked job recommendations.',
          )
        else ...[
          TextField(
            controller: searchController,
            onChanged: onSearch,
            decoration: const InputDecoration(
              hintText: 'Search jobs, skills, company, location',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  vm.hasDepartment
                      ? '${vm.departmentFilter} Jobs'
                      : 'AI Recommended Jobs',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (vm.skillFilters.isNotEmpty || vm.locationFilter.isNotEmpty)
                TextButton.icon(
                  onPressed: () => vm.updateFilters('', {}),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (vm.jobs.isEmpty)
            EmptyState(
              title:
                  vm.hasDepartment
                      ? 'No ${vm.departmentFilter} jobs yet'
                      : 'No AI matches yet',
              message:
                  vm.hasUploadedCvThisSession
                      ? 'Try adjusting search or filters. Recommendations are ranked from your extracted CV skills.'
                      : 'No open vacancies for your department right now. Upload your CV to improve match ranking.',
            )
          else
            ...vm.jobs.map(
              (job) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: JobCard(
                  job: job,
                  onSave: () => vm.toggleSaved(job),
                  onApply:
                      job.applied
                          ? null
                          : () => _openJobDetails(context, vm, job),
                  onOpen: () => _openJobDetails(context, vm, job),
                ),
              ),
            ),
          if (vm.loadingMore)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ],
    );
  }

  Future<void> _openJobDetails(
    BuildContext context,
    DashboardViewModel vm,
    JobModel job,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => JobDetailPage(
              job: job,
              onSave: () => vm.toggleSaved(job),
              onApply: () => vm.apply(job),
            ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xff2563eb), Color(0xff14b8a6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $name',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse jobs for your department. Upload your CV to rank matches with AI-extracted skills.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: .92),
            ),
          ),
        ],
      ),
    );
  }
}
