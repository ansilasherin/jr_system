class CandidateUser {
  const CandidateUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.skills,
    this.phone,
    this.course,
    this.cvUrl,
    this.cvName,
    this.profileUrl,
  });

  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? course;
  final String? cvUrl;
  final String? cvName;
  final String? profileUrl;
  final List<String> skills;

  bool get hasCv => cvUrl != null && cvUrl!.isNotEmpty;

  factory CandidateUser.fromJson(Map<String, dynamic> json) {
    return CandidateUser(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      phone: json['phone'] as String?,
      course: json['course'] as String?,
      cvUrl: json['cv_url'] as String?,
      cvName: json['cv_name'] as String?,
      profileUrl: json['profile_url'] as String?,
      skills: List<String>.from(json['skills'] as List? ?? const []),
    );
  }
}
