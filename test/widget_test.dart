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
import 'package:agbc_app/providers/supabase_provider.dart';
import 'package:agbc_app/providers/branches_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'test_helper.dart';

void main() {
  late SupabaseService supabaseService;
  late PermissionsService permissionsService;
  late NotificationService notificationService;
  late SupabaseClient supabase;
  late SupabaseProvider supabaseProvider;
  late BranchesProvider branchesProvider;

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

  setUp(() {
    // Initialize required services
    supabaseService = SupabaseService();
    permissionsService = PermissionsService();
    notificationService = NotificationService();
    supabase = Supabase.instance.client;
    supabaseProvider = SupabaseProvider();
    branchesProvider = BranchesProvider(supabaseProvider);
  });

  tearDown(() async {
    // Clean up any resources
    await Future.delayed(const Duration(milliseconds: 100));
  });

  testWidgets('Login screen smoke test', (WidgetTester tester) async {
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
          ChangeNotifierProvider.value(value: supabaseProvider),
          ChangeNotifierProvider.value(value: branchesProvider),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Wait for any pending microtasks
    await tester.pumpAndSettle();

    // Verify that the login screen is displayed
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login to your account'), findsOneWidget);
    expect(find.byType(TextFormField),
        findsNWidgets(2)); // Email and password fields
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
  });
}
