import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadThemePreference() async {
    final savedPreference = await PreferencesService.getDarkModePreference();
    if (savedPreference != null) {
      _isDarkMode = savedPreference;
      notifyListeners();
    }
    // If null, keep default (false - light mode)
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await PreferencesService.saveDarkModePreference(_isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await PreferencesService.saveDarkModePreference(_isDarkMode);
      notifyListeners();
    }
  }
}
