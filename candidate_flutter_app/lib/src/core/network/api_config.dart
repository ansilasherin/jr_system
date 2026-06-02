import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ApiConfig {
  static const _definedRootUrl = String.fromEnvironment('API_ROOT_URL');
  static const _definedLanUrl = String.fromEnvironment('API_LAN_URL');
  static const _assetHostPath = 'assets/config/api_host.json';
  static const serverUrlPrefsKey = 'api_server_root_url';
  static const defaultPort = 8000;

  static List<String> _resolvedRoots = [];
  static bool? _androidEmulator;
  static String? _assetHost;

  static String get rootUrl =>
      _resolvedRoots.isNotEmpty
          ? _resolvedRoots.first
          : 'http://127.0.0.1:8000';

  static List<String> get rootUrls =>
      _resolvedRoots.isNotEmpty
          ? List.unmodifiable(_resolvedRoots)
          : _fallbackRoots();

  static Future<void> initialize() async {
    _assetHost = await _loadAssetHost();
    _androidEmulator = await _detectAndroidEmulator();
    _resolvedRoots = _buildRootUrls();
  }

  static Future<String?> _loadAssetHost() async {
    try {
      final raw = await rootBundle.loadString(_assetHostPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return normalizeHost(data['host'] as String?);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _detectAndroidEmulator() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return !info.isPhysicalDevice;
    } catch (_) {
      return false;
    }
  }

  static bool get isAndroidEmulator => _androidEmulator == true;

  static List<String> _buildRootUrls() {
    final urls = <String>[if (_definedRootUrl.isNotEmpty) _definedRootUrl];
    final lanUrls = <String>[
      if (_definedLanUrl.isNotEmpty) _definedLanUrl,
      if (_assetHost != null && _assetHost!.isNotEmpty) _assetHost!,
    ];

    if (kIsWeb) {
      urls.addAll([
        'http://127.0.0.1:$defaultPort',
        'http://localhost:$defaultPort',
      ]);
      urls.addAll(lanUrls);
    } else if (Platform.isAndroid) {
      if (isAndroidEmulator) {
        urls.add('http://10.0.2.2:$defaultPort');
      }
      urls.addAll(lanUrls);
      // Physical phones must reach the PC over LAN — not localhost or 10.0.2.2.
    } else if (Platform.isIOS) {
      urls.add('http://127.0.0.1:$defaultPort');
      urls.addAll(lanUrls);
    } else {
      urls.add('http://127.0.0.1:$defaultPort');
      urls.addAll(lanUrls);
    }

    return urls.map(normalizeHost).whereType<String>().toSet().toList();
  }

  static List<String> _fallbackRoots() => _buildRootUrls();

  static String? normalizeHost(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed.replaceAll(RegExp(r'/+$'), '');
    }
    return 'http://${trimmed.replaceAll(RegExp(r'/+$'), '')}';
  }

  static bool isLocalhostHost(String host) {
    final uri = Uri.tryParse(host);
    if (uri == null) return false;
    return uri.host == '127.0.0.1' ||
        uri.host == 'localhost' ||
        uri.host == '10.0.2.2';
  }

  static String registerApiPath(String path) {
    if (path.startsWith('/api/register')) return path;
    return '/api/register$path';
  }

  static String mcqApiPath(String path) {
    if (path.startsWith('/api/mcq')) return path;
    return '/api/mcq$path';
  }

  static String absoluteUrl(String? value, String root) {
    if (value == null || value.trim().isEmpty) return '';
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final normalizedRoot = root.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.startsWith('/')) {
      return '$normalizedRoot$trimmed';
    }
    return '$normalizedRoot/$trimmed';
  }

  static String connectionHelpMessage() {
    if (!kIsWeb && Platform.isAndroid && !isAndroidEmulator) {
      return 'Cannot reach the JR System backend. On a real phone, set your PC IP in '
          'assets/config/api_host.json (host field), run '
          'python manage.py runserver 0.0.0.0:8000, and ensure phone and PC use the same Wi‑Fi.';
    }
    return 'Cannot reach the JR System backend. Start the server with '
        'python manage.py runserver 0.0.0.0:8000 and try again.';
  }

  static String get baseUrl => '$rootUrl/api/register';

  static String get mcqBaseUrl => '$rootUrl/api/mcq';
}
