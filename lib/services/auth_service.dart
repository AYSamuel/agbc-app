import 'package:flutter/foundation.dart'; // Import for ChangeNotifier
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication
import '../models/user_model.dart'; // Import our custom UserModel

/// Service class for handling authentication-related operations.
class AuthService with ChangeNotifier {
  // Instance of FirebaseAuth for authentication operations
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Private variable to store the current user
  UserModel? _currentUser;

  // Getter to access the current user
  UserModel? get currentUser => _currentUser;

  /// Logs in a user with the provided email and password.
  Future<bool> login(String email, String password) async {
    try {
      // Attempt to sign in with email and password
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If login is successful, create a UserModel from the Firebase User
      _currentUser = UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email!,
        displayName: userCredential.user!.displayName ??
            '', // Use empty string if displayName is null
        churchId: '', // Add churchId if applicable
        role: '', // Add role if applicable
        location: '', // Add location if applicable
      );

      // Notify listeners that the user state has changed
      notifyListeners();
      return true; // Return true to indicate successful login
    } on FirebaseAuthException catch (e) {
      // If a FirebaseAuthException is caught, print the error message
      print('Login failed: ${e.message}');
      return false; // Return false to indicate failed login
    }
  }

  /// Registers a new user with the provided email and password.
  Future<bool> register(String email, String password) async {
    try {
      // Attempt to create a new user with email and password
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If registration is successful, create a UserModel from the Firebase User
      _currentUser = UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email!,
        displayName: userCredential.user!.displayName ??
            '', // Use empty string if displayName is null
        churchId: '', // Add churchId if applicable
        role: '', // Add role if applicable
        location: '', // Add location if applicable
      );

      // Notify listeners that the user state has changed
      notifyListeners();
      return true; // Return true to indicate successful registration
    } on FirebaseAuthException catch (e) {
      // If a FirebaseAuthException is caught, print the error message
      print('Registration failed: ${e.message}');
      return false; // Return false to indicate failed registration
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
  Future<bool> checkAuthStatus() async {
    // Get the current user from FirebaseAuth
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      // If a user is signed in, create a UserModel from the Firebase User
      _currentUser = UserModel(
        uid: user.uid,
        email: user.email!,
        displayName:
            user.displayName ?? '', // Use empty string if displayName is null
        churchId: '', // Add churchId if applicable
        role: '', // Add role if applicable
        location: '', // Add location if applicable
      );
      // Notify listeners that the user state has changed
      notifyListeners();
      return true; // Return true to indicate a user is signed in
    }
    return false; // Return false if no user is signed in
  }
}
