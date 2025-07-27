// lib/config/app_config.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A utility class to manage and access application-wide configurations,
/// particularly environment variables loaded from the .env file.
class AppConfig {
  /// Returns the Supabase project URL from environment variables.
  /// Throws an error if the variable is not found, ensuring critical config is present.
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? (throw Exception('SUPABASE_URL not found in .env'));

  /// Returns the Supabase anonymous public key from environment variables.
  /// Throws an error if the variable is not found.
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? (throw Exception('SUPABASE_ANON_KEY not found in .env'));

  /// Returns the OneSignal App ID from environment variables.
  static String get oneSignalAppId => dotenv.env['ONESIGNAL_APP_ID'] ?? (throw Exception('ONESIGNAL_APP_ID not found in .env'));

  /// Loads environment variables from the .env file.
  /// This method must be called before accessing any environment variables.
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }

  // API Base URL (if needed for future external APIs)
  static const String apiBaseUrl = 'https://your-api-base-url.com/api';
}
