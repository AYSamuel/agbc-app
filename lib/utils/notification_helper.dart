import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
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
        message:
            '$assignerName assigned you a new task: "$taskTitle". Wanna check it out?',
        type: 'task_assignment',
        relatedId: taskId,
      );

      // Send immediate notification
      await _notificationService.sendNotification(
        userIds: [assignedUserId],
        title: 'New Task Assigned',
        message:
            'You have been assigned a new task: "$taskTitle". Wanna check it out?',
        data: {
          'type': 'task_assignment',
          'task_id': taskId,
          'screen': 'task_details',
          'deep_link': 'agbcapp://task?id=$taskId',
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

      // Send immediate notification
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

      // Send immediate notification
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

      // Send immediate notification
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

  /// Notify branch members about a new meeting
  Future<void> notifyMeetingCreated({
    required String meetingId,
    required String meetingTitle,
    required DateTime meetingDateTime,
    required String branchId,
    required String organizerName,
  }) async {
    try {
      // Get all users in the branch
      final branchUsers = await _supabaseProvider.getUsersByBranch(branchId);

      if (branchUsers.isNotEmpty) {
        // Use the proper title format for initial notification
        final title =
            formatMeetingNotificationTitle(1440); // Initial notification

        // Send individual personalized notifications to each user
        for (final user in branchUsers) {
          final userName = user.fullName; // Simplified - no null check needed

          // Create a personalized message for each user
          final message = formatMeetingNotificationMessage(
            userName: userName,
            meetingTitle: meetingTitle,
            meetingDateTime: meetingDateTime,
            reminderMinutes: 1440, // Initial notification (1 day)
            isInitialNotification: true,
          );

          // Send immediate notification to individual user
          await _notificationService.sendNotification(
            userIds: [user.id], // Send to individual user
            title: title,
            message: message,
            data: {
              'type': 'meeting',
              'meeting_id': meetingId,
              'screen': 'meeting_details',
            },
          );
        }

        debugPrint(
            'Successfully sent meeting creation notifications to ${branchUsers.length} users');
      }
    } catch (e) {
      debugPrint('Error sending meeting creation notifications: $e');
    }
  }

  /// Schedule meeting reminder notifications using OneSignal's native scheduling
  Future<void> scheduleMeetingReminders({
    required String meetingId,
    required String meetingTitle,
    required DateTime meetingDateTime,
    required String branchId,
    required List<int> reminderMinutes,
  }) async {
    try {
      // Get all users in the branch
      final branchUsers = await _supabaseProvider.getUsersByBranch(branchId);

      // Schedule reminders for each time using OneSignal's native scheduling
      for (final reminderMinute in reminderMinutes) {
        await _scheduleNotificationViaOneSignal(
          supabaseProvider: _supabaseProvider,
          meetingId: meetingId,
          meetingTitle: meetingTitle,
          meetingDateTime: meetingDateTime,
          branchUsers: branchUsers,
          reminderMinutes: reminderMinute,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling meeting reminders: $e');
    }
  }

  /// Schedule a single notification via OneSignal
  static Future<void> _scheduleNotificationViaOneSignal({
    required SupabaseProvider supabaseProvider,
    required String meetingId,
    required String meetingTitle,
    required DateTime meetingDateTime,
    required List<dynamic> branchUsers,
    required int reminderMinutes,
  }) async {
    try {
      // Calculate when to send the notification
      final sendTime =
          meetingDateTime.subtract(Duration(minutes: reminderMinutes));

      // Only schedule if the send time is in the future
      if (sendTime.isAfter(DateTime.now())) {
        // Format notification title
        final title = formatMeetingNotificationTitle(reminderMinutes);

        // Send individual personalized notifications to each user
        for (final user in branchUsers) {
          final userName = user.fullName; // Simplified - no null check needed

          // Create a personalized message for each user
          final message = formatMeetingNotificationMessage(
            userName: userName,
            meetingTitle: meetingTitle,
            meetingDateTime: meetingDateTime,
            reminderMinutes: reminderMinutes,
            isInitialNotification: false,
          );

          // Schedule notification via OneSignal
          await notificationService.scheduleNotification(
            userIds: [user.id], // Send to individual user
            title: title,
            message: message,
            scheduledDate: sendTime,
            data: {
              'type': 'meeting_reminder',
              'meeting_id': meetingId,
              'screen': 'meeting_details',
              'reminder_minutes': reminderMinutes,
            },
          );
        }

        debugPrint(
            'Successfully scheduled notifications for ${branchUsers.length} users at $reminderMinutes minutes before meeting');
      } else {
        debugPrint(
            'Skipping notification scheduling for $reminderMinutes minutes - send time is in the past');
      }
    } catch (e) {
      debugPrint('Error scheduling notification via OneSignal: $e');
    }
  }

  /// Format meeting notification message based on reminder time
  static String formatMeetingNotificationMessage({
    required String userName,
    required String meetingTitle,
    required DateTime meetingDateTime,
    required int reminderMinutes,
    required bool isInitialNotification,
  }) {
    final dayName = DateFormat('EEEE').format(meetingDateTime);
    final formattedDate =
        DateFormat('d\'th of MMMM, yyyy').format(meetingDateTime);
    final formattedTime = DateFormat('h:mm a').format(meetingDateTime);

    if (isInitialNotification || reminderMinutes >= 1440) {
      return 'Your church family has a meeting on $dayName $formattedDate at $formattedTime. There\'s no church without U 😊';
    } else {
      String timeUnit;
      int timeValue;

      if (reminderMinutes >= 10080) {
        // weeks
        timeValue = reminderMinutes ~/ 10080;
        timeUnit = timeValue == 1 ? 'week' : 'weeks';
      } else if (reminderMinutes >= 1440) {
        // days
        timeValue = reminderMinutes ~/ 1440;
        timeUnit = timeValue == 1 ? 'day' : 'days';
      } else if (reminderMinutes >= 60) {
        // hours
        timeValue = reminderMinutes ~/ 60;
        timeUnit = timeValue == 1 ? 'hour' : 'hours';
      } else {
        // minutes
        timeValue = reminderMinutes;
        timeUnit = timeValue == 1 ? 'minute' : 'minutes';
      }

      return 'Hello $userName, this is a small reminder that your event "$meetingTitle" starts in $timeValue $timeUnit. U make church complete 😊';
    }
  }

  /// Format meeting notification title based on reminder time
  static String formatMeetingNotificationTitle(int reminderMinutes) {
    if (reminderMinutes >= 1440) {
      return 'Meeting scheduled for you';
    } else if (reminderMinutes >= 60) {
      return 'Meeting Reminder';
    } else {
      return 'Meeting Starting Soon';
    }
  }
}
