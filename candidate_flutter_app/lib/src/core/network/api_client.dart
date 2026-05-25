import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class ApiClient {
  ApiClient()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
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
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _overrideRootUrl = null;
      return;
    }
    _overrideRootUrl =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed.replaceAll(RegExp(r'/+$'), '')
            : 'http://${trimmed.replaceAll(RegExp(r'/+$'), '')}';
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Web secure storage can be unavailable outside a supported browser
      // context. SharedPreferences keeps the web session authenticated.
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {
      // Fall through to the SharedPreferences copy.
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
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
    } catch (_) {
      // Ignore storage backends that are unavailable on this platform.
    }
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return _request('GET', path, query: query);
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    ProgressCallback? onSendProgress,
  }) async {
    return _request('POST', path, data: data, onSendProgress: onSendProgress);
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
  }) async {
    final roots = await _orderedRoots();
    DioException? lastNetworkError;
    for (final root in roots) {
      try {
        final response = await _dio.request<dynamic>(
          _urlFor(root, path),
          data: data,
          queryParameters: query,
          options: await _authOptions(method),
          onSendProgress: onSendProgress,
        );
        await _saveActiveRoot(root);
        return response;
      } on DioException catch (e) {
        if (!_isNetworkFailure(e)) rethrow;
        lastNetworkError = e;
      }
    }
    throw lastNetworkError ??
        DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
        );
  }

  Future<List<String>> _orderedRoots() async {
    final prefs = await SharedPreferences.getInstance();
    final activeRoot = prefs.getString(_activeRootKey);
    final definedRoots = ApiConfig.rootUrls;
    final roots = <String>[];
    // If an override root is set at runtime (phone input), prefer it first.
    if (_overrideRootUrl != null && _overrideRootUrl!.isNotEmpty) {
      roots.add(_overrideRootUrl!);
    }
    // Prefer the last successful server so every request does not wait on
    // dead fallback URLs first.
    if (activeRoot != null &&
        activeRoot.isNotEmpty &&
        !roots.contains(activeRoot)) {
      roots.add(activeRoot);
    }
    // Keep configured roots as fallbacks for IP/backend changes.
    roots.addAll(definedRoots);
    return roots.toSet().toList();
  }

  Future<void> _saveActiveRoot(String root) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeRootKey, root);
  }

  String _urlFor(String root, String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) return path;
    if (path.startsWith('/api/')) return '$root$path';
    return '$root/api/register$path';
  }

  bool _isNetworkFailure(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.unknown;
  }

  Future<Options> _authOptions(String method) async {
    final token = await getToken();
    return Options(
      method: method,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }
}
