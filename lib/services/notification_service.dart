import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;
  bool _isInitialized = false;

Future<void> initialize() async {
  if (_isInitialized) return;

  try {
    // Initialize OneSignal with our App ID (no await here)
    OneSignal.initialize(dotenv.env['ONESIGNAL_APP_ID']!);

    // Request permission for notifications
    await OneSignal.Notifications.requestPermission(true);
    // ... rest of your code
  } catch (e) {
    print('Error initializing OneSignal: $e');
    rethrow;
  }
}


  Future<void> registerDevice(String userId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Get the OneSignal device ID
      final deviceState = await OneSignal.User.pushSubscription;
      final oneSignalUserId = deviceState?.id;

      if (oneSignalUserId != null) {
        // Associate the OneSignal user ID with the Supabase user
        await OneSignal.User.addAlias('user_id', userId);
        
        // Store the OneSignal user ID in Supabase for reference
        await _supabase.from('user_devices').upsert({
          'user_id': userId,
          'onesignal_user_id': oneSignalUserId,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error registering device: $e');
      rethrow;
    }
  }

  Future<void> removeDevice(String userId) async {
    if (!_isInitialized) return;

    try {
      // Remove the external user ID from OneSignal
      await OneSignal.User.removeAlias('user_id');
      
      // Remove the device from Supabase
      await _supabase.from('user_devices').delete().eq('user_id', userId);
    } catch (e) {
      print('Error removing device: $e');
      rethrow;
    }
  }

  Future<String?> getDeviceId() async {
    try {
      final deviceState = await OneSignal.User.pushSubscription;
      return deviceState?.id;
    } catch (e) {
      print('Error getting device ID: $e');
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
      final response = await _supabase.functions.invoke('send-notification', body: {
        'userIds': userIds,
        'title': title,
        'message': message,
        'data': data,
      });

      if (response.status != 200) {
        throw Exception('Failed to send notification: ${response.data}');
      }
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  Future<void> sendBroadcastNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all user IDs from Supabase
      final response = await _supabase
          .from('user_devices')
          .select('user_id')
          .neq('onesignal_user_id', '');

      if (response != null && response.isNotEmpty) {
        final userIds = response.map((user) => user['user_id'] as String).toList();
        await sendNotification(
          userIds: userIds,
          title: title,
          message: message,
          data: data,
        );
      }
    } catch (e) {
      print('Error sending broadcast notification: $e');
      rethrow;
    }
  }
}

final notificationService = NotificationService(); 