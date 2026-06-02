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
                              Expanded(
                                flex: 5,
                                child: _SideColumn(
                                  vm: vm,
                                  searchController: _searchController,
                                  onSearch: _onSearch,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(flex: 7, child: _JobsColumn(vm: vm)),
                            ],
                          )
                        else ...[
                          _SideColumn(
                            vm: vm,
                            searchController: _searchController,
                            onSearch: _onSearch,
                          ),
                          const SizedBox(height: 18),
                          _JobsColumn(vm: vm),
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
  const _SideColumn({
    required this.vm,
    required this.searchController,
    required this.onSearch,
  });

  final DashboardViewModel vm;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final fileName =
        vm.selectedCv?.name ??
        _storedCvName(vm.profile?.cvName, vm.profile?.cvUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardSearchPanel(
          enabled: vm.canRecommendJobs,
          controller: searchController,
          onSearch: onSearch,
        ),
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

class _DashboardSearchPanel extends StatelessWidget {
  const _DashboardSearchPanel({
    required this.enabled,
    required this.controller,
    required this.onSearch,
  });

  final bool enabled;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Jobs',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              return TextField(
                controller: controller,
                enabled: enabled,
                onChanged: onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search jobs, skills, company, location',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon:
                      value.text.isEmpty
                          ? null
                          : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              controller.clear();
                              onSearch('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                ),
              );
            },
          ),
          if (!enabled) ...[
            const SizedBox(height: 10),
            Text(
              'Upload your CV or set your department to enable job search.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JobsColumn extends StatelessWidget {
  const _JobsColumn({required this.vm});

  final DashboardViewModel vm;

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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: .18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $name',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse jobs for your department. Upload your CV to rank matches with AI-extracted skills.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: .86),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: .14),
            foregroundColor: theme.colorScheme.onPrimary,
            child: const Icon(Icons.work_outline_rounded, size: 30),
          ),
        ],
      ),
    );
  }
}
