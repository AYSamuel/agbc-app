import 'package:agbc_app/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      await _notificationService.sendNotification(
        userIds: userIds,
        title: title,
        message: message,
        data: data,
      );
    } catch (e) {
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
      // Get all user IDs from Supabase
      final response = await Supabase.instance.client
          .from('user_devices')
          .select('user_id')
          .neq('onesignal_user_id', '');

      if (response.isNotEmpty) {
        final userIds =
            response.map((user) => user['user_id'] as String).toList();
        await sendNotification(
          userIds: userIds,
          title: title,
          message: message,
          data: data,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
