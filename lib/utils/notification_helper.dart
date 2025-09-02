import 'package:flutter/foundation.dart';
import '../providers/supabase_provider.dart';
import '../services/notification_service.dart';

class NotificationHelper {
  final SupabaseProvider _supabaseProvider;
  final NotificationService _notificationService;

  NotificationHelper({
    required SupabaseProvider supabaseProvider,
    required NotificationService notificationService,
  })  : _supabaseProvider = supabaseProvider,
        _notificationService = notificationService;

  /// Send notification when a task is assigned to a user
  Future<void> notifyTaskAssignment({
    required String assignedUserId,
    required String taskTitle,
    required String taskId,
    required String assignedByUserId,
  }) async {
    try {
      // Get the assigned user's name for the notification
      final assignedByUser =
          await _supabaseProvider.getUserById(assignedByUserId);
      final assignerName = assignedByUser?.fullName ?? 'Someone';

      // Create notification record in database
      await _supabaseProvider.createNotificationRecord(
        userId: assignedUserId,
        title: 'New Task Assigned',
        message: '$assignerName assigned you a new task: "$taskTitle"',
        type: 'task_assignment',
        relatedId: taskId,
      );

      // Send push notification to the specific user
      await _notificationService.sendNotification(
        userIds: [assignedUserId],
        title: 'New Task Assigned',
        message: '$assignerName assigned you a new task: "$taskTitle"',
        data: {
          'type': 'task_assignment',
          'task_id': taskId,
          'screen': 'task_details',
        },
      );

      debugPrint('Task assignment notification sent to user: $assignedUserId');
    } catch (e) {
      debugPrint('Error sending task assignment notification: $e');
    }
  }

  /// Send notification when a user's role is updated
  Future<void> notifyRoleUpdate({
    required String userId,
    required String newRole,
    required String updatedByUserId,
  }) async {
    try {
      // Get the updater's name for the notification
      final updatedByUser =
          await _supabaseProvider.getUserById(updatedByUserId);
      final updaterName = updatedByUser?.fullName ?? 'An administrator';

      // Create notification record in database
      await _supabaseProvider.createNotificationRecord(
        userId: userId,
        title: 'Role Updated',
        message: '$updaterName updated your role to $newRole',
        type: 'role_update',
        relatedId: userId,
      );

      // Send push notification to the specific user
      await _notificationService.sendNotification(
        userIds: [userId],
        title: 'Role Updated',
        message: '$updaterName updated your role to $newRole',
        data: {
          'type': 'role_update',
          'user_id': userId,
          'new_role': newRole,
          'screen': 'profile',
        },
      );

      debugPrint('Role update notification sent to user: $userId');
    } catch (e) {
      debugPrint('Error sending role update notification: $e');
    }
  }

  /// Send notification when a task status is updated
  Future<void> notifyTaskStatusUpdate({
    required String taskId,
    required String taskTitle,
    required String newStatus,
    required String updatedByUserId,
    required String taskCreatorId,
  }) async {
    try {
      // Don't notify if the updater is the same as the creator
      if (updatedByUserId == taskCreatorId) return;

      // Get the updater's name for the notification
      final updatedByUser =
          await _supabaseProvider.getUserById(updatedByUserId);
      final updaterName = updatedByUser?.fullName ?? 'Someone';

      // Create notification record in database
      await _supabaseProvider.createNotificationRecord(
        userId: taskCreatorId,
        title: 'Task Status Updated',
        message:
            '$updaterName updated the status of "$taskTitle" to $newStatus',
        type: 'task_status_update',
        relatedId: taskId,
      );

      // Send push notification to the task creator
      await _notificationService.sendNotification(
        userIds: [taskCreatorId],
        title: 'Task Status Updated',
        message:
            '$updaterName updated the status of "$taskTitle" to $newStatus',
        data: {
          'type': 'task_status_update',
          'task_id': taskId,
          'new_status': newStatus,
          'screen': 'task_details',
        },
      );

      debugPrint(
          'Task status update notification sent to creator: $taskCreatorId');
    } catch (e) {
      debugPrint('Error sending task status update notification: $e');
    }
  }

  /// Send notification when a comment is added to a task
  Future<void> notifyTaskComment({
    required String taskId,
    required String taskTitle,
    required String commentText,
    required String commentByUserId,
    required List<String> taskParticipantIds, // assignee, creator, etc.
  }) async {
    try {
      // Get the commenter's name
      final commentByUser =
          await _supabaseProvider.getUserById(commentByUserId);
      final commenterName = commentByUser?.fullName ?? 'Someone';

      // Remove the commenter from the notification list
      final notifyUserIds =
          taskParticipantIds.where((id) => id != commentByUserId).toList();

      if (notifyUserIds.isEmpty) return;

      // Create notification records for each participant
      for (final userId in notifyUserIds) {
        await _supabaseProvider.createNotificationRecord(
          userId: userId,
          title: 'New Comment on Task',
          message:
              '$commenterName commented on "$taskTitle": ${commentText.length > 50 ? '${commentText.substring(0, 50)}...' : commentText}',
          type: 'task_comment',
          relatedId: taskId,
        );
      }

      // Send push notification to all participants
      await _notificationService.sendNotification(
        userIds: notifyUserIds,
        title: 'New Comment on Task',
        message: '$commenterName commented on "$taskTitle"',
        data: {
          'type': 'task_comment',
          'task_id': taskId,
          'screen': 'task_details',
        },
      );

      debugPrint(
          'Task comment notifications sent to ${notifyUserIds.length} users');
    } catch (e) {
      debugPrint('Error sending task comment notifications: $e');
    }
  }
}
