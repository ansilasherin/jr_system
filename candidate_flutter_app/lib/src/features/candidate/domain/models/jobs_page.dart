import 'job_model.dart';

class JobsPage {
  const JobsPage({
    required this.jobs,
    required this.hasNext,
    required this.page,
  });

  final List<JobModel> jobs;
  final bool hasNext;
  final int page;

  factory JobsPage.fromJson(Map<String, dynamic> json) {
    final pagination = Map<String, dynamic>.from(
      json['pagination'] as Map? ?? const {},
    );
    return JobsPage(
      jobs:
          (json['jobs'] as List? ?? const [])
              .map(
                (item) =>
                    JobModel.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList(),
      hasNext: pagination['has_next'] == true,
      page: pagination['page'] as int? ?? 1,
    );
  }
}
