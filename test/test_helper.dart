import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agbc_app/models/church_branch_model.dart';
import 'package:agbc_app/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockSupabaseProvider extends SupabaseProvider {
  @override
  Stream<List<ChurchBranch>> getAllBranches() {
    return Stream.value(<ChurchBranch>[]);
  }
}

/// Initialize test environment with mocked plugins
Future<void> initializeTestEnvironment() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Mock SharedPreferences before initializing Supabase
  SharedPreferences.setMockInitialValues({});
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    if (methodCall.method == 'getAll') {
      return <String, dynamic>{}; // Return empty map for testing
    }
    if (methodCall.method == 'setString') {
      return true;
    }
    if (methodCall.method == 'remove') {
      return true;
    }
    if (methodCall.method == 'clear') {
      return true;
    }
    return null;
  });

  // Initialize Supabase with test values
  await Supabase.initialize(
    url: 'https://test.supabase.co',
    anonKey: 'test-anon-key',
  );

  // Mock app_links plugin
  const MethodChannel appLinksChannel =
      MethodChannel('com.llfbandit.app_links/messages');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(appLinksChannel, (MethodCall methodCall) async {
    if (methodCall.method == 'getInitialAppLink') {
      return null; // Return null for testing
    }
    return null;
  });
}

/// Helper function to create a mock branch
ChurchBranch createMockBranch({
  String id = 'test-id',
  String name = 'Test Branch',
  String location = 'Test Location',
  String address = 'Test Address',
  String createdBy = 'test-user',
}) {
  return ChurchBranch(
    id: id,
    name: name,
    location: location,
    address: address,
    createdBy: createdBy,
  );
}
