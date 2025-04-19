import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// A utility class that provides Firebase configuration options for different platforms.
/// 
/// This class reads Firebase configuration from environment variables and provides
/// the appropriate configuration based on the current platform (iOS, Android, or Web).
class DefaultFirebaseOptions {
  /// Returns the appropriate FirebaseOptions for the current platform.
  /// 
  /// Throws [FirebaseConfigurationError] if required environment variables are missing
  /// or if the platform is not supported.
  static FirebaseOptions get currentPlatform {
    try {
      if (kIsWeb) {
        throw FirebaseConfigurationError('Web platform is not yet supported');
      }

      if (Platform.isIOS) {
        return _getIOSOptions();
      } else if (Platform.isAndroid) {
        return _getAndroidOptions();
      } else {
        throw FirebaseConfigurationError('Unsupported platform');
      }
    } catch (e) {
      throw FirebaseConfigurationError('Failed to get Firebase options: $e');
    }
  }

  static FirebaseOptions _getIOSOptions() {
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    final appId = dotenv.env['FIREBASE_IOS_APP_ID'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'];
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];

    _validateRequiredFields(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
    );

    return FirebaseOptions(
      apiKey: apiKey!,
      appId: appId!,
      messagingSenderId: messagingSenderId!,
      projectId: projectId!,
      authDomain: authDomain,
      storageBucket: storageBucket,
    );
  }

  static FirebaseOptions _getAndroidOptions() {
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    final appId = dotenv.env['FIREBASE_ANDROID_APP_ID'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'];
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];

    _validateRequiredFields(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
    );

    return FirebaseOptions(
      apiKey: apiKey!,
      appId: appId!,
      messagingSenderId: messagingSenderId!,
      projectId: projectId!,
      authDomain: authDomain,
      storageBucket: storageBucket,
    );
  }

  static void _validateRequiredFields({
    required String? apiKey,
    required String? appId,
    required String? messagingSenderId,
    required String? projectId,
  }) {
    if (apiKey == null) {
      throw FirebaseConfigurationError('FIREBASE_API_KEY is missing');
    }
    if (appId == null) {
      throw FirebaseConfigurationError('FIREBASE_APP_ID is missing');
    }
    if (messagingSenderId == null) {
      throw FirebaseConfigurationError('FIREBASE_MESSAGING_SENDER_ID is missing');
    }
    if (projectId == null) {
      throw FirebaseConfigurationError('FIREBASE_PROJECT_ID is missing');
    }
  }
}

/// An exception thrown when there's an error in Firebase configuration.
class FirebaseConfigurationError implements Exception {
  final String message;
  FirebaseConfigurationError(this.message);

  @override
  String toString() => 'FirebaseConfigurationError: $message';
}
