import 'application_model.dart';
import 'candidate_user.dart';
import 'job_model.dart';

class CandidateProfileSummary {
  const CandidateProfileSummary({
    required this.user,
    required this.applications,
    required this.savedJobs,
  });

  final CandidateUser user;
  final List<ApplicationModel> applications;
  final List<JobModel> savedJobs;
}

class HrPostedJobSummary {
  const HrPostedJobSummary({
    required this.jobId,
    required this.title,
    required this.company,
    required this.location,
    required this.status,
    required this.applicationCount,
  });

  final int jobId;
  final String title;
  final String company;
  final String location;
  final String status;
  final int applicationCount;
}

class HrProfileSummary {
  const HrProfileSummary({required this.user, required this.postedJobs});

  final CandidateUser user;
  final List<HrPostedJobSummary> postedJobs;

  int get totalJobsPosted => postedJobs.length;

  int get activeJobs =>
      postedJobs.where((job) => job.status == 'active').length;

  int get closedJobs =>
      postedJobs.where((job) => job.status == 'closed').length;
}
