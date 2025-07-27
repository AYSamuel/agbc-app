import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/church_branch_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';

class SupabaseProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _error;

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
        .from('church_branch')
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
            (data) => data.map((json) => ChurchBranch.fromJson(json)).toList());
  }

  /// Create new branch
  Future<bool> createBranch(ChurchBranch branch) async {
    _setLoading(true);
    try {
      await _supabase.from('church_branch').insert(branch.toJson());
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
      await _supabase.from('church_branch').delete().eq('id', branchId);
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
        .order('scheduled_date', ascending: false)
        .map(
            (data) => data.map((json) => MeetingModel.fromJson(json)).toList());
  }

  /// Create new meeting
  Future<bool> createMeeting(MeetingModel meeting) async {
    _setLoading(true);
    try {
      await _supabase.from('meetings').insert(meeting.toJson());
      return true;
    } catch (e) {
      _setError('Failed to create meeting: $e');
      return false;
    } finally {
      _setLoading(false);
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
      print('SupabaseProvider Error: $error');
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
