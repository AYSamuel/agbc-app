// lib/services/user_service.dart

import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for database access
import 'package:flutter/foundation.dart';
import '../models/user_model.dart'; // Import the UserModel
import 'package:flutter/material.dart';

/// Service class for handling user-related operations with Firebase.
class UserService with ChangeNotifier {
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Instance of FirebaseAuth for authentication
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instance of Firestore for database access

  UserModel? _currentUser;
  Map<String, dynamic>? _currentUserData;
  
  UserModel? get currentUser => _currentUser;
  
  UserService() {
    initialize();
  }

  Future<void> initialize() async {
    try {
      await _loadUserData();
    } catch (e) {
      // Handle error silently in production
    }
  }

  /// Fetches user details from Firestore by user ID (UID).
  ///
  /// [uid] is the unique identifier of the user.
  Future<UserModel?> getUserDetails(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow; // Let the UI handle the error
    }
  }

  /// Updates user information in Firestore.
  ///
  /// [user] is the UserModel containing updated user information.
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toJson());
    } catch (e) {
      rethrow; // Let the UI handle the error
    }
  }

  /// Creates a new user in Firebase Authentication and Firestore.
  ///
  /// [user] is the UserModel containing user information.
  /// [password] is the user's password used for authentication.
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      rethrow; // Let the UI handle the error
    }
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(_currentUser?.uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      rethrow; // Let the UI handle the error
    }
  }

  Future<void> loadUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        _currentUserData = userDoc.data() as Map<String, dynamic>;
        debugPrint('User data loaded successfully');
      } else {
        debugPrint('User document does not exist');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Map<String, dynamic>? get currentUserData => _currentUserData;
}
