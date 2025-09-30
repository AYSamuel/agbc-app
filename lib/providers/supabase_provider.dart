import 'package:flutter/foundation.dart';
import 'package:grace_portal/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/notification_model.dart';
import '../utils/notification_helper.dart';
import '../models/church_branch_model.dart';

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

      // Use provided notification helper or create one if not provided
      final helper = notificationHelper ?? NotificationHelper(
        supabaseProvider: this,
        notificationService: NotificationService(),
      );
      
      // Send immediate notification to branch members
      await helper.notifyMeetingCreated(
        meetingId: meetingId,
        meetingTitle: meeting.title,
        meetingDateTime: meeting.dateTime,
        branchId: meeting.branchId!,
        organizerName: meeting.organizerId,
      );

      // Schedule reminder notifications
      if (reminderMinutes.isNotEmpty) {
        await helper.scheduleMeetingReminders(
          meetingId: meetingId,
          meetingTitle: meeting.title,
          meetingDateTime: meeting.dateTime,
          branchId: meeting.branchId!,
          reminderMinutes: reminderMinutes,
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

  /// Schedule meeting notifications using database function
  Future<void> scheduleMeetingNotifications({
    required String meetingId,
    required String meetingTitle,
    required DateTime meetingDateTime,
    required String branchId,
    required List<int> reminderMinutes,
  }) async {
    try {
      // Call the function with custom reminder times
      await _supabase.rpc('schedule_meeting_notifications', params: {
        'meeting_id': meetingId,
        'meeting_title': meetingTitle,
        'meeting_datetime': meetingDateTime.toIso8601String(),
        'branch_id': branchId,
        'reminder_minutes': reminderMinutes, // Pass the custom reminder times
      });
    } catch (e) {
      debugPrint('Error scheduling meeting notifications: $e');
    }
  }

  /// Get unread notification count for current user
  Future<int> getUnreadNotificationCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      debugPrint('Getting unread count for user: $userId');
      if (userId == null) {
        debugPrint('No authenticated user - returning 0');
        return 0;
      }

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      debugPrint(
          'Unread notifications query result: ${response.length} records');
      return response.length;
    } catch (e) {
      debugPrint('Error getting notification count: $e');
      _setError('Failed to get notification count: $e');
      return 0;
    }
  }

  /// Get notifications for current user
  Stream<List<NotificationModel>> getUserNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    debugPrint('Setting up notification stream for user: $userId');
    if (userId == null) {
      debugPrint('No user ID - returning empty stream');
      return Stream.value([]);
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => NotificationModel.fromJson(json)).toList());
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
        'related_entity_id': relatedId,  // Changed from 'related_id'
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

      // Send notification if helper is provided and task is assigned to someone else
      if (notificationHelper != null && assignedTo != currentUser.id) {
        await notificationHelper.notifyTaskAssignment(
          assignedUserId: assignedTo,
          taskTitle: title,
          taskId: response['id'],
          assignedByUserId: currentUser.id,
        );
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
