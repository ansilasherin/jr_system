import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeViewModel extends ChangeNotifier {
  AppThemeViewModel(this._prefs)
    : themeMode = _modeFromName(_prefs.getString(_themeModeKey));

  static const _themeModeKey = 'app_theme_mode';

  final SharedPreferences _prefs;
  ThemeMode themeMode;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode == mode) return;
    themeMode = mode;
    await _prefs.setString(_themeModeKey, mode.name);
    notifyListeners();
  }

  static ThemeMode _modeFromName(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }
}
