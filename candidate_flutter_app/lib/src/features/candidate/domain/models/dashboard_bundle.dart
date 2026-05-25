import 'application_model.dart';
import 'candidate_user.dart';
import 'job_model.dart';

class DashboardBundle {
  const DashboardBundle({
    required this.profile,
    required this.recommendedJobs,
    required this.recentApplications,
    required this.savedJobs,
  });

  final CandidateUser profile;
  final List<JobModel> recommendedJobs;
  final List<ApplicationModel> recentApplications;
  final List<JobModel> savedJobs;

  factory DashboardBundle.fromJson(Map<String, dynamic> json) {
    return DashboardBundle(
      profile: CandidateUser.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map? ?? const {}),
      ),
      recommendedJobs:
          (json['recommended_jobs'] as List? ?? const [])
              .map(
                (item) =>
                    JobModel.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList(),
      recentApplications:
          (json['recent_applications'] as List? ?? const [])
              .map(
                (item) => ApplicationModel.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      savedJobs:
          (json['saved_jobs'] as List? ?? const [])
              .map(
                (item) =>
                    JobModel.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList(),
    );
  }
}
