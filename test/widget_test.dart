// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:agbc_app/services/auth_service.dart';
import 'package:agbc_app/services/supabase_service.dart';
import 'package:agbc_app/services/permissions_service.dart';
import 'package:agbc_app/services/notification_service.dart';
import 'package:agbc_app/screens/login_screen.dart';
import 'package:agbc_app/providers/branches_provider.dart';
import 'package:agbc_app/providers/supabase_provider.dart'; // Added import
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    // Initialize test environment
    await initializeTestEnvironment();

    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  });

  tearDownAll(() async {
    // Cleanup Supabase
    await Supabase.instance.client.auth.signOut();
  });

  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Initialize required services
    final supabaseService = SupabaseService();
    final permissionsService = PermissionsService();
    final notificationService = NotificationService();
    final supabase = Supabase.instance.client;
    final supabaseProvider = SupabaseProvider();

    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthService(
              supabase: supabase,
              supabaseService: supabaseService,
              notificationService: notificationService,
              permissionsService: permissionsService,
            ),
          ),
          ChangeNotifierProvider(
              create: (_) => BranchesProvider(supabaseProvider)),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Wait for any pending animations or async operations
    await tester.pumpAndSettle();

    // Verify that the login screen is displayed
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login to your account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);

    // Cleanup
    await tester.pumpAndSettle();
  });
}
