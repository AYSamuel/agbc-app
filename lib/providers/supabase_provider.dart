import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/notification_model.dart';
import '../models/initial_notification_config.dart';
import '../utils/notification_helper.dart';
import '../services/notification_service.dart';
import '../models/church_branch_model.dart';
import '../models/meeting_response_model.dart';

class SupabaseProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _error;

  SupabaseClient get supabase => _supabase;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== USERS ====================

  /// Get all users stream
  Stream<List<UserModel>> getAllUsers() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => UserModel.fromJson(json)).toList());
  }

  /// Get a specific user by ID
  Stream<UserModel?> getUser(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isNotEmpty ? UserModel.fromJson(data.first) : null);
  }

  /// Update user
  Future<bool> updateUser(UserModel user) async {
    _setLoading(true);
    try {
      await _supabase.from('users').update(user.toJson()).eq('id', user.id);
      return true;
    } catch (e) {
      _setError('Failed to update user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user role
  Future<bool> updateUserRole(String userId, String newRole) async {
    _setLoading(true);
    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', userId);
      return true;
    } catch (e) {
      _setError('Failed to update user role: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user branch
  Future<bool> updateUserBranch(String userId, String? branchId) async {
    _setLoading(true);
    try {
      await _supabase.from('users').update({
        'branch_id': branchId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      return true;
    } catch (e) {
      _setError('Failed to update user branch: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== BRANCHES ====================

  /// Get all branches stream
  Stream<List<ChurchBranch>> getAllBranches() {
    return _supabase
        .from('church_branches') // Corrected table name
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
            (data) => data.map((json) => ChurchBranch.fromJson(json)).toList());
  }

  /// Create new branch
  Future<bool> createBranch(ChurchBranch branch) async {
    _setLoading(true);
    try {
      // 1. Create the branch first
      await _supabase.from('church_branches').insert(branch.toJson());

      // 2. If a pastor is assigned, update their profile
      if (branch.pastorId != null) {
        await _supabase.from('users').update({
          'branch_id': branch.id,
          'role': 'pastor',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', branch.pastorId!);
      }

      return true;
    } catch (e) {
      _setError('Failed to create branch: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete branch
  Future<bool> deleteBranch(String branchId) async {
    _setLoading(true);
    try {
      await _supabase
          .from('church_branches')
          .delete()
          .eq('id', branchId); // Corrected table name
      return true;
    } catch (e) {
      _setError('Failed to delete branch: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== TASKS ====================

  /// Get all tasks stream
  Stream<List<TaskModel>> getAllTasks() {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => TaskModel.fromJson(json)).toList());
  }

  /// Get user's assigned tasks
  Stream<List<TaskModel>> getUserTasks(String userId) {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('assigned_to', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => TaskModel.fromJson(json)).toList());
  }

  /// Get tasks user is involved in (created by them or assigned to them)
  /// This filters from getAllTasks to only show tasks where user is creator or assignee
  Stream<List<TaskModel>> getUserInvolvedTasks(String userId) {
    return getAllTasks().map((tasks) {
      return tasks.where((task) {
        return task.assignedTo == userId || task.createdBy == userId;
      }).toList();
    });
  }

  /// Create new task
  Future<bool> createTask(TaskModel task) async {
    _setLoading(true);
    try {
      await _supabase.from('tasks').insert(task.toJson());
      return true;
    } catch (e) {
      _setError('Failed to create task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update task
  Future<bool> updateTask(TaskModel task) async {
    _setLoading(true);
    try {
      await _supabase.from('tasks').update(task.toJson()).eq('id', task.id);
      return true;
    } catch (e) {
      _setError('Failed to update task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== MEETINGS ====================

  /// Get all meetings stream
  Stream<List<MeetingModel>> getAllMeetings() {
    return _supabase
        .from('meetings')
        .stream(primaryKey: ['id'])
        .order('start_time', ascending: false)
        .map(
            (data) => data.map((json) => MeetingModel.fromJson(json)).toList());
  }

  /// Create new meeting
  Future<bool> createMeetingWithNotifications(
    MeetingModel meeting,
    List<int> reminderMinutes, {
    NotificationHelper? notificationHelper,
  }) async {
    _setLoading(true);
    try {
      // Create the meeting
      final response = await _supabase
          .from('meetings')
          .insert(meeting.toJson())
          .select()
          .single();

      final meetingId = response['id'];

      // Schedule notifications if reminder minutes are provided
      if (reminderMinutes.isNotEmpty) {
        // Create NotificationHelper if none provided
        final helper = notificationHelper ?? 
            NotificationHelper(
              supabaseProvider: this,
              notificationService: NotificationService(),
            );
        
        await scheduleMeetingNotifications(
          meetingId: meetingId,
          meetingTitle: meeting.title,
          startTime: meeting.dateTime,
          reminderMinutes: reminderMinutes,
          notificationHelper: helper,
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to create meeting: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create new meeting with enhanced initial notification control
  Future<bool> createMeetingWithInitialNotification(
    MeetingModel meeting,
    List<int> reminderMinutes, {
    NotificationHelper? notificationHelper,
  }) async {
    _setLoading(true);
    try {
      // Create the meeting with initial notification config
      final response = await _supabase
          .from('meetings')
          .insert(meeting.toJson())
          .select()
          .single();

      final meetingId = response['id'];

      // Create NotificationHelper if none provided
      final helper = notificationHelper ??
          NotificationHelper(
            supabaseProvider: this,
            notificationService: NotificationService(),
          );

      // IMPORTANT: For recurring meetings, only send/schedule notifications for the parent meeting
      // The database trigger will create child instances, but we should NOT send notifications for all of them at once
      // Notifications for future occurrences should be scheduled separately (via a background job)

      // Handle initial notification based on configuration
      if (meeting.initialNotificationConfig != null &&
          meeting.initialNotificationConfig!.enabled) {

        final config = meeting.initialNotificationConfig!;

        switch (config.timing) {
          case NotificationTiming.immediate:
            // Send immediate notification (for both global and branch-specific meetings)
            await helper.notifyMeetingCreated(
              meetingId: meetingId,
              meetingTitle: meeting.title,
              meetingDateTime: meeting.dateTime,
              organizerName: meeting.organizerName,
              branchId: meeting.branchId, // null for global, specific ID for branch
            );

            // Mark initial notification as sent
            await _updateInitialNotificationStatus(meetingId, true);
            break;

          case NotificationTiming.scheduled:
            if (config.scheduledDateTime != null) {
              // Schedule initial notification for later (for both global and branch-specific)
              await helper.scheduleInitialMeetingNotification(
                meetingId: meetingId,
                meetingTitle: meeting.title,
                meetingDateTime: meeting.dateTime,
                organizerName: meeting.organizerName,
                branchId: meeting.branchId, // null for global, specific ID for branch
                scheduledDateTime: config.scheduledDateTime!,
              );
            }
            break;

          case NotificationTiming.none:
            // No initial notification - do nothing
            break;
        }
      }

      // Schedule reminder notifications if provided
      // ONLY schedule for the parent meeting, NOT for auto-generated instances
      if (reminderMinutes.isNotEmpty) {
        await scheduleMeetingNotifications(
          meetingId: meetingId,
          meetingTitle: meeting.title,
          startTime: meeting.dateTime,
          reminderMinutes: reminderMinutes,
          notificationHelper: helper,
          branchId: meeting.branchId,
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to create meeting with initial notification: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update initial notification status for a meeting
  Future<bool> _updateInitialNotificationStatus(String meetingId, bool sent) async {
    try {
      await _supabase.from('meetings').update({
        'initial_notification_sent': sent,
        'initial_notification_sent_at': sent ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', meetingId);
      return true;
    } catch (e) {
      debugPrint('Error updating initial notification status: $e');
      return false;
    }
  }

  // ==================== MEETING RSVP ====================

  /// Submit or update a meeting response (RSVP)
  Future<bool> submitMeetingResponse({
    required String meetingId,
    required ResponseType responseType,
    String? reason,
  }) async {
    _setLoading(true);
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }

      // Check if user already has a response for this meeting
      final existingResponse = await _supabase
          .from('meeting_responses')
          .select()
          .eq('meeting_id', meetingId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existingResponse != null) {
        // Update existing response
        await _supabase.from('meeting_responses').update({
          'response_type': responseType.value,
          'reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingResponse['id']);
      } else {
        // Create new response
        await _supabase.from('meeting_responses').insert({
          'meeting_id': meetingId,
          'user_id': currentUser.id,
          'response_type': responseType.value,
          'reason': reason,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return true;
    } catch (e) {
      _setError('Failed to submit meeting response: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get current user's response for a specific meeting
  Future<MeetingResponseModel?> getUserMeetingResponse(String meetingId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase
          .from('meeting_responses')
          .select()
          .eq('meeting_id', meetingId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        return MeetingResponseModel.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user meeting response: $e');
      return null;
    }
  }

  /// Get meeting attendance summary (for Pastors/Admins)
  Future<MeetingAttendanceSummary?> getMeetingAttendanceSummary(
      String meetingId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      // Check if user can view attendance data
      final canView = await canViewAttendanceData(meetingId);
      if (!canView) return null;

      final response = await _supabase.rpc('get_meeting_attendance_summary',
          params: {'meeting_uuid': meetingId});

      if (response != null) {
        return MeetingAttendanceSummary.fromJson(response);
      }
      return null;
    } on PostgrestException catch (e) {
      // Handle specific database errors
      if (e.code == '42703' || e.message.contains('column') || e.message.contains('does not exist')) {
        debugPrint('Database schema error in getMeetingAttendanceSummary: ${e.message}');
        debugPrint('This usually means the database functions need to be updated.');
        return null;
      } else if (e.code == '42883' || e.message.contains('function') || e.message.contains('does not exist')) {
        debugPrint('Database function error in getMeetingAttendanceSummary: ${e.message}');
        debugPrint('The get_meeting_attendance_summary function may not exist in the database.');
        return null;
      }
      debugPrint('PostgrestException in getMeetingAttendanceSummary: ${e.message} (Code: ${e.code})');
      return null;
    } catch (e) {
      debugPrint('Unexpected error getting meeting attendance summary: $e');
      return null;
    }
  }

  /// Check if current user can view attendance data for a meeting
  Future<bool> canViewAttendanceData(String meetingId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final response = await _supabase.rpc('can_view_attendance_data', params: {
        'meeting_uuid': meetingId,
      });

      return response == true;
    } on PostgrestException catch (e) {
      // Handle specific database errors
      if (e.code == '42883' || e.message.contains('function') || e.message.contains('does not exist')) {
        debugPrint('Database function error in canViewAttendanceData: ${e.message}');
        debugPrint('The can_view_attendance_data function may not exist in the database.');
        return false;
      }
      debugPrint('PostgrestException in canViewAttendanceData: ${e.message} (Code: ${e.code})');
      return false;
    } catch (e) {
      debugPrint('Unexpected error checking attendance data permissions: $e');
      return false;
    }
  }

  /// Get all responses for a meeting with user details (for Pastors/Admins)
  Future<List<MeetingResponseWithUser>> getMeetingResponsesWithUsers(
      String meetingId) async {
    try {
      final canView = await canViewAttendanceData(meetingId);
      if (!canView) return [];

      final response = await _supabase
          .from('meeting_responses')
          .select('''
            *,
            users:user_id (
              id,
              display_name,
              email,
              photo_url
            )
          ''')
          .eq('meeting_id', meetingId)
          .order('created_at', ascending: false);

      return response
          .map((json) => MeetingResponseWithUser.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting meeting responses with users: $e');
      return [];
    }
  }

  /// Schedule meeting notifications using database function
  Future<void> scheduleMeetingNotifications({
    required String meetingId,
    required String meetingTitle,
    required DateTime startTime,
    required List<int> reminderMinutes,
    required NotificationHelper notificationHelper,
    String? branchId,
  }) async {
    try {
      // Use the notification helper to schedule reminders
      await notificationHelper.scheduleMeetingReminders(
        meetingId: meetingId,
        meetingTitle: meetingTitle,
        meetingDateTime: startTime,
        branchId: branchId, // null for global, specific ID for branch
        reminderMinutes: reminderMinutes,
      );
    } catch (e) {
      debugPrint('Error scheduling meeting notifications: $e');
    }
  }

  /// Get users by branch ID
  Future<List<UserModel>> getUsersByBranch(String branchId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('branch_id', branchId);

      return response.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting users by branch: $e');
      return [];
    }
  }

  /// Get all users as a list (for global meetings/notifications)
  Future<List<UserModel>> getAllUsersList() async {
    try {
      final response = await _supabase.from('users').select();

      return response.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  /// Get unread notification count for current user
  /// OPTIMIZED: Fetches only IDs instead of full records (lighter query)
  /// FILTERED: Only counts immediate or due notifications (excludes future scheduled ones)
  Future<int> getUnreadNotificationCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      debugPrint('Getting unread count for user: $userId');
      if (userId == null) {
        debugPrint('No authenticated user - returning 0');
        return 0;
      }

      // OPTIMIZED: Select only 'id' field instead of all fields
      // This reduces data transfer and improves performance
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .or('scheduled_for.is.null,scheduled_for.lte.${DateTime.now().toIso8601String()}'); // Only count immediate or due notifications

      final count = response.length;
      debugPrint('Unread notification count for user $userId: $count');
      return count;
    } catch (e) {
      debugPrint('Error getting notification count: $e');
      _setError('Failed to get notification count: $e');
      return 0;
    }
  }

  /// Get notifications for current user
  /// OPTIMIZED: Added pagination to prevent memory issues with large notification lists
  /// FILTERED: Only shows immediate notifications or scheduled notifications that are due
  /// Default limit: 50 most recent notifications
  Stream<List<NotificationModel>> getUserNotifications({int limit = 50}) {
    final userId = _supabase.auth.currentUser?.id;
    debugPrint('Setting up notification stream for user: $userId (limit: $limit)');
    if (userId == null) {
      debugPrint('No user ID - returning empty stream');
      return Stream.value([]);
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit) // OPTIMIZED: Limit results to prevent memory issues
        .map((data) {
          final notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
          // Filter out future scheduled notifications (client-side filtering)
          final now = DateTime.now();
          return notifications.where((notification) {
            // Show notification if:
            // 1. It has no scheduled_for (immediate notification), OR
            // 2. Its scheduled_for time has passed or is now
            return notification.scheduledFor == null || notification.scheduledFor!.isBefore(now) || notification.scheduledFor!.isAtSameMomentAs(now);
          }).toList();
        });
  }

  /// Get paginated notifications for current user (for "load more" functionality)
  Future<List<NotificationModel>> getNotificationsPaginated({
    required int offset,
    int limit = 20,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching paginated notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
      return true;
    } catch (e) {
      _setError('Failed to mark notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for current user
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      _setError('Failed to mark all notifications as read: $e');
      return false;
    }
  }

  /// Clear all notifications for current user
  Future<bool> clearAllNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('notifications').delete().eq('user_id', userId);
      return true;
    } catch (e) {
      _setError('Failed to clear all notifications: $e');
      return false;
    }
  }

  /// Create a notification record in the database
  Future<bool> createNotificationRecord({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'related_entity_id': relatedId, // Changed from 'related_id'
        'related_entity_type': 'meeting', // Add the entity type
        'data': data,
        'is_read': false,
        'delivery_status': 'pending',
        'is_push_sent': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      _setError('Failed to create notification record: $e');
      return false;
    }
  }

  /// Create notification records for multiple users
  Future<bool> createNotificationRecords({
    required List<String> userIds,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      final notifications = userIds
          .map((userId) => {
                'user_id': userId,
                'title': title,
                'message': message,
                'type': type,
                'data': data,
                'is_read': false,
                'delivery_status': 'pending',
                'is_push_sent': false,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
          .toList();

      await _supabase.from('notifications').insert(notifications);
      return true;
    } catch (e) {
      _setError('Failed to create notification records: $e');
      return false;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  // ==================== UTILITY METHODS ====================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    if (kDebugMode) {
      debugPrint('SupabaseProvider Error: $error');
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Enhanced task creation with notification support
  Future<void> createTaskWithNotification({
    required String title,
    required String description,
    required String priority,
    required String assignedTo,
    required String branchId,
    DateTime? dueDate,
    NotificationHelper? notificationHelper,
    InitialNotificationConfig? notificationConfig,
  }) async {
    try {
      _setLoading(true);

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Create the task
      final response = await _supabase
          .from('tasks')
          .insert({
            'title': title,
            'description': description,
            'priority': priority,
            'assigned_to': assignedTo,
            'created_by': currentUser.id,
            'branch_id': branchId,
            'due_date': dueDate?.toIso8601String(),
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Send notification if helper is provided, task is assigned to someone else, and config allows it
      if (notificationHelper != null &&
          assignedTo != currentUser.id &&
          notificationConfig != null &&
          notificationConfig.enabled) {

        if (notificationConfig.timing == NotificationTiming.immediate) {
          // Send immediate notification
          await notificationHelper.notifyTaskAssignment(
            assignedUserId: assignedTo,
            taskTitle: title,
            taskId: response['id'],
            assignedByUserId: currentUser.id,
          );
        } else if (notificationConfig.timing == NotificationTiming.scheduled &&
                   notificationConfig.scheduledDateTime != null) {
          // Send scheduled notification
          await notificationHelper.notifyTaskAssignmentScheduled(
            assignedUserId: assignedTo,
            taskTitle: title,
            taskId: response['id'],
            assignedByUserId: currentUser.id,
            scheduledDateTime: notificationConfig.scheduledDateTime!,
          );
        }
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to create task: $e');
      _setLoading(false);
      rethrow;
    }
  }

  /// Enhanced task update with notification support
  Future<void> updateTaskWithNotification({
    required String taskId,
    String? title,
    String? description,
    String? priority,
    String? assignedTo,
    String? status,
    DateTime? dueDate,
    NotificationHelper? notificationHelper,
  }) async {
    try {
      _setLoading(true);

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Get the current task to check for changes
      final currentTask =
          await _supabase.from('tasks').select().eq('id', taskId).single();

      // Prepare update data
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (priority != null) updateData['priority'] = priority;
      if (assignedTo != null) updateData['assigned_to'] = assignedTo;
      if (status != null) updateData['status'] = status;
      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Update the task
      await _supabase.from('tasks').update(updateData).eq('id', taskId);

      // Send notifications if helper is provided
      if (notificationHelper != null) {
        // Notify on assignment change
        if (assignedTo != null &&
            assignedTo != currentTask['assigned_to'] &&
            assignedTo != currentUser.id) {
          await notificationHelper.notifyTaskAssignment(
            assignedUserId: assignedTo,
            taskTitle: title ?? currentTask['title'],
            taskId: taskId,
            assignedByUserId: currentUser.id,
          );
        }

        // Notify on status change
        if (status != null && status != currentTask['status']) {
          await notificationHelper.notifyTaskStatusUpdate(
            taskId: taskId,
            taskTitle: title ?? currentTask['title'],
            newStatus: status,
            updatedByUserId: currentUser.id,
            taskCreatorId: currentTask['created_by'],
          );
        }
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to update task: $e');
      _setLoading(false);
      rethrow;
    }
  }

  /// Enhanced user role update with notification support
  Future<void> updateUserRoleWithNotification({
    required String userId,
    required String newRole,
    NotificationHelper? notificationHelper,
  }) async {
    try {
      _setLoading(true);

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Update the user's role
      await _supabase.from('users').update({
        'role': newRole,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Send notification if helper is provided and not updating own role
      if (notificationHelper != null && userId != currentUser.id) {
        await notificationHelper.notifyRoleUpdate(
          userId: userId,
          newRole: newRole,
          updatedByUserId: currentUser.id,
        );
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to update user role: $e');
      _setLoading(false);
      rethrow;
    }
  }

  /// Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current user's full name
  String get currentUserName =>
      currentUser?.userMetadata?['full_name'] ?? 'Unknown';
}
