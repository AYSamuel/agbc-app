import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../providers/supabase_provider.dart';
import '../services/notification_service.dart';
import 'timezone_helper.dart';

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

      // Send notification (this creates database record AND sends push)
      await _notificationService.sendNotification(
        userIds: [assignedUserId],
        title: 'New Task Assigned',
        message:
            '$assignerName assigned you a new task: "$taskTitle". Wanna check it out?',
        data: {
          'type': 'task_assigned', // FIXED: Use correct notification type
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

  /// Send scheduled notification when a task is assigned to a user
  Future<void> notifyTaskAssignmentScheduled({
    required String assignedUserId,
    required String taskTitle,
    required String taskId,
    required String assignedByUserId,
    required DateTime scheduledDateTime,
  }) async {
    try {
      // Get the assigned user's name for the notification
      final assignedByUser =
          await _supabaseProvider.getUserById(assignedByUserId);
      final assignerName = assignedByUser?.fullName ?? 'Someone';

      // Send scheduled notification (this creates database record AND schedules push)
      await _notificationService.scheduleNotification(
        userIds: [assignedUserId],
        title: 'New Task Assigned',
        message:
            '$assignerName assigned you a new task: "$taskTitle". Wanna check it out?',
        data: {
          'type': 'task_assigned',
          'task_id': taskId,
          'screen': 'task_details',
          'deep_link': 'agbcapp://task?id=$taskId',
        },
        scheduledDate: scheduledDateTime,
      );

      debugPrint('Scheduled task assignment notification for user: $assignedUserId at $scheduledDateTime');
    } catch (e) {
      debugPrint('Error sending scheduled task assignment notification: $e');
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

      // Send notification (this creates database record AND sends push)
      await _notificationService.sendNotification(
        userIds: [userId],
        title: 'Role Updated',
        message: '$updaterName updated your role to $newRole',
        data: {
          'type': 'role_changed', // FIXED: Use correct notification type
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

      // Only notify for in_progress and completed status changes
      String title;
      String message;
      String notificationType;

      switch (newStatus) {
        case 'in_progress':
          title = 'Task Started';
          message = '$updaterName has started working on the "$taskTitle" task';
          notificationType = 'task_assigned'; // Use task_assigned type for started tasks
          break;
        case 'completed':
          title = 'Task Completed';
          message = '$updaterName has finished the "$taskTitle" task';
          notificationType = 'task_completed';
          break;
        default:
          // Don't send notifications for pending or cancelled status changes
          return;
      }

      // Send notification (this creates database record AND sends push)
      await _notificationService.sendNotification(
        userIds: [taskCreatorId],
        title: title,
        message: message,
        data: {
          'type': notificationType,
          'task_id': taskId,
          'new_status': newStatus,
          'screen': 'task_details',
          'deep_link': 'agbcapp://task?id=$taskId',
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

      // Send batched notification (this creates database records AND sends push)
      await _notificationService.sendNotification(
        userIds: notifyUserIds,
        title: 'New Comment on Task',
        message: '$commenterName commented on "$taskTitle"',
        data: {
          'type': 'comment_added', // FIXED: Use correct notification type
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

  /// Notify users about a new meeting (immediate notification)
  /// - If invitedUserIds is provided, notifies only those users (invite-only meeting)
  /// - If branchId is provided, notifies branch members (local meeting)
  /// - If both are null, notifies all users (global meeting)
  /// OPTIMIZED: Uses batched notifications grouped by timezone for accurate time display
  Future<void> notifyMeetingCreated({
    required String meetingId,
    required String meetingTitle,
    required DateTime meetingDateTime,
    String? branchId,
    List<String>? invitedUserIds,
    required String organizerName,
  }) async {
    try {
      // Get users based on meeting type:
      // - invite-only: specific invited users
      // - branch: branch members
      // - global: all users
      final users = invitedUserIds != null && invitedUserIds.isNotEmpty
          ? await _supabaseProvider.getUsersByIds(invitedUserIds)
          : branchId != null
              ? await _supabaseProvider.getUsersByBranch(branchId)
              : await _supabaseProvider.getAllUsersList();

      if (users.isNotEmpty) {
        // Group users by timezone for accurate time display
        final usersByTimezone = <String, List<String>>{};
        for (final user in users) {
          final timezone = user.timezone ?? TimezoneHelper.getDeviceTimezone();
          usersByTimezone.putIfAbsent(timezone, () => []).add(user.id);
        }

        // Use the proper title format for initial notification
        final title = formatMeetingNotificationTitle(1440); // Initial notification

        // Send separate batched notifications per timezone group
        for (final entry in usersByTimezone.entries) {
          final timezone = entry.key;
          final userIds = entry.value;

          // Create timezone-specific message
          final message = formatMeetingNotificationMessage(
            userName: '', // Empty - not used for initial notifications
            meetingTitle: meetingTitle,
            meetingDateTime: meetingDateTime,
            reminderMinutes: 1440, // Initial notification (1 day)
            isInitialNotification: true,
            recipientTimezone: timezone,
          );

          await _notificationService.sendNotification(
            userIds: userIds,
            title: title,
            message: message,
            data: {
              'type': 'meeting_reminder', // Use valid notification type
              'meeting_id': meetingId,
              'screen': 'meeting_details',
              'url': 'agbcapp://meeting/$meetingId', // Deep link URL
            },
          );

          debugPrint('Sent notification to ${userIds.length} users in timezone $timezone');
        }

        final meetingType = invitedUserIds != null && invitedUserIds.isNotEmpty
            ? ' (invite-only)'
            : branchId != null
                ? ' in branch'
                : ' (global)';
        debugPrint(
            'Successfully sent batched meeting creation notification to ${users.length} users in ${usersByTimezone.length} timezone(s)$meetingType');
      }
    } catch (e) {
      debugPrint('Error sending meeting creation notifications: $e');
    }
  }

  /// Schedule initial notification for a meeting at a specific date/time
  /// - If invitedUserIds is provided, schedules for those users (invite-only meeting)
  /// - If branchId is provided, schedules for branch members (local meeting)
  /// - If both are null, schedules for all users (global meeting)
  /// OPTIMIZED: Uses batched notifications grouped by timezone for accurate time display
  Future<void> scheduleInitialMeetingNotification({
    required String meetingId,
    required String meetingTitle,
    required DateTime meetingDateTime,
    String? branchId,
    List<String>? invitedUserIds,
    required String organizerName,
    required DateTime scheduledDateTime,
  }) async {
    try {
      // Get users based on meeting type:
      // - invite-only: specific invited users
      // - branch: branch members
      // - global: all users
      final users = invitedUserIds != null && invitedUserIds.isNotEmpty
          ? await _supabaseProvider.getUsersByIds(invitedUserIds)
          : branchId != null
              ? await _supabaseProvider.getUsersByBranch(branchId)
              : await _supabaseProvider.getAllUsersList();

      if (users.isNotEmpty) {
        // Only schedule if the scheduled time is in the future
        if (scheduledDateTime.isAfter(DateTime.now())) {
          // Group users by timezone for accurate time display
          final usersByTimezone = <String, List<String>>{};
          for (final user in users) {
            final timezone = user.timezone ?? TimezoneHelper.getDeviceTimezone();
            usersByTimezone.putIfAbsent(timezone, () => []).add(user.id);
          }

          // Use the proper title format for initial notification
          final title = formatMeetingNotificationTitle(1440); // Initial notification

          // Schedule separate batched notifications per timezone group
          for (final entry in usersByTimezone.entries) {
            final timezone = entry.key;
            final userIds = entry.value;

            // Create timezone-specific message
            final message = formatMeetingNotificationMessage(
              userName: '', // Empty - not used for initial notifications
              meetingTitle: meetingTitle,
              meetingDateTime: meetingDateTime,
              reminderMinutes: 1440, // Initial notification (1 day)
              isInitialNotification: true,
              recipientTimezone: timezone,
            );

            // Schedule notification via OneSignal for this timezone group
            await _notificationService.scheduleNotification(
              userIds: userIds,
              title: title,
              message: message,
              scheduledDate: scheduledDateTime,
              data: {
                'type': 'meeting_reminder',
                'meeting_id': meetingId,
                'screen': 'meeting_details',
                'is_initial_notification': true,
                'url': 'agbcapp://meeting/$meetingId', // Deep link URL
              },
            );

            debugPrint('Scheduled notification for ${userIds.length} users in timezone $timezone');
          }

          final meetingType = invitedUserIds != null && invitedUserIds.isNotEmpty
              ? ' (invite-only)'
              : branchId != null
                  ? ' in branch'
                  : ' (global)';
          debugPrint(
              'Successfully scheduled batched initial meeting notification for ${users.length} users in ${usersByTimezone.length} timezone(s)$meetingType at $scheduledDateTime');
        } else {
          debugPrint(
              'Skipping initial notification scheduling - scheduled time is in the past');
        }
      }
    } catch (e) {
      debugPrint('Error scheduling initial meeting notification: $e');
    }
  }

  /// Schedule meeting reminder notifications using OneSignal's native scheduling
  /// - If invitedUserIds is provided, schedules for those users (invite-only meeting)
  /// - If branchId is provided, schedules for branch members (local meeting)
  /// - If both are null, schedules for all users (global meeting)
  Future<void> scheduleMeetingReminders({
    required String meetingId,
    required String meetingTitle,
    required DateTime meetingDateTime,
    String? branchId,
    List<String>? invitedUserIds,
    required List<int> reminderMinutes,
  }) async {
    try {
      // Get users based on meeting type:
      // - invite-only: specific invited users
      // - branch: branch members
      // - global: all users
      final users = invitedUserIds != null && invitedUserIds.isNotEmpty
          ? await _supabaseProvider.getUsersByIds(invitedUserIds)
          : branchId != null
              ? await _supabaseProvider.getUsersByBranch(branchId)
              : await _supabaseProvider.getAllUsersList();

      // Schedule reminders for each time using OneSignal's native scheduling
      for (final reminderMinute in reminderMinutes) {
        await _scheduleNotificationViaOneSignal(
          supabaseProvider: _supabaseProvider,
          notificationService: _notificationService,
          meetingId: meetingId,
          meetingTitle: meetingTitle,
          meetingDateTime: meetingDateTime,
          branchUsers: users,
          reminderMinutes: reminderMinute,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling meeting reminders: $e');
    }
  }

  /// Schedule a single notification via OneSignal
  /// OPTIMIZED: Uses batched notifications grouped by timezone for accurate time display
  static Future<void> _scheduleNotificationViaOneSignal({
    required SupabaseProvider supabaseProvider,
    required NotificationService notificationService,
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
        // Group users by timezone for accurate time display
        final usersByTimezone = <String, List<String>>{};
        for (final user in branchUsers) {
          final timezone = user.timezone ?? TimezoneHelper.getDeviceTimezone();
          usersByTimezone.putIfAbsent(timezone, () => []).add(user.id as String);
        }

        // Format notification title
        final title = formatMeetingNotificationTitle(reminderMinutes);

        // Schedule separate batched notifications per timezone group
        for (final entry in usersByTimezone.entries) {
          final timezone = entry.key;
          final userIds = entry.value;

          // Create timezone-specific message
          final message = formatMeetingNotificationMessage(
            userName: '', // Empty - will be handled by formatMeetingNotificationMessage
            meetingTitle: meetingTitle,
            meetingDateTime: meetingDateTime,
            reminderMinutes: reminderMinutes,
            isInitialNotification: false,
            recipientTimezone: timezone,
          );

          // Schedule notification via OneSignal for this timezone group
          await notificationService.scheduleNotification(
            userIds: userIds,
            title: title,
            message: message,
            scheduledDate: sendTime,
            data: {
              'type': 'meeting_reminder',
              'meeting_id': meetingId,
              'screen': 'meeting_details',
              'reminder_minutes': reminderMinutes,
              'url': 'agbcapp://meeting/$meetingId', // Deep link URL
            },
          );

          debugPrint('Scheduled reminder for ${userIds.length} users in timezone $timezone');
        }

        debugPrint(
            'Successfully scheduled batched notification for ${branchUsers.length} users in ${usersByTimezone.length} timezone(s) at $reminderMinutes minutes before meeting');
      } else {
        debugPrint(
            'Skipping notification scheduling for $reminderMinutes minutes - send time is in the past');
      }
    } catch (e) {
      debugPrint('Error scheduling notification via OneSignal: $e');
    }
  }

  /// Format meeting notification message based on reminder time
  /// OPTIMIZED: Returns generic messages for batched notifications (no personalization)
  static String formatMeetingNotificationMessage({
    required String userName,
    required String meetingTitle,
    required DateTime meetingDateTime,
    required int reminderMinutes,
    required bool isInitialNotification,
    String recipientTimezone = 'UTC',
  }) {
    // Convert UTC meeting time to recipient's timezone
    final localDateTime = TimezoneHelper.convertFromUtc(meetingDateTime, recipientTimezone);

    final dayName = DateFormat('EEEE').format(localDateTime);
    final formattedDate =
        DateFormat('d\'th of MMMM, yyyy').format(localDateTime);
    final formattedTime = DateFormat('h:mm a').format(localDateTime);

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

      // OPTIMIZED: Generic message for better performance (no user name)
      return 'This is a reminder that "$meetingTitle" starts in $timeValue $timeUnit. U make church complete 😊';
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
