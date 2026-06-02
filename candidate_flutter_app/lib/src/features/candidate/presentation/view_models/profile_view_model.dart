import 'package:flutter/foundation.dart';

import '../../data/profile_repository.dart';
import '../../domain/models/profile_summary.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._repository);

  final ProfileRepository _repository;

  CandidateProfileSummary? candidateProfile;
  HrProfileSummary? hrProfile;
  bool loading = false;
  String? error;

  void clearCachedProfiles() {
    candidateProfile = null;
    hrProfile = null;
    error = null;
    notifyListeners();
  }

  Future<void> loadCandidateProfile() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      candidateProfile = await _repository.candidateProfile();
    } catch (e) {
      error = _cleanError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadHrProfile() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      hrProfile = await _repository.hrProfile();
    } catch (e) {
      error = _cleanError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
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
