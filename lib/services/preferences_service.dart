import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _rememberMeKey = 'remember_me';
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';
  static const String _darkModeKey = 'dark_mode';

  static Future<void> saveLoginCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (rememberMe) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_emailKey, email);
      await prefs.setString(_passwordKey, password);
    } else {
      await clearLoginCredentials();
    }
  }

  static Future<void> clearLoginCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
  }

  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

  static Future<bool?> getDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_darkModeKey)) {
      return prefs.getBool(_darkModeKey);
    }
    return null; // No preference saved yet
  }

  static Future<void> saveDarkModePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDarkMode);
  }
}
