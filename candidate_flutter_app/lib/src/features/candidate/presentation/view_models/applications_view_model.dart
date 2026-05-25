import 'package:flutter/foundation.dart';

import '../../data/candidate_repository.dart';
import '../../domain/models/application_model.dart';
import '../../domain/models/mcq_question.dart';

class ApplicationsViewModel extends ChangeNotifier {
  ApplicationsViewModel(this._repository);

  final CandidateRepository _repository;

  List<ApplicationModel> applications = [];
  List<McqQuestion> questions = [];
  final Map<int, String> answers = {};
  bool loading = false;
  bool examLoading = false;
  bool submitting = false;
  String? error;
  String? successMessage;
  ApplicationModel? selectedApplication;

  Future<void> loadApplications() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      applications = await _repository.applications();
    } catch (e) {
      error = _cleanError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> startMcq(ApplicationModel application) async {
    if (!application.canTakeMcq) {
      error = 'MCQ will be available only after HR approves this application.';
      notifyListeners();
      return false;
    }
    examLoading = true;
    error = null;
    selectedApplication = application;
    answers.clear();
    notifyListeners();
    try {
      questions = await _repository.mcqQuestions(application.id);
      return questions.isNotEmpty;
    } catch (e) {
      error = _cleanError(e);
      return false;
    } finally {
      examLoading = false;
      notifyListeners();
    }
  }

  void selectAnswer(McqQuestion question, String answer) {
    answers[question.id] = answer;
    notifyListeners();
  }

  Future<bool> submitMcq() async {
    final application = selectedApplication;
    if (application == null) return false;
    submitting = true;
    error = null;
    notifyListeners();
    try {
      final updated = await _repository.submitMcq(
        applicationId: application.id,
        answers: answers,
      );
      applications =
          applications
              .map((item) => item.id == updated.id ? updated : item)
              .toList();
      successMessage = 'MCQ submitted successfully.';
      return true;
    } catch (e) {
      error = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  String _cleanError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.startsWith('DioException')) {
      return 'Server request failed. Please try again.';
    }
    return message;
  }
}
