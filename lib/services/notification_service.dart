import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;
  bool _isInitialized = false;

  /// Log errors to Supabase for monitoring
  Future<void> logError(String operation, String error) async {
    try {
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
      // Initialize OneSignal with our App ID
      OneSignal.initialize(dotenv.env['ONESIGNAL_APP_ID']!);

      // Request permission for notifications
      final permission = await OneSignal.Notifications.requestPermission(true);
      debugPrint('Notification permission result: $permission');

      _isInitialized = true;
      debugPrint('OneSignal initialized successfully');
    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
      await logError('initialize', e.toString());
      rethrow;
    }
  }

  Future<void> registerDevice(String userId) async {
    debugPrint('=== DEVICE REGISTRATION STARTED ===');
    debugPrint('User ID: $userId');
    debugPrint('OneSignal initialized: $_isInitialized');

    if (!_isInitialized) {
      debugPrint('OneSignal not initialized, initializing now...');
      await initialize();
    }

    try {
      // Determine platform first
      String platform;
      if (kIsWeb) {
        platform = 'web';
      } else if (Platform.isIOS) {
        platform = 'ios';
      } else if (Platform.isAndroid) {
        platform = 'android';
      } else {
        platform = 'unknown';
      }

      debugPrint('Platform detected: $platform');

      // Ensure the device is subscribed first
      debugPrint('Ensuring device is subscribed...');
      await OneSignal.Notifications.requestPermission(true);

      // IMPORTANT: Logout first to clear any existing external user ID
      debugPrint('Clearing any existing OneSignal session...');
      await OneSignal.logout();
      await Future.delayed(const Duration(seconds: 1));

      // Now login with the new user ID
      debugPrint('Calling OneSignal.login($userId)...');
      await OneSignal.login(userId);
      debugPrint('OneSignal login completed for user: $userId');

      // Wait for OneSignal to process the login and get device state
      await Future.delayed(const Duration(seconds: 2));

      // Get the device state after login
      final deviceState = OneSignal.User.pushSubscription;
      final oneSignalUserId = deviceState.id;
      final pushToken = deviceState.token;
      
      debugPrint('=== DEVICE REGISTRATION DEBUG ===');
      debugPrint('Registering device for user: $userId');
      debugPrint('OneSignal Device ID: $oneSignalUserId');
      debugPrint('Push Token: $pushToken');
      debugPrint('Device opted in: ${deviceState.optedIn}');

      // Generate a unique device ID
      String deviceId;
      if (oneSignalUserId != null && oneSignalUserId.isNotEmpty) {
        deviceId = oneSignalUserId;
        debugPrint('Using OneSignal device ID: $deviceId');
      } else {
        // Generate a fallback device ID using user ID and platform
        deviceId = '${userId}_${platform}_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('Generated fallback device ID: $deviceId');
      }

      // CLEAN UP: Remove ALL existing entries for this user to avoid duplicates
      debugPrint('Cleaning up any existing device registrations for user...');
      await _supabase
          .from('user_devices')
          .delete()
          .eq('user_id', userId);
      debugPrint('Existing registrations cleaned up');

      // Also clean up any entries with the same device_id from other users
      await _supabase
          .from('user_devices')
          .delete()
          .eq('device_id', deviceId);
      debugPrint('Existing device_id registrations cleaned up');

      // Prepare the device data
      final deviceData = {
        'user_id': userId,
        'device_id': deviceId,
        'platform': platform,
        'push_token': pushToken,
        'onesignal_user_id': oneSignalUserId,
        'is_active': true,
        'last_seen': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('Device data to insert: $deviceData');

      // Insert the new record (using insert instead of upsert to avoid conflicts)
      final result = await _supabase.from('user_devices').insert(deviceData);
      debugPrint('Database insert result: $result');

      // Verify the insertion
      final verifyResult = await _supabase
          .from('user_devices')
          .select('id, device_id, platform, onesignal_user_id')
          .eq('user_id', userId)
          .single();

      debugPrint('✅ Device registration verified in database: $verifyResult');
      debugPrint('Device registered successfully for user: $userId');

    } catch (e) {
      debugPrint('❌ Error registering device: $e');
      await logError('register_device', e.toString());
      rethrow;
    }
  }

  Future<void> removeDevice(String userId) async {
    debugPrint('=== DEVICE REMOVAL STARTED ===');
    debugPrint('User ID: $userId');
    debugPrint('OneSignal initialized: $_isInitialized');

    if (!_isInitialized) {
      debugPrint('OneSignal not initialized, skipping device removal');
      return;
    }

    try {
      // Get current device state before logout
      final deviceState = OneSignal.User.pushSubscription;
      final oneSignalUserId = deviceState.id;

      debugPrint('Removing device for user: $userId');
      debugPrint('OneSignal Device ID: $oneSignalUserId');

      // Logout from OneSignal (removes external user ID)
      await OneSignal.logout();
      debugPrint('OneSignal logout completed');

      // Wait a moment for OneSignal to process the logout
      await Future.delayed(const Duration(seconds: 1));

      // Remove from our database
      await _supabase.from('user_devices').delete().eq('user_id', userId);
      debugPrint('Device record removed from database for user: $userId');

      // Clear any existing aliases
      try {
        await OneSignal.User.removeAlias('user_id');
        debugPrint('User alias removed');
      } catch (e) {
        debugPrint('No alias to remove or error removing alias: $e');
      }
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
      debugPrint('Sending notification to users: $userIds');
      debugPrint('Title: $title, Message: $message');

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
      debugPrint('Sending broadcast notification');

      final response = await _supabase
          .from('user_devices')
          .select('user_id')
          .neq('onesignal_user_id', '');

      if (response.isNotEmpty) {
        final userIds = response
            .map((user) => user['user_id'] as String)
            .where((id) => id.isNotEmpty)
            .toList();

        debugPrint('Found ${userIds.length} users with registered devices');

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
    } catch (e) {
      debugPrint('Error sending broadcast notification: $e');
      await logError('send_broadcast_notification', e.toString());
      rethrow;
    }
  }
}

final notificationService = NotificationService();
