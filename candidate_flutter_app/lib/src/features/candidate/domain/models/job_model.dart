class JobModel {
  JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.experience,
    required this.skills,
    required this.description,
    required this.matchScore,
    required this.applied,
    required this.saved,
    this.department,
    this.postedDate,
    this.deadline,
  });

  final int id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final String experience;
  final List<String> skills;
  final String description;
  final int matchScore;
  final String? department;
  final DateTime? postedDate;
  final DateTime? deadline;
  bool applied;
  bool saved;

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as int? ?? 0,
      title: json['job_title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      location: json['location'] as String? ?? '',
      salary: (json['salary_stipend'] ?? json['stipend'] ?? '').toString(),
      experience:
          (json['experience_required'] ?? json['duration'] ?? '').toString(),
      skills: List<String>.from(
        json['skills_required'] as List? ?? json['skills'] as List? ?? const [],
      ),
      description: json['description'] as String? ?? '',
      matchScore: json['match_score'] as int? ?? 0,
      applied: json['applied'] == true,
      saved: json['saved'] == true,
      department: json['department'] as String?,
      postedDate: DateTime.tryParse(
        (json['posted_date'] ?? json['created_at'] ?? '').toString(),
      ),
      deadline: DateTime.tryParse((json['deadline'] ?? '').toString()),
    );
  }
}
