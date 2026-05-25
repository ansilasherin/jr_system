import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/result/api_exception.dart';
import '../domain/models/application_model.dart';
import '../domain/models/candidate_user.dart';
import '../domain/models/dashboard_bundle.dart';
import '../domain/models/jobs_page.dart';
import '../domain/models/mcq_question.dart';
import '../domain/models/picked_cv.dart';
import 'sample_candidate_data.dart';

class CandidateRepository {
  CandidateRepository(this._client);

  final ApiClient _client;

  Future<CandidateUser> login(
    String email,
    String password, {
    String? expectedRole,
  }) async {
    try {
      final response = await _client.post(
        '/auth/login/',
        data: {'email': email, 'password': password},
      );
      final data = _expectSuccess(response);
      await _client.saveToken(data['token'] as String);
      final user = CandidateUser.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
      await _client.saveSessionRole(user.role);
      return user;
    } on DioException catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
      if (expectedRole == 'hr') {
        throw ApiException(
          'Cannot connect to HR server at ${ApiConfig.rootUrl}. Start the backend or set API_ROOT_URL to the correct server address.',
        );
      }
      final mockUser =
          expectedRole == 'hr'
              ? SampleCandidateData.hrProfile
              : SampleCandidateData.profile;
      await _client.saveToken('mock-${mockUser.role}-token');
      await _client.saveSessionRole(mockUser.role);
      return mockUser;
    }
  }

  Future<CandidateUser> registerCandidate({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? course,
    PickedCv? cv,
  }) async {
    final data = FormData.fromMap({
      'full_name': fullName,
      'email': email,
      'password': password,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (course != null && course.trim().isNotEmpty) 'course': course.trim(),
    });
    if (cv != null) {
      data.files.add(
        MapEntry(
          'cv',
          cv.bytes != null
              ? MultipartFile.fromBytes(cv.bytes!, filename: cv.name)
              : await MultipartFile.fromFile(cv.path!, filename: cv.name),
        ),
      );
    }
    try {
      final response = await _client.post(
        '/auth/register/candidate/',
        data: data,
      );
      final body = _expectSuccess(response);
      return CandidateUser.fromJson(
        Map<String, dynamic>.from(body['user'] as Map),
      );
    } on DioException catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
      return CandidateUser(
        id: SampleCandidateData.profile.id,
        fullName: fullName,
        email: email,
        role: 'user',
        phone: phone,
        course: course,
        cvUrl: cv?.name,
        cvName: cv?.name,
        skills:
            cv == null ? const [] : SampleCandidateData.skillsForCv(cv.name),
      );
    }
  }

  Future<void> logout() => _client.clearToken();

  Future<String?> savedSessionRole() async {
    final token = await _client.getToken();
    if (token == null || token.isEmpty) return null;
    return _client.getSessionRole();
  }

  Future<DashboardBundle> dashboard() async {
    try {
      final response = await _client.get('/candidate/dashboard/');
      return DashboardBundle.fromJson(_expectSuccess(response));
    } on DioException catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
      return DashboardBundle(
        profile: SampleCandidateData.profile,
        recommendedJobs: const [],
        recentApplications: const [],
        savedJobs: const [],
      );
    }
  }

  Future<List<String>> extractSkillsFromCv(
    PickedCv cv,
    void Function(double progress) onProgress,
  ) async {
    final uploadFile =
        cv.bytes != null
            ? MultipartFile.fromBytes(cv.bytes!, filename: cv.name)
            : await MultipartFile.fromFile(cv.path!, filename: cv.name);
    final formData = FormData.fromMap({'cv': uploadFile});
    try {
      final response = await _client.post(
        '/candidate/skills/extract/',
        data: formData,
        onSendProgress:
            (sent, total) => onProgress(total <= 0 ? 0 : sent / total),
      );
      final data = _expectSuccess(response);
      return List<String>.from(data['skills'] as List? ?? const []);
    } on DioException catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
      onProgress(1);
      return SampleCandidateData.skillsForCv(cv.name);
    }
  }

  Future<JobsPage> jobs({
    required int page,
    required String query,
    required String location,
    String? department,
    required List<String> skills,
    List<String> matchSkills = const [],
    bool skillMatch = true,
  }) async {
    try {
      final response = await _client.get(
        '/jobs/',
        query: {
          'page': page,
          'page_size': 10,
          if (query.trim().isNotEmpty) 'q': query.trim(),
          if (location.trim().isNotEmpty) 'location': location.trim(),
          if (department != null && department.trim().isNotEmpty)
            'department': department.trim(),
          if (skills.isNotEmpty) 'skills': skills.join(','),
          if (matchSkills.isNotEmpty) 'match_skills': matchSkills.join(','),
          if (skillMatch) 'skill_match': 1,
        },
      );
      return JobsPage.fromJson(_expectSuccess(response));
    } on DioException catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
      return SampleCandidateData.jobsPage(
        page: page,
        query: query,
        location: location,
        department: department,
        selectedSkills: skills,
        matchSkills: matchSkills,
        skillMatch: skillMatch,
      );
    }
  }

  Future<ApplicationModel> applyJob(int jobId) async {
    try {
      final response = await _client.post(
        '/applications/apply/',
        data: {'job_id': jobId},
      );
      final data = _expectSuccess(response);
      return ApplicationModel.fromJson(
        Map<String, dynamic>.from(data['application'] as Map),
      );
    } on DioException catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
      throw ApiException(
        'Cannot submit application without connecting to the server.',
      );
    }
  }

  Future<List<ApplicationModel>> applications() async {
    try {
      final response = await _client.get('/applications/');
      final data = _expectSuccess(response);
      return (data['applications'] as List? ?? const [])
          .map(
            (item) =>
                ApplicationModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
      return const [];
    }
  }

  Future<List<ApplicationModel>> hrApplications({String? status}) async {
    final response = await _client.get(
      '/hr/applications/',
      query: {if (status != null && status.isNotEmpty) 'status': status},
    );
    final data = _expectSuccess(response);
    return (data['applications'] as List? ?? const [])
        .map(
          (item) => ApplicationModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<ApplicationModel> updateApplicationStatus(
    int applicationId,
    String status,
  ) async {
    final response = await _client.post(
      '/hr/applications/$applicationId/status/',
      data: {'status': status},
    );
    final data = _expectSuccess(response);
    return ApplicationModel.fromJson(
      Map<String, dynamic>.from(data['application'] as Map),
    );
  }

  Future<ApplicationModel> hireCandidate(int applicationId) async {
    final response = await _client.post(
      '/hr/applications/$applicationId/hire/',
    );
    final data = _expectSuccess(response);
    return ApplicationModel.fromJson(
      Map<String, dynamic>.from(data['application'] as Map),
    );
  }

  Future<List<McqQuestion>> mcqQuestions(int applicationId) async {
    try {
      final response = await _client.get(
        '/api/mcq/applications/$applicationId/questions/',
      );
      final data = _expectSuccess(response);
      return (data['questions'] as List? ?? const [])
          .map((item) => McqQuestion.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
      return SampleCandidateData.mcqQuestions;
    }
  }

  Future<ApplicationModel> submitMcq({
    required int applicationId,
    required Map<int, String> answers,
  }) async {
    final payload =
        answers.entries
            .map((entry) => {'question_id': entry.key, 'answer': entry.value})
            .toList();
    try {
      final response = await _client.post(
        '/api/mcq/applications/$applicationId/submit/',
        data: {'answers': payload},
      );
      final data = _expectSuccess(response);
      return ApplicationModel.fromJson(
        Map<String, dynamic>.from(data['application'] as Map? ?? const {}),
      );
    } on DioException catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
      final app = SampleCandidateData.recentApplications.firstWhere(
        (item) => item.id == applicationId,
        orElse: () => SampleCandidateData.recentApplications.first,
      );
      return ApplicationModel(
        id: app.id,
        jobId: app.jobId,
        status: 'mcq_completed',
        matchScore: app.matchScore,
        jobTitle: app.jobTitle,
        company: app.company,
        appliedAt: app.appliedAt,
        mcqScore: 86,
        mcqPassed: true,
      );
    }
  }

  Future<void> setSaved(int jobId, bool saved) async {
    try {
      final response =
          saved
              ? await _client.post('/jobs/$jobId/save/')
              : await _client.delete('/jobs/$jobId/save/');
      _expectSuccess(response);
    } on DioException catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
    }
  }

  Map<String, dynamic> _expectSuccess(Response<dynamic> response) {
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw ApiException(data['message'] as String? ?? 'Request failed');
    }
    if (data['success'] != true) {
      throw ApiException(data['message'] as String? ?? 'Request failed');
    }
    return data;
  }

  bool _isNetworkFailure(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.unknown;
  }
}
