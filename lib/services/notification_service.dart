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
    print('Attempting to insert into user_devices: user_id=$userId');
    print('Current auth.uid: ${Supabase.instance.client.auth.currentUser?.id}');

    if (!_isInitialized) {
      debugPrint('OneSignal not initialized, initializing now...');
      await initialize();
    }

    try {
      // Get the device state
      final deviceState = OneSignal.User.pushSubscription;
      final oneSignalUserId = deviceState.id;
      print(
          'DeviceState: id=${deviceState.id}, optedIn=${deviceState.optedIn}');

      debugPrint('=== DEVICE REGISTRATION DEBUG ===');
      debugPrint('Registering device for user: $userId');
      debugPrint('OneSignal Device ID: $oneSignalUserId');
      debugPrint('Device opted in: ${deviceState.optedIn}');

      if (oneSignalUserId != null && deviceState.optedIn == true) {
        // Check if this device is already registered for a different user
        final existingDevice = await _supabase
            .from('user_devices')
            .select('user_id')
            .eq('onesignal_user_id', oneSignalUserId)
            .neq('user_id', userId)
            .maybeSingle();

        if (existingDevice != null) {
          debugPrint(
              'Device was previously registered for user: ${existingDevice['user_id']}');
          debugPrint('Cleaning up previous registration...');

          // Remove the previous user's registration
          await _supabase
              .from('user_devices')
              .delete()
              .eq('user_id', existingDevice['user_id']);
          debugPrint('Previous user registration removed from database');
        }

        // Ensure the device is subscribed first
        debugPrint('Ensuring device is subscribed...');
        await OneSignal.Notifications.requestPermission(true);

        // Set the external user ID - this is crucial for targeting notifications
        debugPrint('Calling OneSignal.login($userId)...');
        await OneSignal.login(userId);
        debugPrint('OneSignal login completed for user: $userId');

        // Wait a moment for OneSignal to process the login
        await Future.delayed(const Duration(seconds: 1));

        // Store the mapping in our database for reference
        print(
            'Upserting into user_devices: user_id=$userId, onesignal_user_id=$oneSignalUserId');
        await _supabase.from('user_devices').upsert({
          'user_id': userId,
          'onesignal_user_id': oneSignalUserId,
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('Device record updated in database');

        debugPrint('Device registered successfully for user: $userId');
        debugPrint(
            'Database record updated with OneSignal User ID: $oneSignalUserId');
      } else {
        debugPrint(
            'Device not ready for notifications. ID: $oneSignalUserId, Opted in: ${deviceState.optedIn}');
        throw Exception('Device not ready for notifications');
      }
    } catch (e) {
      debugPrint('Error registering device: $e');
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
