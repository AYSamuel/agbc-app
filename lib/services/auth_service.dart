import 'package:flutter/foundation.dart'; // Import for ChangeNotifier
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Import our custom UserModel
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../services/firestore_service.dart';

/// Exception for user-facing authentication errors.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Service class for handling authentication-related operations.
class AuthService with ChangeNotifier {
  // Instance of FirebaseAuth for authentication operations
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Private variable to store the current user
  UserModel? _currentUser;

  // Getter to access the current user
  UserModel? get currentUser => _currentUser;

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        try {
          _firestoreService.getUser(user.uid).listen((userData) {
            if (userData != null) {
              // If user data exists but displayName is empty, use displayName from Firebase Auth
              if (userData.displayName.isEmpty && user.displayName != null) {
                userData = userData.copyWith(displayName: user.displayName!);
                _firestoreService.collection('users').doc(user.uid).update({'displayName': user.displayName!});
              }
              _currentUser = userData;
            } else {
              // If no user data exists, create a basic user document
              _currentUser = UserModel(
                uid: user.uid,
                displayName: user.displayName ?? '',
                email: user.email ?? '',
                role: 'member',
                createdAt: DateTime.now(),
                lastLogin: DateTime.now(),
                isActive: true,
                emailVerified: user.emailVerified,
                departments: [],
                permissions: _getDefaultPermissions('member'),
                notificationSettings: {
                  'email': true,
                  'push': true,
                },
              );
              _firestoreService.collection('users').doc(user.uid).set(_currentUser!.toJson());
            }
            notifyListeners();
          });
        } catch (e) {
          print('Error getting user data: $e');
        }
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  /// Logs in a user with the provided email and password.
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Get the user document from Firestore
        final userDoc = await _firestoreService.collection('users').doc(userCredential.user!.uid).get();
        
        if (userDoc.exists) {
          // If the document exists, create the UserModel with the data
          final data = userDoc.data() as Map<String, dynamic>;
          data['uid'] = userCredential.user!.uid; // Ensure uid is set
          _currentUser = UserModel.fromJson(data);
          notifyListeners();
          return _currentUser;
        } else {
          // If the document doesn't exist, create a basic user document
          final user = UserModel(
            uid: userCredential.user!.uid,
            displayName: userCredential.user!.displayName ?? '',
            email: userCredential.user!.email ?? email,
            role: 'member',
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
            isActive: true,
            emailVerified: userCredential.user!.emailVerified,
            departments: [],
            permissions: _getDefaultPermissions('member'),
            notificationSettings: {
              'email': true,
              'push': true,
            },
          );
          
          // Save the user document to Firestore
          await _firestoreService.collection('users').doc(user.uid).set(user.toJson());
          
          _currentUser = user;
          notifyListeners();
          return user;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Registers a new user with the provided email and password.
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
    String role,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name in Firebase Auth
        await userCredential.user!.updateDisplayName(displayName);

        final user = UserModel(
          uid: userCredential.user!.uid,
          displayName: displayName,
          email: email,
          role: role,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          isActive: true,
          emailVerified: false,
          departments: [],
          permissions: _getDefaultPermissions(role),
          notificationSettings: {
            'email': true,
            'push': true,
          },
        );

        await _firestoreService.collection('users').doc(user.uid).set(user.toJson());
        _currentUser = user;
        notifyListeners();
        return user;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  /// Updates a user's role (only accessible by admins)
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    // Check if current user is admin
    if (_currentUser?.role != 'admin') {
      throw 'Only administrators can update user roles';
    }

    // Validate the new role
    if (!['member', 'worker', 'pastor', 'admin'].contains(newRole)) {
      throw 'Invalid role specified';
    }

    try {
      // Update the user's role in Firestore
      await _firestoreService.collection('users').doc(userId).update({
        'role': newRole,
        'permissions': _getDefaultPermissions(newRole),
      });

      // If updating the current user's role, update the local state
      if (userId == _currentUser?.uid) {
        _currentUser = _currentUser?.copyWith(
          role: newRole,
          permissions: _getDefaultPermissions(newRole),
        );
        notifyListeners();
      }
    } catch (e) {
      throw 'Failed to update user role: $e';
    }
  }

