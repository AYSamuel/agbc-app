import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/church_branch_model.dart';
import '../services/notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  /// Gets a user by their uid
  Stream<UserModel?> getUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromJson(doc.data()!) : null);
  }

  /// Updates a user's data
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toJson());
  }

  /// Gets all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data()!))
            .toList());
  }

  // Task operations
  Stream<List<TaskModel>> getTasksForUser(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromJson(doc.data()!))
            .toList());
  }

  Stream<List<TaskModel>> getAllTasks() {
    return _firestore
        .collection('tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromJson(doc.data()!))
            .toList());
  }

  Future<void> createTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toJson());
  }

  Future<void> updateTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).update(task.toJson());
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  Future<void> addCommentToTask(String taskId, String userId, String comment) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'comments': FieldValue.arrayUnion([
        {
          'userId': userId,
          'comment': comment,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ])
    });
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Meeting operations
  Stream<List<MeetingModel>> getMeetingsForUser(String userId) {
    return _firestore
        .collection('meetings')
        .where('invitedUsers', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromJson(doc.data()!))
            .toList());
  }

  Stream<List<MeetingModel>> getAllMeetings() {
    return _firestore
        .collection('meetings')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromJson(doc.data()!))
            .toList());
  }

  Future<void> createMeeting(MeetingModel meeting) async {
    await _firestore.collection('meetings').doc(meeting.id).set(meeting.toJson());
  }

  Future<void> updateMeeting(MeetingModel meeting) async {
    await _firestore.collection('meetings').doc(meeting.id).update(meeting.toJson());
  }

  Future<void> deleteMeeting(String meetingId) async {
    await _firestore.collection('meetings').doc(meetingId).delete();
  }

  Future<void> updateMeetingAttendance(
    String meetingId,
    String userId,
    bool isAttending,
  ) async {
    await _firestore.collection('meetings').doc(meetingId).update({
      'attendance': FieldValue.arrayUnion([userId]),
    });
  }

  // Branch operations
  Stream<List<ChurchBranch>> getAllBranches() {
    return _firestore
        .collection('branches')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChurchBranch.fromJson(doc.data()!))
            .toList());
  }

  Future<void> createBranch(ChurchBranch branch) async {
    await _firestore.collection('branches').doc(branch.id).set(branch.toJson());
  }

  Future<void> updateBranch(String branchId, Map<String, dynamic> data) async {
    await _firestore.collection('branches').doc(branchId).update(data);
  }

  Future<void> deleteBranch(String branchId) async {
    await _firestore.collection('branches').doc(branchId).delete();
  }

  Stream<ChurchBranch?> getBranch(String branchId) {
    return _firestore
        .collection('branches')
        .doc(branchId)
        .snapshots()
        .map((doc) => doc.exists ? ChurchBranch.fromJson(doc.data()!) : null);
  }

  // Department Operations
  Future<List<String>> getDepartments(String branchId) async {
    try {
      final doc = await _firestore.collection('branches').doc(branchId).get();
      if (doc.exists) {
        return List<String>.from(doc.data()?['departments'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      // Get the user's FCM token before updating the role
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['displayName'] as String?;

      // Update the role
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });

      // Send notification about role change
      final notificationService = NotificationService();
      await notificationService.sendNotification(
        userId: userId,
        title: 'Role Updated',
        body: 'Your role has been changed to ${newRole.toUpperCase()}',
      );
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Collection access methods
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get tasks => _firestore.collection('tasks');
  CollectionReference get meetings => _firestore.collection('meetings');
  CollectionReference get branches => _firestore.collection('branches');
}