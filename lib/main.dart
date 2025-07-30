// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/branches_provider.dart';
import 'providers/supabase_provider.dart'; // Add this import
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'utils/theme.dart';

Future<void> main() async {
  try {
    // Ensure Flutter widgets are initialized before any plugin calls.
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables from .env file.
    await AppConfig.load();

    // Initialize Supabase client with the loaded URL and anonymous key.
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        debug: false, // Set to false in production
      );
    } catch (e) {
      // Ignore specific errors related to code verifier
      if (e.toString().contains('Code verifier could not be found')) {
        debugPrint('Ignoring expected Supabase initialization error: $e');
      } else {
        // Rethrow other errors
        rethrow;
      }
    }

    // Initialize services
    final authService = AuthService();
    final notificationService = NotificationService();

    // Initialize services in sequence
    await authService.initialize();
    await notificationService.initialize();

    // Run the main application widget.
    runApp(
      MultiProvider(
        providers: [
          // Provide AuthService to the widget tree. It will manage authentication state.
          ChangeNotifierProvider(create: (_) => authService),
          // Provide NotificationService
          ChangeNotifierProvider(create: (_) => notificationService),
          // Provide BranchesProvider
          ChangeNotifierProvider(create: (_) => BranchesProvider()),
          // Provide SupabaseProvider - Add this line
          ChangeNotifierProvider(create: (_) => SupabaseProvider()),
        ],
        child: const GracePortalApp(),
      ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
  }
}

/// The root widget of the Grace Portal application.
/// It sets up the MultiProvider for state management and defines the app's theme.
class GracePortalApp extends StatefulWidget {
  const GracePortalApp({super.key});

  @override
  State<GracePortalApp> createState() => _GracePortalAppState();
}

class _GracePortalAppState extends State<GracePortalApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle app launch from deep link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');

    if (uri.scheme == 'agbcapp') {
      switch (uri.host) {
        case 'login':
          // Navigate to login screen
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
          break;
        case 'callback':
          // Handle general callback (legacy support)
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
          break;
        default:
          debugPrint('Unknown deep link path: ${uri.host}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Grace Portal',
      theme: AppTheme.lightTheme, // Apply the light theme
      darkTheme: AppTheme.darkTheme, // Apply the dark theme
      themeMode: ThemeMode.system, // Use system theme preference
      home:
          const AuthGate(), // The initial screen that checks authentication status
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigationScreen(),
      },
    );
  }
}

/// A widget that acts as an authentication gate.
/// It always shows the splash screen first, which handles all initialization and routing.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // ALWAYS show splash screen first - let it handle all initialization
    return const SplashScreen();
  }
}
