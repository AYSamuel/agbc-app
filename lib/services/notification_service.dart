import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;
  bool _isInitialized = false;

  /// Log errors to Supabase for monitoring
  Future<void> logError(String operation, String error) async {
    try {
      debugPrint('Error in $operation: $error');
      await _supabase.from('error_logs').insert({
        'operation': operation,
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging error: $e');
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing OneSignal...');
      // Initialize OneSignal with our App ID
      final appId = dotenv.env['ONESIGNAL_APP_ID'];
      debugPrint('OneSignal App ID: $appId');

      // Set up logging
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Initialize OneSignal
      OneSignal.initialize(appId!);

      // Set external user ID if available
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        debugPrint('Setting external user ID: ${currentUser.id}');
        await OneSignal.login(currentUser.id);
      }

      // Request permission for notifications
      debugPrint('Requesting notification permission...');
      final permission = await OneSignal.Notifications.requestPermission(true);
      debugPrint('Notification permission status: $permission');

      // Set up notification handlers
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('Notification clicked: ${event.notification.title}');
        // Handle notification click
        if (event.notification.additionalData != null) {
          final data = event.notification.additionalData;
          // Handle deep linking or navigation based on notification data
          debugPrint('Notification data: $data');
        }
      });

      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint(
            'Foreground notification received: ${event.notification.title}');
        // You can prevent the notification from displaying by calling:
        // event.preventDefault();
        // event.notification.display();
      });

      // Check initial subscription state
      final pushSubscription = OneSignal.User.pushSubscription;
      debugPrint('Initial push subscription state:');
      debugPrint('- Opted in: ${pushSubscription.optedIn}');
      debugPrint('- Push token: ${pushSubscription.token}');
      debugPrint('- User ID: ${pushSubscription.id}');

      _isInitialized = true;
      debugPrint('OneSignal initialized successfully');
    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
      await logError('initialize', e.toString());
      rethrow;
    }
  }

  Future<void> registerDevice(String userId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('Registering device for user: $userId');

      // First, ensure we have push subscription
      final pushSubscription = OneSignal.User.pushSubscription;
      debugPrint('Push subscription state: ${pushSubscription.optedIn}');

      if (pushSubscription.optedIn == false) {
        debugPrint('Push subscription not opted in, requesting permission...');
        final permission =
            await OneSignal.Notifications.requestPermission(true);
        debugPrint('Permission result: $permission');
      }

      final oneSignalUserId = pushSubscription.id;
      debugPrint('OneSignal User ID: $oneSignalUserId');

      if (oneSignalUserId != null) {
        debugPrint('Adding user alias to OneSignal...');
        await OneSignal.User.addAlias('user_id', userId);

        // Verify the device is properly registered with OneSignal
        final deviceState = await OneSignal.User.pushSubscription;
        debugPrint('Device state - opted in: ${deviceState.optedIn}');
        debugPrint('Device state - push token: ${deviceState.token}');

        debugPrint('Storing device info in database...');
        await _supabase.from('user_devices').upsert({
          'user_id': userId,
          'onesignal_user_id': oneSignalUserId,
          'push_token': deviceState.token,
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('Device registered successfully');
      } else {
        debugPrint(
            'No OneSignal User ID available - device registration skipped');
      }
    } catch (e) {
      debugPrint('Error registering device: $e');
      await logError('register_device', e.toString());
      // Don't rethrow the error - we don't want to block login
    }
  }

  Future<void> removeDevice(String userId) async {
    if (!_isInitialized) return;

    try {
      await OneSignal.User.removeAlias('user_id');
      await _supabase.from('user_devices').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('Error removing device: $e');
      await logError('remove_device', e.toString());
      rethrow;
    }
  }

  Future<String?> getDeviceId() async {
    try {
      final deviceState = OneSignal.User.pushSubscription;
      return deviceState.id;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      await logError('get_device_id', e.toString());
      return null;
    }
  }

  Future<void> sendNotification({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('=== Starting Send Notification ===');
      debugPrint('Sending notification to users: $userIds');
      debugPrint('Title: $title');
      debugPrint('Message: $message');
      debugPrint('Data: $data');

      final response =
          await _supabase.functions.invoke('send-notification', body: {
        'userIds': userIds,
        'title': title,
        'message': message,
        'data': data,
      });

      debugPrint('Notification response status: ${response.status}');
      debugPrint('Notification response data: ${response.data}');

      if (response.status != 200) {
        throw Exception('Failed to send notification: ${response.data}');
      }
      debugPrint('=== Send Notification Complete ===');
    } catch (e) {
      debugPrint('Error sending notification: $e');
      await logError('send_notification', e.toString());
      rethrow;
    }
  }

  Future<void> sendBroadcastNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('=== Starting Broadcast Notification ===');
      debugPrint('Title: $title');
      debugPrint('Message: $message');

      // Check OneSignal initialization
      debugPrint('OneSignal initialized: $_isInitialized');
      final pushSubscription = OneSignal.User.pushSubscription;
      debugPrint('Push subscription state:');
      debugPrint('- Opted in: ${pushSubscription.optedIn}');
      debugPrint('- Push token: ${pushSubscription.token}');
      debugPrint('- User ID: ${pushSubscription.id}');

      // Get registered devices
      debugPrint('Querying user_devices table...');
      final response = await _supabase
          .from('user_devices')
          .select('user_id, onesignal_user_id, push_token')
          .neq('onesignal_user_id', '');

      debugPrint('Found ${response.length} registered devices');
      debugPrint('Device details: $response');

      if (response.isNotEmpty) {
        final userIds = response
            .map((user) => user['user_id'] as String)
            .where((id) => id.isNotEmpty)
            .toList();

        debugPrint('Sending to user IDs: $userIds');

        if (userIds.isNotEmpty) {
          await sendNotification(
            userIds: userIds,
            title: title,
            message: message,
            data: data,
          );
        } else {
          debugPrint('No valid user IDs found for broadcast notification');
        }
      } else {
        debugPrint('No devices registered for notifications');
      }
      debugPrint('=== Broadcast Notification Complete ===');
    } catch (e) {
      debugPrint('Error sending broadcast notification: $e');
      await logError('send_broadcast_notification', e.toString());
      rethrow;
    }
  }
}

final notificationService = NotificationService();
