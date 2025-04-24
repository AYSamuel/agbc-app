import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/church_branch_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // User operations
  Stream<UserModel?> getUser(String id) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isNotEmpty ? UserModel.fromJson(data.first) : null);
  }

  Future<void> updateUser(UserModel user) async {
    await _supabase.from('users').update(user.toJson()).eq('id', user.id);
  }

  Stream<List<UserModel>> getAllUsers() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('isActive', true)
        .map((data) => data.map((doc) => UserModel.fromJson(doc)).toList());
  }

  // Task operations
  Stream<List<TaskModel>> getTasksForUser(String userId) {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('assigned_to', userId)
        .map((data) => data.map((doc) => TaskModel.fromJson(doc)).toList());
  }

  Stream<List<TaskModel>> getAllTasks() {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((doc) => TaskModel.fromJson(doc)).toList());
  }

  Future<void> createTask(TaskModel task) async {
    final taskData = task.toJson();
    taskData['assigned_to'] = taskData.remove('assignedTo');
    await _supabase.from('tasks').insert(taskData);
  }

  Future<void> updateTask(TaskModel task) async {
    final taskData = task.toJson();
    taskData['assigned_to'] = taskData.remove('assignedTo');
    await _supabase.from('tasks').update(taskData).eq('id', task.id);
  }

  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }

  Future<void> addCommentToTask(String taskId, String userId, String comment) async {
    await _supabase.from('tasks').update({
      'comments': [
        {
          'userId': userId,
          'comment': comment,
          'timestamp': DateTime.now().toIso8601String(),
        }
      ]
    }).eq('id', taskId);
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _supabase.from('tasks').update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', taskId);
  }

  // Meeting operations
  Stream<List<MeetingModel>> getMeetingsForUser(String userId) {
    return _supabase
        .from('meetings')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((doc) => (doc['invitedUsers'] as List).contains(userId))
            .map((doc) => MeetingModel.fromJson(doc))
            .toList());
  }

  Stream<List<MeetingModel>> getAllMeetings() {
    return _supabase
        .from('meetings')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((doc) => MeetingModel.fromJson(doc)).toList());
  }

  Future<void> createMeeting(MeetingModel meeting) async {
    await _supabase.from('meetings').insert(meeting.toJson());
  }

  Future<void> updateMeeting(MeetingModel meeting) async {
    await _supabase.from('meetings').update(meeting.toJson()).eq('id', meeting.id);
  }

  Future<void> deleteMeeting(String meetingId) async {
    await _supabase.from('meetings').delete().eq('id', meetingId);
  }

  Future<void> updateMeetingAttendance(
    String meetingId,
    String userId,
    bool isAttending,
  ) async {
    await _supabase.from('meetings').update({
      'attendance': [userId]
    }).eq('id', meetingId);
  }

  // Branch operations
  Stream<List<ChurchBranch>> getAllBranches() {
    return _supabase
        .from('branches')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((doc) => ChurchBranch.fromJson(doc)).toList());
  }

  Future<void> createBranch(ChurchBranch branch) async {
    await _supabase.from('branches').insert(branch.toJson());
  }

  Future<void> updateBranch(String branchId, Map<String, dynamic> data) async {
    await _supabase.from('branches').update(data).eq('id', branchId);
  }

  Future<void> deleteBranch(String branchId) async {
    await _supabase.from('branches').delete().eq('id', branchId);
  }

  Stream<ChurchBranch?> getBranch(String branchId) {
    return _supabase
        .from('branches')
        .stream(primaryKey: ['id'])
        .eq('id', branchId)
        .map((data) => data.isNotEmpty ? ChurchBranch.fromJson(data.first) : null);
  }

  // Department Operations
  Future<List<String>> getDepartments(String branchId) async {
    try {
      final data = await _supabase.from('branches').select('departments').eq('id', branchId).single();
      return List<String>.from(data['departments'] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }
} 