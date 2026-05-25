import 'package:flutter/foundation.dart';

import '../../data/candidate_repository.dart';
import '../../domain/models/candidate_user.dart';
import '../../domain/models/picked_cv.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final CandidateRepository _repository;
  bool loading = false;
  bool checkingSession = false;
  String? error;
  CandidateUser? user;

  Future<String?> savedSessionRoute() async {
    checkingSession = true;
    notifyListeners();
    try {
      final role = await _repository.savedSessionRole();
      if (role == 'hr') return 'hr';
      if (role == 'user') return 'user';
      return null;
    } finally {
      checkingSession = false;
      notifyListeners();
    }
  }

  Future<bool> login(
    String email,
    String password, {
    String expectedRole = 'user',
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      user = await _repository.login(
        email,
        password,
        expectedRole: expectedRole,
      );
      final isHrLogin = expectedRole == 'hr';
      if (isHrLogin != (user?.role == 'hr')) {
        await _repository.logout();
        user = null;
        error =
            isHrLogin
                ? 'This account is not an HR account.'
                : 'This account is not a candidate account.';
        return false;
      }
      return true;
    } catch (e) {
      error = _cleanError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> registerCandidate({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? course,
    PickedCv? cv,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _repository.registerCandidate(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        course: course,
        cv: cv,
      );
      return true;
    } catch (e) {
      error = _cleanError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    user = null;
    await _repository.logout();
  }

  String _cleanError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.startsWith('DioException')) {
      return 'Server request failed. Please try again.';
    }
    return message;
  }
}
