// lib/services/user_service.dart

import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for database access
import 'package:flutter/foundation.dart';
import '../models/user_model.dart'; // Import the UserModel

/// Service class for handling user-related operations with Firebase.
class UserService with ChangeNotifier {
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Instance of FirebaseAuth for authentication
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instance of Firestore for database access

  UserModel? _currentUser;
  
  UserModel? get currentUser => _currentUser;
  
  UserService() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        _currentUser = await getUserDetails(user.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  /// Fetches user details from Firestore by user ID (UID).
  ///
  /// [uid] is the unique identifier of the user.
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      // Get the document from the 'users' collection where the document ID is the user's UID
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        // If the document exists, parse and return a UserModel instance
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null; // Return null if the user does not exist
    } catch (e) {
      print('Error fetching user details: $e'); // Log any errors that occur
      return null; // Return null in case of an error
    }
  }

  /// Updates user information in Firestore.
  ///
  /// [user] is the UserModel containing updated user information.
  Future<bool> updateUser(UserModel user) async {
    try {
      // Update the user's document in the 'users' collection with new data
      await _firestore.collection('users').doc(user.uid).update(user.toJson());
      _currentUser = user;
      notifyListeners();
      return true; // Return true if the update was successful
    } catch (e) {
      print('Error updating user: $e'); // Log any errors that occur
      return false; // Return false in case of an error
    }
  }

  /// Creates a new user in Firebase Authentication and Firestore.
  ///
  /// [user] is the UserModel containing user information.
  /// [password] is the user's password used for authentication.
  Future<bool> createUser(UserModel user, String password) async {
    try {
      // Create a new user with email and password in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      // After creating the user, save their information to Firestore
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(user.toJson());
      return true; // Return true if the user was created successfully
    } catch (e) {
      print('Error creating user: $e'); // Log any errors that occur
      return false; // Return false in case of an error
    }
  }
}
