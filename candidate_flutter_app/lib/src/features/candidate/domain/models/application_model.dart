class ApplicationModel {
  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.status,
    required this.matchScore,
    required this.jobTitle,
    required this.company,
    this.candidateName,
    this.candidateEmail,
    this.candidatePhone,
    this.candidateCourse,
    this.candidateCvUrl,
    this.candidateCvName,
    this.candidateSkills = const [],
    this.appliedAt,
    this.mcqScore,
    this.mcqPassed,
    this.canTakeMcq = false,
    this.statusMessage,
    this.jobLocation,
    this.jobDepartment,
    this.jobDuration,
    this.jobStipend,
    this.jobDescription,
    this.jobSkills = const [],
    this.jobDeadline,
    this.interviewResult,
    this.interviewFeedback,
    this.interviewTranscript,
    this.interviewAnalysis,
    this.interviewRecordingUrl,
    this.interviewRoomId,
  });

  final int id;
  final int jobId;
  final String status;
  final int matchScore;
  final String jobTitle;
  final String company;
  final String? candidateName;
  final String? candidateEmail;
  final String? candidatePhone;
  final String? candidateCourse;
  final String? candidateCvUrl;
  final String? candidateCvName;
  final List<String> candidateSkills;
  final DateTime? appliedAt;
  final double? mcqScore;
  final bool? mcqPassed;
  final bool canTakeMcq;
  final String? statusMessage;
  final String? jobLocation;
  final String? jobDepartment;
  final String? jobDuration;
  final String? jobStipend;
  final String? jobDescription;
  final List<String> jobSkills;
  final DateTime? jobDeadline;
  final String? interviewResult;
  final String? interviewFeedback;
  final String? interviewTranscript;
  final Map<String, dynamic>? interviewAnalysis;
  final String? interviewRecordingUrl;
  final String? interviewRoomId;

  String get statusLabel => status.replaceAll('_', ' ');

  bool get isPendingHrReview =>
      status == 'applied' || status == 'under_review' || status == 'pending';

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    final job = Map<String, dynamic>.from(json['job'] as Map? ?? const {});
    final candidate = Map<String, dynamic>.from(
      json['candidate'] as Map? ?? const {},
    );
    final score = json['mcq_score'];
    final analysis = json['interview_analysis'];
    final jobSkills = List<String>.from(
      json['skills'] as List? ??
          json['job_skills'] as List? ??
          job['skills'] as List? ??
          job['skills_required'] as List? ??
          const [],
    );
    final canTakeMcq =
        json['can_take_mcq'] as bool? ??
        ((json['status'] as String? ?? '') == 'approved' && score == null);

    return ApplicationModel(
      id: json['id'] as int? ?? 0,
      jobId: json['job_id'] as int? ?? job['id'] as int? ?? 0,
      status: json['status'] as String? ?? 'applied',
      matchScore: json['match_score'] as int? ?? 0,
      jobTitle:
          json['job_title'] as String? ?? job['job_title'] as String? ?? '',
      company: json['company'] as String? ?? job['company'] as String? ?? '',
      candidateName:
          json['candidate_name'] as String? ??
          candidate['full_name'] as String?,
      candidateEmail:
          json['candidate_email'] as String? ?? candidate['email'] as String?,
      candidatePhone:
          json['candidate_phone'] as String? ?? candidate['phone'] as String?,
      candidateCourse:
          json['candidate_course'] as String? ?? candidate['course'] as String?,
      candidateCvUrl:
          json['candidate_cv_url'] as String? ?? candidate['cv_url'] as String?,
      candidateCvName:
          json['candidate_cv_name'] as String? ??
          candidate['cv_name'] as String?,
      candidateSkills: List<String>.from(
        json['candidate_skills'] as List? ??
            candidate['skills'] as List? ??
            const [],
      ),
      appliedAt: DateTime.tryParse((json['applied_at'] ?? '').toString()),
      mcqScore:
          score is num
              ? score.toDouble()
              : double.tryParse((score ?? '').toString()),
      mcqPassed: json['mcq_passed'] as bool?,
      canTakeMcq: canTakeMcq,
      statusMessage: json['status_message'] as String?,
      jobLocation:
          json['job_location'] as String? ?? job['location'] as String?,
      jobDepartment:
          json['job_department'] as String? ?? job['department'] as String?,
      jobDuration:
          json['job_duration'] as String? ?? job['duration'] as String?,
      jobStipend:
          json['job_stipend'] as String? ??
          job['stipend'] as String? ??
          job['salary_stipend'] as String?,
      jobDescription:
          json['job_description'] as String? ?? job['description'] as String?,
      jobSkills: jobSkills,
      jobDeadline: DateTime.tryParse(
        (json['job_deadline'] ?? job['deadline'] ?? '').toString(),
      ),
      interviewResult: json['interview_result'] as String?,
      interviewFeedback: json['interview_feedback'] as String?,
      interviewTranscript: json['interview_transcript'] as String?,
      interviewAnalysis:
          analysis is Map ? Map<String, dynamic>.from(analysis) : null,
      interviewRecordingUrl: json['interview_recording_url'] as String?,
      interviewRoomId: json['interview_room_id']?.toString(),
    );
  }
}
