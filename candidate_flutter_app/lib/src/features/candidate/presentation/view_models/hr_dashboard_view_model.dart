import 'package:flutter/foundation.dart';

import '../../data/candidate_repository.dart';
import '../../domain/models/application_model.dart';

class HrDashboardViewModel extends ChangeNotifier {
  HrDashboardViewModel(this._repository);

  final CandidateRepository _repository;

  List<ApplicationModel> applications = [];
  bool loading = false;
  String? error;
  String? successMessage;
  String statusFilter = '';

  void clearCachedApplications() {
    applications = [];
    loading = false;
    error = null;
    successMessage = null;
    statusFilter = '';
    notifyListeners();
  }

  Future<void> loadApplications({bool showLoading = true}) async {
    if (showLoading) {
      loading = true;
    }
    error = null;
    notifyListeners();
    try {
      applications = await _repository.hrApplications(status: statusFilter);
    } catch (e) {
      error = _cleanError(e);
    } finally {
      if (showLoading) {
        loading = false;
      }
      notifyListeners();
    }
  }

  Future<void> setFilter(String status) async {
    statusFilter = status;
    await loadApplications();
  }

  Future<void> updateStatus(ApplicationModel application, String status) async {
    await _replaceApplication(
      () => _repository.updateApplicationStatus(application.id, status),
      '$status status updated.',
    );
  }

  Future<void> rejectAfterMcq(ApplicationModel application) async {
    await _replaceApplication(
      () => _repository.updateApplicationStatus(application.id, 'rejected'),
      'Candidate rejected after MCQ evaluation.',
    );
  }

  Future<void> hire(ApplicationModel application) async {
    await _replaceApplication(
      () => _repository.hireCandidate(application.id),
      'Candidate hired after MCQ evaluation.',
    );
  }

  Future<void> _replaceApplication(
    Future<ApplicationModel> Function() action,
    String message,
  ) async {
    error = null;
    successMessage = null;
    notifyListeners();
    try {
      final updated = await action();
      applications =
          applications
              .map((item) => item.id == updated.id ? updated : item)
              .toList();
      successMessage = message;
    } catch (e) {
      error = _cleanError(e);
    }
    notifyListeners();
  }

  String _cleanError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.startsWith('DioException') ||
        message.startsWith('ApiException')) {
      return message.replaceFirst('ApiException: ', '');
    }
    return message;
  }
}
