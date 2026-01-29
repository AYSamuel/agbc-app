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
        title: 'New Assignment 📋',
        message:
            '$assignerName made a task for you: "$taskTitle". Tap to review instructions.',
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
        title: 'New Assignment 📋',
        message:
            '$assignerName made a task for you: "$taskTitle". Tap to review.',
        data: {
          'type': 'task_assigned',
          'task_id': taskId,
          'screen': 'task_details',
          'deep_link': 'agbcapp://task?id=$taskId',
        },
        scheduledDate: scheduledDateTime,
      );

      debugPrint(
          'Scheduled task assignment notification for user: $assignedUserId at $scheduledDateTime');
    } catch (e) {
      debugPrint('Error sending scheduled task assignment notification: $e');
    }
  }

  /// Send notification when a user's role is updated
  Future<void> notifyRoleUpdate({
    required String userId,
    required String newRole,
    required String oldRole,
    required String updatedByUserId,
  }) async {
    try {
      // Get the updater's name for the notification
      final updatedByUser =
          await _supabaseProvider.getUserById(updatedByUserId);
      final updaterName = updatedByUser?.fullName ?? 'An administrator';

      // Use updaterName in debug log to silence unused variable warning
      debugPrint('Role update triggered by: $updaterName');

      // Determine if it's a demotion
      int getRoleRank(String role) {
        switch (role.toLowerCase()) {
          case 'admin':
            return 4;
          case 'pastor':
            return 3;
          case 'worker':
            return 2;
          case 'member':
            return 1;
          default:
            return 0;
        }
      }

      final oldRank = getRoleRank(oldRole);
      final newRank = getRoleRank(newRole);
      final isDemotion = newRank < oldRank;

      String title;
      String message;

      if (isDemotion) {
        // Option A: Warm demotion message
        title = 'Role Update 📋';
        message =
            'We’ve updated your role to $newRole. Thank you for staying with us on this journey!';
      } else {
        // Option A: Warm promotion message
        title = 'Role Update 🌟';
        message = 'Your role is now $newRole. We appreciate everything you do!';
      }

      // Send notification (this creates database record AND sends push)
      await _notificationService.sendNotification(
        userIds: [userId],
        title: title,
        message: message,
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

  /// Schedule reminders for a task
  Future<void> scheduleTaskReminders({
    required String taskId,
    required String taskTitle,
    required DateTime dueDate,
    required String assignedUserId,
  }) async {
    try {
      // Schedule reminder 24 hours before due date
      final reminderTime = dueDate.subtract(const Duration(hours: 24));

      // Only schedule if the reminder time is in the future
      if (reminderTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          userIds: [assignedUserId],
          title: 'Task Due Soon ⏰',
          message: 'Your task "$taskTitle" is due tomorrow. You’ve got this!',
          scheduledDate: reminderTime,
          data: {
            'type': 'task_reminder',
            'task_id': taskId,
            'screen': 'task_details',
            'deep_link': 'agbcapp://task?id=$taskId',
          },
        );
        debugPrint(
            'Scheduled task reminder for user: $assignedUserId at $reminderTime');
      }
    } catch (e) {
      debugPrint('Error scheduling task reminders: $e');
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
          notificationType =
              'task_assigned'; // Use task_assigned type for started tasks
          break;
        case 'completed':
          title = 'Task Completed ✅';
          message = 'The task "$taskTitle" is now finished.';
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
        message: '**$commenterName** commented on "**$taskTitle**"',
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
        final title =
            formatMeetingNotificationTitle(1440); // Initial notification

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

          debugPrint(
              'Sent notification to ${userIds.length} users in timezone $timezone');
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
            final timezone =
                user.timezone ?? TimezoneHelper.getDeviceTimezone();
            usersByTimezone.putIfAbsent(timezone, () => []).add(user.id);
          }

          // Use the proper title format for initial notification
          final title =
              formatMeetingNotificationTitle(1440); // Initial notification

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

            debugPrint(
                'Scheduled notification for ${userIds.length} users in timezone $timezone');
          }

          final meetingType =
              invitedUserIds != null && invitedUserIds.isNotEmpty
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
          usersByTimezone
              .putIfAbsent(timezone, () => [])
              .add(user.id as String);
        }

        // Format notification title
        final title = formatMeetingNotificationTitle(reminderMinutes);

        // Schedule separate batched notifications per timezone group
        for (final entry in usersByTimezone.entries) {
          final timezone = entry.key;
          final userIds = entry.value;

          // Create timezone-specific message
          final message = formatMeetingNotificationMessage(
            userName:
                '', // Empty - will be handled by formatMeetingNotificationMessage
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

          debugPrint(
              'Scheduled reminder for ${userIds.length} users in timezone $timezone');
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
    // Format the date/time in the recipient's timezone
    // Note: We're not showing the time anymore per user request, but keeping the date calculation correct
    final localDateTime =
        TimezoneHelper.convertFromUtc(meetingDateTime, recipientTimezone);

    // Format date only (e.g. "Monday 28th")
    final dateStr = DateFormat('EEEE d').format(localDateTime) +
        _getOrdinalSuffix(localDateTime.day);

    if (isInitialNotification) {
      // Option A: Warm initial invitation
      return 'We’re getting together for $meetingTitle on $dateStr! We’d love to see you there.';
    }

    switch (reminderMinutes) {
      case 1440: // 24 hours / 1 day
        // Option A: Warm 1 day reminder
        return 'Just a reminder that $meetingTitle is happening tomorrow ($dateStr). Can’t wait to see you!';
      case 60: // 1 hour
        // Option A: Warm 1 hour reminder
        return 'We’re starting $meetingTitle in about an hour! Hope you can make it.';
      case 15: // 15 minutes
        // Option A: Warm 15 minute reminder
        return '$meetingTitle is starting very soon! We’re ready for you.';
      default:
        // Generic warm reminder
        return 'Reminder: $meetingTitle is coming up on $dateStr. We look forward to seeing you!';
    }
  }

  /// Format meeting notification title based on reminder time
  static String formatMeetingNotificationTitle(int reminderMinutes) {
    if (reminderMinutes == 1440) {
      return 'Upcoming Gathering 📅'; // Initial/24h
    } else if (reminderMinutes == 60) {
      return 'See You Soon! ⏳'; // 1h
    } else if (reminderMinutes <= 15) {
      return 'Starting Soon 🚀'; // 15m
    } else {
      return 'Event Reminder 🔔'; // Default
    }
  }

  /// Helper to get ordinal suffix (st, nd, rd, th)
  static String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
