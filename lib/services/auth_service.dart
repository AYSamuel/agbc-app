import 'package:flutter/foundation.dart'; // Import for ChangeNotifier
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Import our custom UserModel

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
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  // Private variable to store the current user
  UserModel? _currentUser;

  // Getter to access the current user
  UserModel? get currentUser => _currentUser;

  // Constructor with dependency injection
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Logs in a user with the provided email and password.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Debug: Attempting to sign in with email: $email');

      // Attempt to sign in with email and password
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Debug: Successfully authenticated with Firebase');

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        print('Debug: Email not verified');
        await _firebaseAuth.signOut();
        throw AuthException('Please verify your email before logging in.');
      }

      print('Debug: Email verified, fetching user data from Firestore');

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        print('Debug: User document found in Firestore');
        final userData = userDoc.data();
        if (userData != null) {
          try {
            // Cast userData to Map<String, dynamic> before accessing its keys
            final Map<String, dynamic> userDataMap =
                userData as Map<String, dynamic>;

            // Create a new user model with default values
            _currentUser = UserModel(
              uid: userCredential.user!.uid,
              email: userCredential.user!.email!,
              displayName: userCredential.user!.displayName ?? '',
              churchId: userDataMap['churchId'] ?? '',
              role: userDataMap['role'] ?? 'member',
              location: userDataMap['location'] ?? '',
              createdAt: userDataMap['createdAt'] != null
                  ? DateTime.parse(userDataMap['createdAt'].toString())
                  : DateTime.now(),
              lastLogin: DateTime.now(),
              isActive: userDataMap['isActive'] ?? true,
              emailVerified: userCredential.user!.emailVerified,
              departments: List<String>.from(userDataMap['departments'] ?? []),
              permissions:
                  Map<String, bool>.from(userDataMap['permissions'] ?? {}),
              notificationSettings: Map<String, dynamic>.from(
                  userDataMap['notificationSettings'] ??
                      {
                        'email': true,
                        'push': true,
                      }),
            );
            print('Debug: Successfully loaded user data');
          } catch (e) {
            print('Error converting user data: $e');
            throw AuthException('Error loading user data. Please try again.');
          }
        } else {
          print('Debug: User data is null');
          throw AuthException('User data is null. Please try again.');
        }
      } else {
        print('Debug: Creating new user document');
        // If no user document exists, create a basic one
        _currentUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName ?? '',
          churchId: '',
          role: 'member',
          location: '',
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

        // Save the new user document to Firestore
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(_currentUser!.toJson());
        print('Debug: Created new user document');
      }

      // Notify listeners that the user state has changed
      notifyListeners();
      print('Debug: Login process completed successfully');
    } on FirebaseAuthException catch (e) {
      print('Debug: Firebase Auth Error: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Too many failed login attempts. Please try again later.';
          break;
        default:
          errorMessage = 'An error occurred during login. Please try again.';
      }
      throw AuthException(errorMessage);
    } catch (e) {
      print('Debug: Unexpected error during login: $e');
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  /// Registers a new user with the provided email and password.
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String location,
  }) async {
    try {
      print('Debug: Starting Firebase user creation');
      // Create user in Firebase Auth
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Debug: User created, sending verification email');
      // Send email verification
      await userCredential.user!.sendEmailVerification();
      print('Debug: Verification email sent');

      print('Debug: Updating display name');
      // Update display name
      await userCredential.user!.updateDisplayName(name);

      print('Debug: Creating user document in Firestore');
      // Create user document in Firestore with default 'member' role
      final userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: name,
        location: location,
        churchId: '', // Empty string as default
        role: 'member', // All new users are registered as members
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        isActive: true,
        emailVerified: false,
        departments: [],
        permissions: _getDefaultPermissions('member'),
        notificationSettings: {
          'email': true,
          'push': true,
        },
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toJson());

      print('Debug: User document created in Firestore');
      _currentUser = userModel;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      print(
          'Debug: Firebase Auth Error: [33m${e.code}[0m - [36m${e.message}[0m');
      throw AuthException(_handleAuthException(e));
    } catch (e) {
      print('Debug: General Error during registration: $e');
      throw AuthException(e.toString());
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
      await _firestore.collection('users').doc(userId).update({
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
  Stream<List<Map<String, dynamic>>> getTasks() {
    if (hasPermission('view_all_tasks')) {
      return _firestore.collection('tasks').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    } else {
      return _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: _currentUser?.uid)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    }
  }

  /// Get meetings based on user's role and permissions
  Stream<List<Map<String, dynamic>>> getMeetings() {
    if (hasPermission('view_all_meetings')) {
      return _firestore.collection('meetings').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    } else {
      return _firestore
          .collection('meetings')
          .where('invitedUsers', arrayContains: _currentUser?.uid)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    // Sign out the current user
    await _firebaseAuth.signOut();
    // Set current user to null
    _currentUser = null;
    // Notify listeners that the user state has changed
    notifyListeners();
  }

  /// Checks if there's a currently authenticated user.
  Future<bool> isAuthenticated() async {
    try {
      // Get the current user from FirebaseAuth
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

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
      print('Error in isAuthenticated: $e');
      return false;
    }
  }

  /// Sends a verification email to the current user
  Future<void> sendVerificationEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw 'Failed to send verification email: $e';
    }
  }

  /// Checks if the current user's email is verified
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
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
}
