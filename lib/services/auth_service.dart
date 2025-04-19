import 'package:flutter/foundation.dart'; // Import for ChangeNotifier
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Import for StreamSubscription
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart'; // Import our custom UserModel
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../services/firestore_service.dart';
import '../services/permissions_service.dart';
import 'package:flutter/material.dart';

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
  @visibleForTesting
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;
  final PermissionsService _permissionsService;
  bool _rememberMe = false;

  // Private variable to store the current user
  @visibleForTesting
  UserModel? _currentUser;
  StreamSubscription<User?>? _authStateSubscription;

  // Getter to access the current user
  UserModel? get currentUser => _currentUser;

  // Getter to check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  // Getter for remember me setting
  bool get rememberMe => _rememberMe;

  // Rate limiting
  @visibleForTesting
  final Map<String, List<DateTime>> _loginAttempts = {};
  @visibleForTesting
  static const int _maxAttempts = 5;
  @visibleForTesting
  static const Duration _attemptWindow = Duration(minutes: 15);
  @visibleForTesting
  static const Duration _lockoutDuration = Duration(minutes: 30);

  AuthService({FirebaseAuth? auth}) 
      : _auth = auth ?? FirebaseAuth.instance,
        _firestoreService = FirestoreService(),
        _permissionsService = PermissionsService();

  Future<void> initialize() async {
    try {
      // Cancel any existing subscription
      await _authStateSubscription?.cancel();
      
      // Set up new auth state listener
      _authStateSubscription = _auth.authStateChanges().listen((User? user) async {
        if (user != null) {
          try {
            DocumentSnapshot userDoc = await _firestoreService.collection('users').doc(user.uid).get();
            
            if (userDoc.exists && userDoc.data() != null) {
              _currentUser = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
            } else {
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
                permissions: PermissionsService.getDefaultPermissions('member'),
                notificationSettings: {
                  'email': true,
                  'push': true,
                },
              );
              await _firestoreService.collection('users').doc(user.uid).set(_currentUser!.toJson());
            }
          } catch (e) {
            debugPrint('Error getting user data: $e');
            _currentUser = null;
          }
        } else {
          _currentUser = null;
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  /// Set the remember me preference
  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    if (kIsWeb) {
      // Only set persistence on web platforms
      if (!value) {
        await _auth.setPersistence(Persistence.NONE);
      } else {
        await _auth.setPersistence(Persistence.LOCAL);
      }
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    try {
      // Cancel the auth state listener
      await _authStateSubscription?.cancel();
      _authStateSubscription = null;

      // Clear the current user
      _currentUser = null;
      notifyListeners();

      // Clear Firebase persistence (web only)
      if (kIsWeb) {
        await _auth.setPersistence(Persistence.NONE);
      }

      // Sign out from Firebase
      await _auth.signOut();

      // Clear any cached data
      _loginAttempts.clear();
    } catch (e) {
      debugPrint('Error during logout: $e');
      throw AuthException('Failed to logout: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  /// Check if an IP is rate limited
  @visibleForTesting
  bool isRateLimited(String ip) {
    final now = DateTime.now();
    final attempts = _loginAttempts[ip] ?? [];
    
    // Remove attempts outside the window
    attempts.removeWhere((attempt) => now.difference(attempt) > _attemptWindow);
    
    if (attempts.length >= _maxAttempts) {
      final lastAttempt = attempts.last;
      if (now.difference(lastAttempt) < _lockoutDuration) {
        return true;
      }
      // Reset attempts if lockout period has passed
      _loginAttempts[ip] = [];
    }
    return false;
  }

  /// Record a login attempt
  @visibleForTesting
  void recordLoginAttempt(String ip) {
    final now = DateTime.now();
    final attempts = _loginAttempts[ip] ?? [];
    attempts.add(now);
    _loginAttempts[ip] = attempts;
  }

  /// Logs in a user with the provided email and password.
  Future<UserModel?> signInWithEmailAndPassword(String email, String password, {String? ip}) async {
    try {
      // Check rate limiting if IP is provided
      if (ip != null && isRateLimited(ip)) {
        throw AuthException('Too many login attempts. Please try again later.');
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (ip != null) {
        recordLoginAttempt(ip);
      }

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
            permissions: PermissionsService.getDefaultPermissions('member'),
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
      if (ip != null) {
        recordLoginAttempt(ip);
      }
      throw AuthException(_handleAuthException(e as FirebaseAuthException));
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
          permissions: PermissionsService.getDefaultPermissions(role),
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
        'permissions': PermissionsService.getDefaultPermissions(newRole),
      });

      // If updating the current user's role, update the local state
      if (userId == _currentUser?.uid) {
        _currentUser = _currentUser?.copyWith(
          role: newRole,
          permissions: PermissionsService.getDefaultPermissions(newRole),
        );
        notifyListeners();
      }
    } catch (e) {
      throw 'Failed to update user role: $e';
    }
  }

  /// Check if the current user has a specific permission
  bool hasPermission(String permission) {
    return _currentUser?.permissions[permission] ?? false;
  }

  /// Check if the current user can perform an action
  bool canPerformAction(String action) {
    return PermissionsService.canPerformAction(_currentUser?.permissions ?? {}, action);
  }

  /// Get tasks based on user's role and permissions
  Stream<List<TaskModel>> getTasksForCurrentUser() {
    if (_currentUser != null) {
      return _firestoreService.getTasksForUser(_currentUser!.uid);
    }
    return Stream.value([]);
  }

  /// Checks if there's a currently authenticated user.
  Future<bool> checkAuthentication() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestoreService.collection('users').doc(user.uid).get();
        
        if (userDoc.exists && userDoc.data() != null) {
          _currentUser = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
          notifyListeners();
          return true;
        }
        return false;
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
      } else {
        throw AuthException('No authenticated user found');
      }
    } catch (e) {
      throw AuthException('Failed to send verification email: $e');
    }
  }

  /// Checks if the current user's email is verified
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      throw AuthException('Failed to check email verification status: $e');
    }
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

  /// Signs out the user and clears all auth state
  Future<void> signOut() async {
    try {
      // Clear the current user first
      _currentUser = null;
      notifyListeners();

      // Sign out from Firebase
      await _auth.signOut();

      // Clear any cached data
      _loginAttempts.clear();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      throw AuthException('Failed to sign out: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw AuthException(_handleAuthException(e as FirebaseAuthException));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePassword(newPassword);
      } else {
        throw AuthException('No authenticated user found');
      }
    } catch (e) {
      throw AuthException(_handleAuthException(e as FirebaseAuthException));
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateEmail(newEmail);
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(email: newEmail);
          await _firestoreService.updateUser(_currentUser!);
          notifyListeners();
        }
      } else {
        throw AuthException('No authenticated user found');
      }
    } catch (e) {
      throw AuthException(_handleAuthException(e as FirebaseAuthException));
    }
  }

  Future<void> updateProfile(String name, String? photoUrl) async {
    try {
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
      } else {
        throw AuthException('No authenticated user found');
      }
    } catch (e) {
      throw AuthException('Failed to update profile: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      if (_auth.currentUser != null) {
        await _firestoreService.collection('users').doc(_auth.currentUser!.uid).delete();
        await _auth.currentUser!.delete();
        _currentUser = null;
        notifyListeners();
      } else {
        throw AuthException('No authenticated user found');
      }
    } catch (e) {
      throw AuthException('Failed to delete account: $e');
    }
  }

  /// Get meetings based on user's role and permissions
  Stream<List<MeetingModel>> getMeetings() {
    if (_currentUser == null) {
      return Stream.value([]);
    }

    if (hasPermission('view_all_meetings')) {
      return _firestoreService.collection('meetings')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => MeetingModel.fromJson(doc.data()))
              .toList());
    } else {
      return _firestoreService
          .collection('meetings')
          .where('invitedUsers', arrayContains: _currentUser!.uid)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => MeetingModel.fromJson(doc.data()))
              .toList());
    }
  }
}