  Map<String, bool> _getDefaultPermissions(String role) {
    switch (role) {
      case 'admin':
        return {
          // User Management
          'manage_users': true,
          'view_users': true,
          'assign_roles': true,

          // Church Management
          'manage_church': true,
          'manage_departments': true,

          // Task Management
          'create_tasks': true,
          'edit_tasks': true,
          'delete_tasks': true,
          'assign_tasks': true,
          'view_all_tasks': true,

          // Meeting Management
          'create_meetings': true,
          'edit_meetings': true,
          'delete_meetings': true,
          'invite_to_meetings': true,
          'view_all_meetings': true,

          // Content Management
          'create_content': true,
          'edit_content': true,
          'delete_content': true,
        };
      case 'pastor':
        return {
          // User Management
          'view_users': true,

          // Task Management
          'create_tasks': true,
          'edit_tasks': true,
          'delete_tasks': true,
          'assign_tasks': true,
          'view_all_tasks': true,

          // Meeting Management
          'create_meetings': true,
          'edit_meetings': true,
          'delete_meetings': true,
          'invite_to_meetings': true,
          'view_all_meetings': true,

          // Content Management
          'create_content': true,
          'edit_content': true,
        };
      case 'worker':
        return {
          // User Management
          'view_users': true,

          // Task Management
          'create_tasks': true,
          'edit_tasks': true,
          'delete_tasks': true,
          'view_all_tasks': true,

          // Meeting Management
          'view_all_meetings': true,

          // Content Management
          'create_content': true,
        };
      case 'member':
      default:
        return {
          // Task Management
          'view_assigned_tasks': true,

          // Meeting Management
          'view_invited_meetings': true,

          // Content Management
          'view_content': true,
        };
    }
  }

  /// Check if the current user has a specific permission
  bool hasPermission(String permission) {
    return _currentUser?.permissions[permission] ?? false;
  }

  /// Check if the current user can perform an action
  bool canPerformAction(String action) {
    switch (action) {
      case 'create_task':
        return hasPermission('create_tasks');
      case 'assign_task':
        return hasPermission('assign_tasks');
      case 'create_meeting':
        return hasPermission('create_meetings');
      case 'invite_to_meeting':
        return hasPermission('invite_to_meetings');
      case 'manage_users':
        return hasPermission('manage_users');
      default:
        return false;
    }
  }

  /// Get tasks based on user's role and permissions
  Stream<List<TaskModel>> getTasksForCurrentUser() {
    if (_currentUser != null) {
      return _firestoreService.getTasksForUser(_currentUser!.uid);
    }
    return Stream.value([]);
  }

  /// Get meetings based on user's role and permissions
  Stream<List<MeetingModel>> getMeetingsForCurrentUser() {
    if (_currentUser != null) {
      return _firestoreService.getMeetingsForUser(_currentUser!.uid);
    }
    return Stream.value([]);
  }

  /// Logs out the current user.
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Checks if there's a currently authenticated user.
  Future<bool> checkAuthentication() async {
    try {
      // Get the current user from FirebaseAuth
      User? user = _auth.currentUser;
      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot userDoc =
            await _firestoreService.collection('users').doc(user.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          _currentUser =
              UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
          notifyListeners();
          return true;
        } else {
          // If no user document exists, create a basic one
          _currentUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            churchId: '',
            role: 'member',
            location: '',
          );
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error in checkAuthentication: $e');
      return false;
    }
  }

  /// Sends a verification email to the current user
  Future<void> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw 'Failed to send verification email: $e';
    }
  }

  /// Checks if the current user's email is verified
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user
          .reload(); // Reload the user to get the latest email verification status
      return user.emailVerified;
    }
    return false;
  }

  String _handleAuthException(FirebaseAuthException e) {
    print(
        'FirebaseAuthException code: [33m${e.code}[0m, message: [36m${e.message}[0m');
    switch (e.code) {
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email & Password accounts are not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'This email is not registered. Please create an account first.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please register if you don\'t have an account.';
      default:
        // Return the actual Firebase error message if available, otherwise a generic message
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updatePassword(String newPassword) async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updatePassword(newPassword);
    }
  }

  Future<void> updateEmail(String newEmail) async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updateEmail(newEmail);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(email: newEmail);
        await _firestoreService.updateUser(_currentUser!);
        notifyListeners();
      }
    }
  }

  Future<void> updateProfile(String name, String? photoUrl) async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(name);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          displayName: name,
          photoUrl: photoUrl,
        );
        await _firestoreService.updateUser(_currentUser!);
        notifyListeners();
      }
    }
  }

  Future<void> deleteAccount() async {
    if (_auth.currentUser != null) {
      await _firestoreService.collection('users').doc(_auth.currentUser!.uid).delete();
      await _auth.currentUser!.delete();
      _currentUser = null;
      notifyListeners();
    }
  }

  /// Getter to check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  Stream<List<Map<String, dynamic>>> getMeetings() {
    if (hasPermission('view_all_meetings')) {
      return _firestoreService.collection('meetings').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    } else {
      return _firestoreService
          .collection('meetings')
          .where('invitedUsers', arrayContains: _currentUser?.uid)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    }
  }
}
