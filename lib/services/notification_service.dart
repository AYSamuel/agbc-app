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
      await OneSignal.Notifications.requestPermission(true);
      _isInitialized = true;
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
      final deviceState = OneSignal.User.pushSubscription;
      final oneSignalUserId = deviceState.id;

      if (oneSignalUserId != null) {
        await OneSignal.User.addAlias('user_id', userId);

        await _supabase.from('user_devices').upsert({
          'user_id': userId,
          'onesignal_user_id': oneSignalUserId,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error registering device: $e');
      await logError('register_device', e.toString());
      rethrow;
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
      final deviceState = await OneSignal.User.pushSubscription;
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
      final response =
          await _supabase.functions.invoke('send-notification', body: {
        'userIds': userIds,
        'title': title,
        'message': message,
        'data': data,
      });

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
      final response = await _supabase
          .from('user_devices')
          .select('user_id')
          .neq('onesignal_user_id', '');

      if (response.isNotEmpty) {
        final userIds = response
            .map((user) => user['user_id'] as String)
            .where((id) => id.isNotEmpty)
            .toList();

        if (userIds.isNotEmpty) {
          await sendNotification(
            userIds: userIds,
            title: title,
            message: message,
            data: data,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending broadcast notification: $e');
      await logError('send_broadcast_notification', e.toString());
      rethrow;
    }
  }
}

final notificationService = NotificationService();
