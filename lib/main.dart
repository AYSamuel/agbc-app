// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grace_portal/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/branches_provider.dart';
import 'providers/supabase_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/meetings_screen.dart';
import 'screens/meeting_details_screen.dart';
import 'screens/upcoming_events_screen.dart';
import 'utils/theme.dart';
import 'utils/notification_helper.dart';
import 'models/meeting_model.dart';

// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Store pending notification to handle after app initialization
Map<String, dynamic>? _pendingNotificationData;

/// Handle notification click events from OneSignal
void _handleNotificationClick(Map<String, dynamic>? additionalData) {
  if (additionalData == null) {
    debugPrint('No additional data in notification');
    return;
  }

  debugPrint('Handling notification click with data: $additionalData');

  // Get the current context from the navigator
  final context = navigatorKey.currentContext;
  if (context == null) {
    debugPrint('Navigator context is null, storing pending notification');
    // Store the notification data to handle after app is ready
    _pendingNotificationData = additionalData;
    return;
  }

  // Navigate based on notification data
  _navigateFromNotification(context, additionalData);
}

/// Navigate based on notification data
void _navigateFromNotification(BuildContext context, Map<String, dynamic> additionalData) {
  final type = additionalData['type'] as String?;
  final screen = additionalData['screen'] as String?;

  debugPrint('Navigating from notification - Type: $type, Screen: $screen');

  // Handle different notification types
  switch (type) {
    case 'meeting_reminder':
    case 'meeting':
      final meetingId = additionalData['meeting_id'] as String?;
      if (meetingId != null) {
        _navigateToMeetingDetails(context, meetingId);
      }
      break;

    case 'task_assigned':
    case 'task_completed':
    case 'comment_added':
      final taskId = additionalData['task_id'] as String?;
      if (taskId != null && screen == 'task_details') {
        // Navigate to task details (you'll need to implement this route)
        debugPrint('Navigate to task details: $taskId');
        // TODO: Implement task details navigation when route is available
      }
      break;

    case 'role_changed':
      // Navigate to profile or home
      Navigator.pushNamed(context, '/home');
      break;

    default:
      debugPrint('Unknown notification type: $type');
      // Default to home screen
      Navigator.pushNamed(context, '/home');
  }
}

/// Check and handle any pending notification after app is ready
void handlePendingNotification() {
  if (_pendingNotificationData != null) {
    debugPrint('Processing pending notification: $_pendingNotificationData');

    // Wait a bit for navigation to be ready
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = navigatorKey.currentContext;
      if (context != null) {
        _navigateFromNotification(context, _pendingNotificationData!);
        _pendingNotificationData = null; // Clear after handling
      } else {
        debugPrint('Context still null after delay, will retry');
        // Retry once more
        Future.delayed(const Duration(seconds: 1), () {
          final retryContext = navigatorKey.currentContext;
          if (retryContext != null) {
            _navigateFromNotification(retryContext, _pendingNotificationData!);
            _pendingNotificationData = null;
          } else {
            debugPrint('Failed to get context for pending notification');
            _pendingNotificationData = null; // Clear to avoid infinite retries
          }
        });
      }
    });
  }
}

