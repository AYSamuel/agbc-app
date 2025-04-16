import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/church_model.dart';

class FirestoreProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  // User Data
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  
  // Task Data
  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;
  
  // Meeting Data
  List<MeetingModel> _meetings = [];
  List<MeetingModel> get meetings => _meetings;
  
  // Church Data
  ChurchModel? _currentChurch;
  ChurchModel? get currentChurch => _currentChurch;
  
  // Initialize user data
  Future<void> initializeUserData(String uid) async {
    _firestoreService.getUser(uid).listen((user) {
      _currentUser = user;
      if (user != null) {
        _firestoreService.getChurch(user.churchId).listen((church) {
          _currentChurch = church;
          notifyListeners();
        });
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
  
  // Church Operations
  Future<void> updateChurch(ChurchModel church) async {
    await _firestoreService.updateChurch(church);
    _currentChurch = church;
    notifyListeners();
  }
  
  // Department Operations
  List<String> getDepartments() {
    return _currentChurch?.departments ?? [];
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

  Stream<ChurchModel?> getChurch(String churchId) {
    return _firestoreService.getChurch(churchId);
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestoreService.updateUserRole(userId, newRole);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }
} 