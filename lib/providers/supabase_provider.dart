import 'package:logging/logging.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/church_branch_model.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SupabaseProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final _logger = Logger('SupabaseProvider');

  // Expose SupabaseService
  SupabaseService get supabaseService => _supabaseService;

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

  // Initialize branch data
  Future<void> initializeBranchData(String? branchId) async {
    if (branchId != null) {
      try {
        // First get the branch data immediately
        final branch = await _supabaseService.getBranch(branchId).first;
        _currentBranch = branch;
        notifyListeners();

        // Then set up a listener for updates
        _supabaseService.getBranch(branchId).listen((branch) {
          _currentBranch = branch;
          notifyListeners();
        });
      } catch (e) {
        _logger.severe('Error initializing branch data: $e');
        _currentBranch = null;
        notifyListeners();
      }
    } else {
      _currentBranch = null;
      notifyListeners();
    }
  }

  // Initialize user data
  Future<void> initializeUserData(String id) async {
    try {
      // First get the user data immediately
      final user = await _supabaseService.getUser(id).first;
      _currentUser = user;

      if (user != null) {
        // Initialize branch data
        await initializeBranchData(user.branchId);

        // Set up listeners for updates
        _supabaseService.getUser(id).listen((user) async {
          _currentUser = user;
          if (user != null) {
            // Update branch data if branch ID changes
            if (_currentBranch?.id != user.branchId) {
              await initializeBranchData(user.branchId);
            }
          }
          notifyListeners();
        });

        _loadUserTasks(id);
        _loadUserMeetings(id);
      }
      notifyListeners();
    } catch (e) {
      _logger.severe('Error initializing user data: $e');
      rethrow;
    }
  }

  // Load user tasks
  void _loadUserTasks(String userId) {
    _supabaseService.getTasksForUser(userId).listen((tasks) {
      _tasks = tasks;
      notifyListeners();
    });
  }

  // Load user meetings
  void _loadUserMeetings(String userId) {
    _supabaseService.getMeetingsForUser(userId).listen((meetings) {
      _meetings = meetings;
      notifyListeners();
    });
  }

  // Expose SupabaseService streams
  Stream<List<TaskModel>> getTasksForUser(String userId) {
    return _supabaseService.getTasksForUser(userId);
  }

  Stream<List<MeetingModel>> getMeetingsForUser(String userId) {
    return _supabaseService.getMeetingsForUser(userId);
  }

  // Task Operations
  Future<void> createTask(TaskModel task) async {
    await _supabaseService.createTask(task);
    notifyListeners();
  }

  Future<void> updateTask(TaskModel task) async {
    await _supabaseService.updateTask(task);
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    await _supabaseService.deleteTask(taskId);
    notifyListeners();
  }

  Future<void> addCommentToTask(String taskId, String comment) async {
    await _supabaseService.addCommentToTask(taskId, _currentUser!.id, comment);
    notifyListeners();
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _supabaseService.updateTaskStatus(taskId, status);
    notifyListeners();
  }

  // Meeting Operations
  Future<void> createMeeting(MeetingModel meeting) async {
    await _supabaseService.createMeeting(meeting);
    notifyListeners();
  }

  Future<void> updateMeeting(MeetingModel meeting) async {
    await _supabaseService.updateMeeting(meeting);
    notifyListeners();
  }

  Future<void> deleteMeeting(String meetingId) async {
    await _supabaseService.deleteMeeting(meetingId);
    notifyListeners();
  }

  Future<void> updateMeetingAttendance(
    String meetingId,
    String userId,
    bool isAttending,
  ) async {
    await _supabaseService.updateMeetingAttendance(
      meetingId,
      userId,
      isAttending,
    );
    notifyListeners();
  }

  // Branch Operations
  Stream<List<ChurchBranch>> getAllBranches() {
    return _supabaseService.getAllBranches();
  }

  Future<void> createBranch(ChurchBranch branch) async {
    await _supabaseService.createBranch(branch);
    notifyListeners();
  }

  Future<void> updateBranch(String branchId, Map<String, dynamic> data) async {
    await _supabaseService.updateBranch(branchId, data);
    notifyListeners();
  }

  Future<void> deleteBranch(String branchId) async {
    await _supabaseService.deleteBranch(branchId);
    notifyListeners();
  }

  Future<void> assignPastorToBranch(String branchId, String pastorId) async {
    await _supabaseService.updateBranch(branchId, {'pastorId': pastorId});
    notifyListeners();
  }

  Future<void> addMemberToBranch(String branchId, String userId) async {
    await _supabaseService.updateBranch(branchId, {
      'members': [userId]
    });
    notifyListeners();
  }

  Future<void> removeMemberFromBranch(String branchId, String userId) async {
    await _supabaseService.updateBranch(branchId, {
      'members': [userId]
    });
    notifyListeners();
  }

  // Department Operations
  List<String> getDepartments() {
    return _currentBranch?.departments ?? [];
  }

  // User operations
  Stream<UserModel?> getUser(String id) {
    return _supabaseService.getUser(id);
  }

  Future<void> updateUser(UserModel updatedUser) async {
    try {
      final user = await _supabaseService.updateUser(updatedUser);

      // Update current user if it's the same user
      if (_currentUser?.id == user.id) {
        _currentUser = user;
        // Update current branch if branch ID has changed
        if (_currentBranch?.id != user.branchId) {
          if (user.branchId == null || user.branchId!.isEmpty) {
            _currentBranch = null;
          } else {
            _supabaseService.getBranch(user.branchId!).listen((branch) {
              _currentBranch = branch;
              notifyListeners();
            });
          }
        }
      }

      // Notify AuthService to refresh user data
      final authService =
          Provider.of<AuthService>(navigatorKey.currentContext!, listen: false);
      await authService.refreshUserData();

      notifyListeners();
    } catch (e) {
      _logger.severe('Error updating user: $e');
      rethrow;
    }
  }

  Stream<List<UserModel>> getAllUsers() {
    return _supabaseService.getAllUsers();
  }

  Stream<List<TaskModel>> getAllTasks() {
    return _supabaseService.getAllTasks();
  }

  Stream<List<MeetingModel>> getAllMeetings() {
    return _supabaseService.getAllMeetings();
  }

  Stream<ChurchBranch?> getBranch(String branchId) {
    return _supabaseService.getBranch(branchId);
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final updatedUser =
          await _supabaseService.updateUserRole(userId, newRole);

      // If the updated user is the current user, update the current user
      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  Future<List<UserModel>> getUsers() async {
    try {
      final users = await _supabaseService.getAllUsers().first;
      return users;
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _supabaseService.updateUser(user);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }
}
