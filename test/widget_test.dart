import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/services/supabase_service.dart';
import 'package:grace_portal/services/permissions_service.dart';
import 'package:grace_portal/services/notification_service.dart';
import 'package:grace_portal/screens/login_screen.dart';
import 'package:grace_portal/providers/branches_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    // Initialize test environment
    await initializeTestEnvironment();
  });

  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Initialize required services
    final supabaseService = SupabaseService();
    final permissionsService = PermissionsService();
    final notificationService = NotificationService();
    final mockSupabaseProvider = MockSupabaseProvider();

    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthService(
              supabase: Supabase.instance.client,
              supabaseService: supabaseService,
              notificationService: notificationService,
              permissionsService: permissionsService,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => BranchesProvider(mockSupabaseProvider),
          ),
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
