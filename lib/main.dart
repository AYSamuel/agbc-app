import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/permissions_service.dart';
import 'providers/supabase_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/email_verification_success_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'utils/theme.dart';
import 'providers/branches_provider.dart';

Future<void> main() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: true, // Enable debug logs to help troubleshoot auth issues
    );

    // Initialize services
    final supabase = Supabase.instance.client;
    final supabaseService = SupabaseService();
    final notificationService = NotificationService();
    final permissionsService = PermissionsService();
    final authService = AuthService(
      supabase: supabase,
      supabaseService: supabaseService,
      notificationService: notificationService,
      permissionsService: permissionsService,
    );

    // Initialize services in sequence
    await permissionsService.initialize();
    await notificationService.initialize();

    // Create providers
    final supabaseProvider = SupabaseProvider();
    final branchesProvider = BranchesProvider(supabaseProvider);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => authService),
          ChangeNotifierProvider.value(value: supabaseProvider),
          Provider.value(value: supabaseService),
          ChangeNotifierProvider(create: (_) => notificationService),
          ChangeNotifierProvider.value(value: branchesProvider),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _handleDeepLink();
  }

  Future<void> _handleDeepLink() async {
    try {
      // Handle links that opened the app
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }

      // Handle incoming links when app is running
      _appLinks.uriLinkStream.listen((uri) {
        _handleUri(uri);
      });
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }

  Future<void> _handleUri(Uri uri) async {
    try {
      if (uri.path == '/verify-email') {
        final token = uri.queryParameters['token'];

        if (token != null) {
          final currentContext = context;
          final authService =
              Provider.of<AuthService>(currentContext, listen: false);

          await authService.verifyEmail(token);

          if (!mounted) return;
          if (!currentContext.mounted) return;

          // Check if user is already authenticated
          if (authService.isAuthenticated) {
            Navigator.of(currentContext).pushReplacementNamed('/home');
          } else {
            Navigator.of(currentContext)
                .pushReplacementNamed('/email-verification-success');
          }
        } else {
          if (!mounted) return;
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid verification link'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      debugPrint('Error handling URI: $e');
      if (!mounted) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying email: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGBC App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/email-verification-success': (context) =>
            const EmailVerificationSuccessScreen(),
        '/home': (context) => const MainNavigationScreen(),
      },
    );
  }
}