/// Navigate to meeting details screen
Future<void> _navigateToMeetingDetails(BuildContext context, String meetingId) async {
  try {
    debugPrint('Fetching meeting details for ID: $meetingId');

    // Get the meeting from Supabase
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('meetings')
        .select()
        .eq('id', meetingId)
        .single();

    final meeting = MeetingModel.fromJson(response);

    // Navigate to meeting details screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeetingDetailsScreen(meeting: meeting),
        ),
      );
    }
  } catch (e) {
    debugPrint('Error navigating to meeting details: $e');
    // Show error message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading meeting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

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

    // Initialize OneSignal
    OneSignal.initialize(AppConfig.oneSignalAppId);

    // Set up notification click handler
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('OneSignal notification clicked: ${event.notification.additionalData}');
      _handleNotificationClick(event.notification.additionalData);
    });

    // Initialize services
    final authService = AuthService();
    final notificationService = NotificationService();

    // Initialize services in sequence
    await authService.initialize();
    await notificationService.initialize();

    // Capture OneSignal Player ID for existing logged-in users
    await _capturePlayerIdForExistingUser();

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
          // Provide SupabaseProvider
          ChangeNotifierProvider(create: (_) => SupabaseProvider()),
          // Provide NavigationProvider
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          // Add NotificationProvider with SupabaseProvider dependency
          ChangeNotifierProxyProvider<SupabaseProvider, NotificationProvider>(
            create: (context) => NotificationProvider(
              Provider.of<SupabaseProvider>(context, listen: false),
            ),
            update: (context, supabaseProvider, previous) {
              // Only create new instance if supabaseProvider actually changed
              if (previous != null) {
                // Check if the provider is still valid and the supabase provider hasn't changed
                try {
                  if (previous.supabaseProvider == supabaseProvider && !previous.disposed) {
                    return previous;
                  }
                } catch (e) {
                  // Previous provider is disposed, create new one
                }
              }

              // Create new instance and dispose old one properly
              final newProvider = NotificationProvider(supabaseProvider);
              // Dispose previous provider after a delay to avoid "used after disposed" errors
              if (previous != null) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  try {
                    previous.dispose();
                  } catch (e) {
                    // Ignore disposal errors
                  }
                });
              }
              return newProvider;
            },
          ),
          // Add NotificationHelper as a provider
          ProxyProvider2<SupabaseProvider, NotificationService,
              NotificationHelper>(
            create: (context) => NotificationHelper(
              supabaseProvider: Provider.of<SupabaseProvider>(context, listen: false),
              notificationService: Provider.of<NotificationService>(context, listen: false),
            ),
            update: (context, supabaseProvider, notificationService, previous) =>
                NotificationHelper(
              supabaseProvider: supabaseProvider,
              notificationService: notificationService,
            ),
          ),
        ],
        child: const GracePortalApp(),
      ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
  }
}

/// Capture OneSignal Player ID for existing logged-in users
Future<void> _capturePlayerIdForExistingUser() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Wait for OneSignal to initialize
      await Future.delayed(const Duration(seconds: 2));

      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId != null && playerId.isNotEmpty) {
        // Check if we already have this player ID stored
        final existingUser = await Supabase.instance.client
            .from('users')
            .select('onesignal_player_id')
            .eq('id', user.id)
            .single();

        if (existingUser['onesignal_player_id'] == null ||
            existingUser['onesignal_player_id'] != playerId) {
          // Update with new player ID
          await Supabase.instance.client
              .from('users')
              .update({'onesignal_player_id': playerId}).eq('id', user.id);

          debugPrint(
              'Updated OneSignal Player ID for existing user: $playerId');
        }
      }
    }
  } catch (e) {
    debugPrint('Error capturing Player ID for existing user: $e');
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
    debugPrint('Deep link received: $uri');

    if (uri.scheme == 'agbcapp') {
      switch (uri.host) {
        case 'login':
          Navigator.pushNamed(context, '/login');
          break;
        case 'callback':
          // Handle auth callback
          break;
        case 'task':
          final taskId =
              uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
          if (taskId != null) {
            debugPrint('Deep link task ID: $taskId');
            // TODO: Implement task details navigation when route is available
          }
          break;
        case 'meeting':
          final meetingId =
              uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
          if (meetingId != null) {
            debugPrint('Deep link meeting ID: $meetingId');

            // Check if context is ready
            if (navigatorKey.currentContext == null) {
              debugPrint('Context not ready for deep link, storing as pending notification');
              // Store as pending notification data to be processed after app initialization
              _pendingNotificationData = {
                'type': 'meeting_reminder',
                'meeting_id': meetingId,
                'screen': 'meeting_details',
              };
            } else {
              // Use the same navigation method as notification clicks
              _navigateToMeetingDetails(context, meetingId);
            }
          }
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Use global navigator key
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
        '/meetings': (context) => const MeetingsScreen(),
        '/upcoming-events': (context) => const UpcomingEventsScreen(),
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
