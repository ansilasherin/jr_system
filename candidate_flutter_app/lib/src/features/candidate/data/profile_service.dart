import '../domain/models/application_model.dart';
import '../domain/models/profile_summary.dart';

class ProfileService {
  const ProfileService();

  List<HrPostedJobSummary> buildPostedJobs(
    List<ApplicationModel> applications,
  ) {
    final grouped = <int, List<ApplicationModel>>{};
    for (final application in applications) {
      grouped.putIfAbsent(application.jobId, () => []).add(application);
    }

    return grouped.entries.map((entry) {
        final first = entry.value.first;
        return HrPostedJobSummary(
          jobId: entry.key,
          title: first.jobTitle,
          company: first.company,
          location: first.jobLocation ?? 'Not specified',
          status: _jobStatus(entry.value),
          applicationCount: entry.value.length,
        );
      }).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  String _jobStatus(List<ApplicationModel> applications) {
    final closedStatuses = {'hired', 'rejected', 'selected', 'closed'};
    final hasOpenApplication = applications.any(
      (application) => !closedStatuses.contains(application.status),
    );
    return hasOpenApplication ? 'active' : 'closed';
  }
}
