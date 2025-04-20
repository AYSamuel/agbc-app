import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/church_branch_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // User Data
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  
  // Task Data
  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;
  
  // Meeting Data
  List<MeetingModel> _meetings = [];
  List<MeetingModel> get meetings => _meetings;
  
  // Branch Data
  ChurchBranch? _currentBranch;
  ChurchBranch? get currentBranch => _currentBranch;
  
  // Initialize user data
  Future<void> initializeUserData(String uid) async {
    _firestoreService.getUser(uid).listen((user) {
      _currentUser = user;
      if (user != null) {
        if (user.branchId != null) {
          _firestoreService.getBranch(user.branchId!).listen((branch) {
            _currentBranch = branch;
            notifyListeners();
          });
        }
        _loadUserTasks(uid);
        _loadUserMeetings(uid);
      }
      notifyListeners();
    });
  }
  
  // Load user tasks
  void _loadUserTasks(String userId) {
    _firestoreService.getTasksForUser(userId).listen((tasks) {
      _tasks = tasks;
      notifyListeners();
    });
  }
  
  // Load user meetings
  void _loadUserMeetings(String userId) {
    _firestoreService.getMeetingsForUser(userId).listen((meetings) {
      _meetings = meetings;
      notifyListeners();
    });
  }

  // Expose FirestoreService streams
  Stream<List<TaskModel>> getTasksForUser(String userId) {
    return _firestoreService.getTasksForUser(userId);
  }

  Stream<List<MeetingModel>> getMeetingsForUser(String userId) {
    return _firestoreService.getMeetingsForUser(userId);
  }
  
  // Task Operations
  Future<void> createTask(TaskModel task) async {
    await _firestoreService.createTask(task);
    notifyListeners();
  }
  
  Future<void> updateTask(TaskModel task) async {
    await _firestoreService.updateTask(task);
    notifyListeners();
  }
  
  Future<void> deleteTask(String taskId) async {
    await _firestoreService.deleteTask(taskId);
    notifyListeners();
  }
  
  Future<void> addTaskComment(String taskId, String comment) async {
    if (_currentUser != null) {
      await _firestoreService.addCommentToTask(taskId, _currentUser!.uid, comment);
    }
    notifyListeners();
  }
  
  Future<void> updateTaskStatus(String taskId, String status) async {
    await _firestoreService.updateTaskStatus(taskId, status);
    notifyListeners();
  }
  
  // Meeting Operations
  Future<void> createMeeting(MeetingModel meeting) async {
    await _firestoreService.createMeeting(meeting);
    notifyListeners();
  }
  
  Future<void> updateMeeting(MeetingModel meeting) async {
    await _firestoreService.updateMeeting(meeting);
    notifyListeners();
  }
  
  Future<void> deleteMeeting(String meetingId) async {
    await _firestoreService.deleteMeeting(meetingId);
    notifyListeners();
  }
  
  Future<void> updateMeetingAttendance(
    String meetingId,
    String userId,
    bool isAttending,
  ) async {
    await _firestoreService.updateMeetingAttendance(
      meetingId,
      userId,
      isAttending,
    );
    notifyListeners();
  }
  
  // Branch Operations
  Stream<List<ChurchBranch>> getAllBranches() {
    return _firestoreService.branches
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChurchBranch.fromJson({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }))
            .toList());
  }

  Future<void> createBranch(ChurchBranch branch) async {
    await _firestoreService.createBranch(branch);
    notifyListeners();
  }

  Future<void> updateBranch(String branchId, Map<String, dynamic> data) async {
    await _firestoreService.updateBranch(branchId, data);
    notifyListeners();
  }

  Future<void> deleteBranch(String branchId) async {
    await _firestoreService.deleteBranch(branchId);
    notifyListeners();
  }

  Future<void> assignPastorToBranch(String branchId, String pastorId) async {
    await _firestoreService.updateBranch(branchId, {'pastorId': pastorId});
    notifyListeners();
  }

  Future<void> addMemberToBranch(String branchId, String userId) async {
    await _firestoreService.updateBranch(branchId, {
      'members': FieldValue.arrayUnion([userId])
    });
    notifyListeners();
  }

  Future<void> removeMemberFromBranch(String branchId, String userId) async {
    await _firestoreService.updateBranch(branchId, {
      'members': FieldValue.arrayRemove([userId])
    });
    notifyListeners();
  }
  
  // Department Operations
  List<String> getDepartments() {
    return _currentBranch?.departments ?? [];
  }

  // User operations
  Stream<UserModel?> getUser(String uid) {
    return _firestoreService.getUser(uid);
  }

  Future<void> updateUser(UserModel user) async {
    await _firestoreService.updateUser(user);
    notifyListeners();
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestoreService.getAllUsers();
  }

  Stream<List<TaskModel>> getAllTasks() {
    return _firestoreService.getAllTasks();
  }

  Stream<List<MeetingModel>> getAllMeetings() {
    return _firestoreService.getAllMeetings();
  }

  Stream<ChurchBranch?> getBranch(String branchId) {
    return _firestoreService.getBranch(branchId);
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final user = await _firestore.collection('users').doc(userId).get();
      if (user.exists) {
        final data = user.data() as Map<String, dynamic>;
        data['role'] = newRole;
        await _firestore.collection('users').doc(userId).update(data);
      }
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  Future<List<UserModel>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return UserModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }
} 