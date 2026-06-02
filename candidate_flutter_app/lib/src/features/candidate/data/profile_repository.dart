import 'candidate_repository.dart';
import 'profile_service.dart';
import 'sample_candidate_data.dart';
import '../domain/models/job_model.dart';
import '../domain/models/profile_summary.dart';

class ProfileRepository {
  ProfileRepository(this._candidateRepository, this._service);

  final CandidateRepository _candidateRepository;
  final ProfileService _service;

  Future<CandidateProfileSummary> candidateProfile() async {
    try {
      final user = await _candidateRepository.fetchProfile();
      final applications = await _candidateRepository.applications();
      final savedJobs = await _savedJobs();
      return CandidateProfileSummary(
        user: user,
        applications: applications,
        savedJobs: savedJobs,
      );
    } catch (_) {
      return CandidateProfileSummary(
        user: SampleCandidateData.profile,
        applications: SampleCandidateData.recentApplications,
        savedJobs: SampleCandidateData.jobs.where((job) => job.saved).toList(),
      );
    }
  }

  Future<List<JobModel>> _savedJobs() async {
    try {
      return (await _candidateRepository.dashboard()).savedJobs;
    } catch (_) {
      return const [];
    }
  }

  Future<HrProfileSummary> hrProfile() async {
    try {
      final user = await _candidateRepository.fetchProfile();
      final applications = await _candidateRepository.hrApplications();
      return HrProfileSummary(
        user: user,
        postedJobs: _service.buildPostedJobs(applications),
      );
    } catch (_) {
      return HrProfileSummary(
        user: SampleCandidateData.hrProfile,
        postedJobs: _service.buildPostedJobs(
          SampleCandidateData.hrApplications,
        ),
      );
    }
  }
}
