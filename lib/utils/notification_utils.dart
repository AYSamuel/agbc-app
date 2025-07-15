import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grace_portal/services/notification_service.dart';

/// Utility class for sending notifications
class NotificationUtils {
  static final NotificationUtils _instance = NotificationUtils._internal();
  factory NotificationUtils() => _instance;
  NotificationUtils._internal();

  final _notificationService = NotificationService();

  /// Send a notification to specific users
  Future<void> sendNotification({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (userIds.isEmpty) {
        debugPrint('No users to send notification to');
        return;
      }

      await _notificationService.sendNotification(
        userIds: userIds,
        title: title,
        message: message,
        data: data,
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
      await _notificationService.logError(
          'send_notification_util', e.toString());
      rethrow;
    }
  }

  /// Send a notification to all users
  Future<void> sendBroadcastNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await Supabase.instance.client
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
        } else {
          debugPrint('No valid user IDs found for broadcast notification');
        }
      } else {
        debugPrint('No devices registered for notifications');
      }
    } catch (e) {
      debugPrint('Error sending broadcast notification: $e');
      await _notificationService.logError(
          'send_broadcast_notification_util', e.toString());
      rethrow;
    }
  }
}
