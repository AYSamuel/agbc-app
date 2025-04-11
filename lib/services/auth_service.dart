import 'package:flutter/foundation.dart'; // Import for ChangeNotifier
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Import our custom UserModel

/// Service class for handling authentication-related operations.
class AuthService with ChangeNotifier {
  // Instance of FirebaseAuth for authentication operations
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Private variable to store the current user
  UserModel? _currentUser;

  // Getter to access the current user
  UserModel? get currentUser => _currentUser;

  /// Logs in a user with the provided email and password.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Attempt to sign in with email and password
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        _currentUser = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      } else {
        // If no user document exists, create a basic one
        _currentUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName ?? '',
          churchId: '',
          role: 'member',
          location: '',
        );
      }

      // Notify listeners that the user state has changed
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Registers a new user with the provided email and password.
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String location,
    required String churchId,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user!.updateDisplayName(name);

      // Create user document in Firestore with default 'member' role
      final userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: name,
        phoneNumber: phoneNumber,
        location: location,
        churchId: churchId,
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

      _currentUser = userModel;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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
          'manage_users': true,
          'manage_church': true,
          'manage_meetings': true,
          'manage_tasks': true,
        };
      case 'pastor':
        return {
          'manage_meetings': true,
          'manage_tasks': true,
          'view_members': true,
        };
      case 'worker':
        return {
          'manage_tasks': true,
          'view_members': true,
        };
      case 'member':
      default:
        return {
          'view_meetings': true,
          'view_tasks': true,
        };
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
    // Get the current user from FirebaseAuth
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
          notifyListeners();
          return true; // Return true to indicate a user is signed in
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
    return false; // Return false if no user is signed in
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
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
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
