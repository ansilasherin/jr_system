import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import '../result/api_exception.dart';

class ApiClient {
  ApiClient()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null && status < 600,
        ),
      );

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'candidate_token';
  static const _roleKey = 'session_role';
  static const _activeRootKey = 'active_api_root_url';

  String? _overrideRootUrl;

  void setOverrideRootUrl(String? url) {
    _overrideRootUrl = ApiConfig.normalizeHost(url);
  }

  Future<void> loadSavedServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setOverrideRootUrl(prefs.getString(ApiConfig.serverUrlPrefsKey));
    await _sanitizeActiveRoot(prefs);
  }

  Future<void> _sanitizeActiveRoot(SharedPreferences prefs) async {
    final active = prefs.getString(_activeRootKey);
    if (active == null || active.isEmpty) return;
    if (!kIsWeb &&
        Platform.isAndroid &&
        !ApiConfig.isAndroidEmulator &&
        ApiConfig.isLocalhostHost(active)) {
      await prefs.remove(_activeRootKey);
    }
  }

  Future<void> saveServerUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(ApiConfig.serverUrlPrefsKey);
      setOverrideRootUrl(null);
      return;
    }
    setOverrideRootUrl(url);
    await prefs.setString(ApiConfig.serverUrlPrefsKey, _overrideRootUrl!);
  }

  Future<String?> getActiveRootUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeRootKey) ??
        _overrideRootUrl ??
        ApiConfig.rootUrl;
  }

  Future<String?> getConfiguredServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.serverUrlPrefsKey) ??
        _overrideRootUrl ??
        ApiConfig.rootUrls.firstOrNull;
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_tokenKey);
    if (cached != null && cached.isNotEmpty) return cached;
    try {
      final token = await _storage
          .read(key: _tokenKey)
          .timeout(const Duration(seconds: 3));
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    return null;
  }

  Future<void> saveSessionRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  Future<String?> getSessionRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool mcq = false,
    bool singleHost = false,
  }) async {
    return _request(
      'GET',
      path,
      query: query,
      mcq: mcq,
      singleHost: singleHost,
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    ProgressCallback? onSendProgress,
    bool mcq = false,
    bool singleHost = false,
  }) async {
    return _request(
      'POST',
      path,
      data: data,
      onSendProgress: onSendProgress,
      mcq: mcq,
      singleHost: singleHost,
    );
  }

  Future<Response<dynamic>> delete(String path) async {
    return _request('DELETE', path);
  }

  Future<Response<dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    dynamic data,
    ProgressCallback? onSendProgress,
    bool mcq = false,
    bool singleHost = false,
  }) async {
    final roots = await _orderedRoots(singleHost: singleHost);
    if (roots.isEmpty) {
      throw ApiException(ApiConfig.connectionHelpMessage());
    }

    DioException? lastNetworkError;

    for (final root in roots) {
      try {
        final response = await _dio.request<dynamic>(
          _urlFor(root, path, mcq: mcq),
          data: data,
          queryParameters: query,
          options: await _authOptions(method, data),
          onSendProgress: onSendProgress,
        );
        await _saveActiveRoot(root);
        return response;
      } on DioException catch (e) {
        if (!_isNetworkFailure(e)) {
          throw _toApiException(e);
        }
        lastNetworkError = e;
      }
    }

    if (lastNetworkError != null) {
      throw lastNetworkError;
    }
    throw ApiException(ApiConfig.connectionHelpMessage());
  }

  Future<List<String>> _orderedRoots({bool singleHost = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final activeRoot = prefs.getString(_activeRootKey);
    final roots = <String>[];
    if (_overrideRootUrl != null && _overrideRootUrl!.isNotEmpty) {
      roots.add(_overrideRootUrl!);
    }
    if (activeRoot != null &&
        activeRoot.isNotEmpty &&
        !roots.contains(activeRoot) &&
        _isValidRootForDevice(activeRoot)) {
      roots.add(activeRoot);
    }
    if (singleHost) {
      if (roots.isEmpty && ApiConfig.rootUrls.isNotEmpty) {
        roots.add(ApiConfig.rootUrls.first);
      }
      return roots.toSet().toList();
    }
    roots.addAll(ApiConfig.rootUrls.where(_isValidRootForDevice));
    return roots.toSet().toList();
  }

  bool _isValidRootForDevice(String root) {
    if (kIsWeb) return true;
    if (Platform.isAndroid && !ApiConfig.isAndroidEmulator) {
      return !ApiConfig.isLocalhostHost(root);
    }
    return true;
  }

  Future<void> _saveActiveRoot(String root) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeRootKey, root);
  }

  String _urlFor(String root, String path, {required bool mcq}) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) return path;
    final normalizedRoot = root.replaceAll(RegExp(r'/+$'), '');
    if (path.startsWith('/api/')) return '$normalizedRoot$path';
    if (mcq) return '$normalizedRoot${ApiConfig.mcqApiPath(path)}';
    return '$normalizedRoot${ApiConfig.registerApiPath(path)}';
  }

  bool _isNetworkFailure(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }

  ApiException _toApiException(DioException? error) {
    final response = error?.response;
    if (response?.data is Map) {
      final data = Map<String, dynamic>.from(response!.data as Map);
      final message = data['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return ApiException(message);
      }
    }
    return ApiException(ApiConfig.connectionHelpMessage());
  }

  Future<Options> _authOptions(String method, dynamic data) async {
    final token = await getToken();
    return Options(
      method: method,
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      contentType:
          (data is Map || data is List) ? Headers.jsonContentType : null,
    );
  }
}
