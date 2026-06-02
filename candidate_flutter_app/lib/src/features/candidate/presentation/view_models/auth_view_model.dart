import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_config.dart';
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
      final role = await _repository.quickSessionRole();
      if (role == null) {
        user = null;
        return null;
      }
      // Refresh profile in the background; do not block app launch.
      _repository.restoreSession().then((restored) {
        user = restored;
        notifyListeners();
      });
      return role;
    } catch (e) {
      error = _cleanError(e);
      user = null;
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

  Future<void> ensureUserLoaded() async {
    if (user != null) return;
    user = await _repository.restoreSession();
    notifyListeners();
  }

  String _cleanError(Object error) {
    if (error is DioException) {
      return ApiConfig.connectionHelpMessage();
    }
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.startsWith('DioException') ||
        message.startsWith('ApiException')) {
      return message.replaceFirst('ApiException: ', '');
    }
    return message;
  }
}
