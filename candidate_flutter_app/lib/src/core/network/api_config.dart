import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _definedRootUrl = String.fromEnvironment('API_ROOT_URL');
  static const _definedLanUrl = String.fromEnvironment('API_LAN_URL');
  static const _defaultAndroidLanUrl = 'http://192.168.1.16:8000';

  static String get rootUrl {
    return rootUrls.first;
  }

  static List<String> get rootUrls {
    final urls = <String>[
      if (_definedRootUrl.isNotEmpty) _definedRootUrl,
      if (kIsWeb) ...[
        'http://127.0.0.1:8000',
        if (_definedLanUrl.isNotEmpty) _definedLanUrl,
        _defaultAndroidLanUrl,
      ],
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
        if (_definedLanUrl.isNotEmpty) _definedLanUrl,
        _defaultAndroidLanUrl,
        'http://10.0.2.2:8000',
      ],
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android)
        'http://127.0.0.1:8000',
    ];
    return urls.toSet().toList();
  }

  static String get baseUrl {
    const value = String.fromEnvironment('API_BASE_URL');
    if (value.isNotEmpty) return value;
    return '$rootUrl/api/register';
  }

  static String get mcqBaseUrl => '$rootUrl/api/mcq';
}
