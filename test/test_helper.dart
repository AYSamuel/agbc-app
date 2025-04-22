import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initialize test environment with mocked plugins
Future<void> initializeTestEnvironment() async {
  // Mock SharedPreferences
  const MethodChannel channel = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    if (methodCall.method == 'getAll') {
      return <String, dynamic>{}; // Return empty map for testing
    }
    return null;
  });

  // Initialize SharedPreferences with empty data
  SharedPreferences.setMockInitialValues({});
} 