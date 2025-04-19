import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/church_model.dart';
import '../services/notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  // User operations
  /// Gets a user by their uid
  Stream<UserModel?> getUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = uid; // Ensure uid is set
        return UserModel.fromJson(data);
      }
      return null;
    });
  }

  /// Updates a user's data
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toJson());
  }

  /// Gets all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return UserModel.fromJson(data);
      }).toList();
    });
  }

  // Task operations
  Stream<List<TaskModel>> getTasksForUser(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
    });
  }

  Stream<List<TaskModel>> getAllTasks() {
    return _firestore.collection('tasks').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
    });
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

  Future<void> addCommentToTask(String taskId, String userId, String content) async {
    final comment = {
      'content': content,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('tasks').doc(taskId).update({
      'comments': FieldValue.arrayUnion([comment]),
    });
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _firestore.collection('tasks').doc(taskId).update({'status': status});
  }

  // Meeting operations
  Stream<List<MeetingModel>> getMeetingsForUser(String userId) {
    return _firestore
        .collection('meetings')
        .where('attendees', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MeetingModel.fromJson(doc.data())).toList();
    });
  }

  Stream<List<MeetingModel>> getAllMeetings() {
    return _firestore
        .collection('meetings')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
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
    if (isAttending) {
      await _firestore.collection('meetings').doc(meetingId).update({
        'attendees': FieldValue.arrayUnion([userId]),
      });
    } else {
      await _firestore.collection('meetings').doc(meetingId).update({
        'attendees': FieldValue.arrayRemove([userId]),
      });
    }
  }

  // Church operations
  Stream<ChurchModel?> getChurch(String churchId) {
    return _firestore.collection('churches').doc(churchId).snapshots().map((doc) {
      if (doc.exists) {
        return ChurchModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    });
  }

  Future<void> updateChurch(ChurchModel church) async {
    await _firestore.collection('churches').doc(church.id).update(church.toJson());
  }

  // Department Operations
  Future<List<String>> getDepartments(String churchId) async {
    try {
      final doc = await _firestore.collection('churches').doc(churchId).get();
      if (doc.exists) {
        return List<String>.from(doc.data()?['departments'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting departments: $e');
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
        data: {
          'type': 'role_change',
          'newRole': newRole,
          'userName': userName,
        },
      );
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  Stream<List<ChurchModel>> getAllBranches() {
    return _firestore.collection('churches').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChurchModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();
    });
  }

  Future<void> addBranch(ChurchModel branch) async {
    final docRef = await _firestore.collection('churches').add(branch.toJson());
    await docRef.update({'id': docRef.id});
  }

  Future<void> updateBranch(ChurchModel branch) async {
    await _firestore.collection('churches').doc(branch.id).update(branch.toJson());
  }

  Future<void> deleteBranch(String branchId) async {
    await _firestore.collection('churches').doc(branchId).delete();
  }
}