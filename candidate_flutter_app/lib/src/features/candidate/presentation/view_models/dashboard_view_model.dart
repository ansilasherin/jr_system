import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../data/candidate_repository.dart';
import '../../domain/department_options.dart';
import '../../domain/models/application_model.dart';
import '../../domain/models/candidate_user.dart';
import '../../domain/models/job_model.dart';
import '../../domain/models/picked_cv.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repository);

  final CandidateRepository _repository;

  CandidateUser? profile;
  List<String> skills = [];
  List<JobModel> jobs = [];
  List<JobModel> savedJobs = [];
  List<ApplicationModel> recentApplications = [];

  bool loading = false;
  bool extracting = false;
  bool loadingMore = false;
  bool hasNext = false;
  double uploadProgress = 0;
  int _page = 1;
  String? error;
  String? successMessage;
  PickedCv? selectedCv;
  bool hasUploadedCvThisSession = false;
  String searchQuery = '';
  String locationFilter = '';
  final Set<String> skillFilters = {};

  String? get departmentFilter => normalizeDepartment(profile?.course);

  bool get hasDepartment =>
      departmentFilter != null && departmentFilter!.isNotEmpty;

  bool get canRecommendJobs => hasDepartment || skills.isNotEmpty;

  Future<void> loadDashboard() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final bundle = await _repository.dashboard();
      profile = bundle.profile;
      savedJobs = bundle.savedJobs;
      recentApplications = bundle.recentApplications;
      final restoredSkills = bundle.profile.skills;
      final hasStoredCv = bundle.profile.hasCv || restoredSkills.isNotEmpty;
      if (hasStoredCv) {
        skills = restoredSkills;
        hasUploadedCvThisSession = true;
      } else {
        skills = [];
        hasUploadedCvThisSession = false;
        skillFilters.clear();
      }
      await _loadDepartmentJobs(fallbackJobs: bundle.recommendedJobs);
    } catch (e) {
      error = _cleanError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDepartmentJobs({List<JobModel>? fallbackJobs}) async {
    final department = departmentFilter;
    if ((department == null || department.isEmpty) && skills.isEmpty) {
      jobs = [];
      hasNext = false;
      return;
    }
    _page = 1;
    final page = await _repository.jobs(
      page: _page,
      query: searchQuery,
      location: locationFilter,
      department: department,
      skills: skillFilters.toList(),
      matchSkills: skills,
      skillMatch: skills.isNotEmpty,
    );
    jobs = page.jobs.isNotEmpty ? page.jobs : (fallbackJobs ?? const []);
    hasNext = page.hasNext;
  }

  Future<void> pickAndUploadCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final picked = PickedCv(
      name: file.name,
      path: file.path,
      bytes: file.bytes,
    );
    if (picked.path == null && picked.bytes == null) {
      error = 'Could not read selected CV.';
      notifyListeners();
      return;
    }
    await uploadCv(picked);
  }

  Future<void> uploadCv(PickedCv cv) async {
    extracting = true;
    uploadProgress = 0;
    error = null;
    successMessage = null;
    selectedCv = cv;
    notifyListeners();
    try {
      skills = await _repository.extractSkillsFromCv(cv, (progress) {
        uploadProgress = progress.clamp(0, 1);
        notifyListeners();
      });
      profile = await _repository.fetchProfile();
      skills = profile?.skills ?? skills;
      hasUploadedCvThisSession = profile?.hasCv == true || skills.isNotEmpty;
      successMessage = 'CV uploaded and skills extracted successfully.';
      await refreshJobs();
    } catch (e) {
      error = _cleanError(e);
    } finally {
      extracting = false;
      uploadProgress = 1;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await loadDashboard();
  }

  Future<void> refreshJobs() async {
    if (!canRecommendJobs) {
      jobs = [];
      hasNext = false;
      notifyListeners();
      return;
    }
    await _loadDepartmentJobs();
    notifyListeners();
  }

  Future<void> loadMoreJobs() async {
    if (!canRecommendJobs || loadingMore || !hasNext) return;
    loadingMore = true;
    notifyListeners();
    try {
      final page = await _repository.jobs(
        page: _page + 1,
        query: searchQuery,
        location: locationFilter,
        department: departmentFilter,
        skills: skillFilters.toList(),
        matchSkills: skills,
        skillMatch: skills.isNotEmpty,
      );
      _page = page.page;
      jobs.addAll(page.jobs);
      hasNext = page.hasNext;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> updateSearch(String value) async {
    searchQuery = value;
    await refreshJobs();
  }

  Future<void> updateFilters(
    String location,
    Set<String> selectedSkills,
  ) async {
    locationFilter = location;
    skillFilters
      ..clear()
      ..addAll(selectedSkills);
    await refreshJobs();
  }

  Future<void> apply(JobModel job) async {
    error = null;
    successMessage = null;
    notifyListeners();
    try {
      final submitted = await _repository.applyJob(job.id);
      job.applied = true;
      successMessage =
          'Application submitted for ${submitted.jobTitle}. HR will review your CV before MCQ access.';
      recentApplications = await _repository.applications();
    } catch (e) {
      error = _cleanError(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> toggleSaved(JobModel job) async {
    final nextValue = !job.saved;
    job.saved = nextValue;
    notifyListeners();
    try {
      await _repository.setSaved(job.id, nextValue);
      if (nextValue) {
        savedJobs = [job, ...savedJobs.where((item) => item.id != job.id)];
      } else {
        savedJobs = savedJobs.where((item) => item.id != job.id).toList();
      }
    } catch (e) {
      job.saved = !nextValue;
      error = _cleanError(e);
    }
    notifyListeners();
  }

  void clearCachedDashboard() {
    profile = null;
    skills = [];
    jobs = [];
    savedJobs = [];
    recentApplications = [];
    hasNext = false;
    _page = 1;
    error = null;
    successMessage = null;
    selectedCv = null;
    hasUploadedCvThisSession = false;
    searchQuery = '';
    locationFilter = '';
    skillFilters.clear();
    notifyListeners();
  }

  String _cleanError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.startsWith('DioException') ||
        message.startsWith('ApiException')) {
      return message.replaceFirst('ApiException: ', '');
    }
    return message;
  }
}
