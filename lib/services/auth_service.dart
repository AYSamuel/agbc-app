// lib/services/auth_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'notification_service.dart'; // Add this import

/// A service class to manage user authentication (sign-up, sign-in, sign-out)
/// and notify listeners about authentication state changes.
/// This service integrates with your existing UserModel and database schema.
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  UserModel? _currentUserProfile;
  bool _isLoading = false;

  /// Returns the currently authenticated user from Supabase Auth, or null if no user is logged in.
  User? get currentUser => _supabase.auth.currentUser;

  /// Returns the current user's profile from the public.users table
  UserModel? get currentUserProfile => _currentUserProfile;

  /// Returns whether the service is currently loading
  bool get isLoading => _isLoading;

  /// Returns whether a user is currently authenticated
  bool get isAuthenticated => currentUser != null;

  /// Initialize the auth service and load current user profile if authenticated
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (currentUser != null) {
        await _loadUserProfile();
      }
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load the current user's profile from the database
  Future<void> _loadUserProfile() async {
    if (currentUser == null) return;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser!.id)
          .single();

      _currentUserProfile = UserModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // If profile doesn't exist, create one
      await _createUserProfile();
    }
  }

  /// Create a user profile in the public.users table with enhanced data
  Future<void> _createUserProfile({
    String? displayName,
    String? phoneNumber,
    String? location,
    String? role,
    String? branchId,
  }) async {
    if (currentUser == null) return;

    try {
      final userData = {
        'id': currentUser!.id,
        'email': currentUser!.email,
        'display_name': displayName ??
            currentUser!.userMetadata?['display_name'] ??
            currentUser!.email?.split('@').first ??
            'User',
        'phone_number':
            phoneNumber ?? currentUser!.userMetadata?['phone_number'],
        'photo_url': currentUser!.userMetadata?['photo_url'],
        'role': role ?? 'member',
        'is_active': true,
        'email_verified': currentUser!.emailConfirmedAt != null,
        'departments': [],
        'settings': {
          'notifications': {'push': true, 'email': true}
        },
        'metadata': {},
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add location if provided
      if (location != null && location.isNotEmpty) {
        // Parse location string into JSONB format
        final locationParts = location.split(',').map((e) => e.trim()).toList();
        if (locationParts.length >= 2) {
          userData['location'] = {
            'city': locationParts[0],
            'country':
                locationParts.length > 1 ? locationParts[1] : locationParts[0],
          };
        }
      }

      // Add branch if provided
      if (branchId != null) {
        userData['branch_id'] = branchId;
      }

      await _supabase.from('users').insert(userData);
      await _loadUserProfile();
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  /// Enhanced registration method with all required fields
  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
    String phoneNumber,
    String location,
    String role,
    String? branchId,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'phone_number': phoneNumber,
          'location': location,
          'role': role,
          'branch_id': branchId,
        },
      );

      if (response.user != null) {
        // Don't create profile here - let the database trigger handle it
        // This prevents issues with unconfirmed users
        debugPrint('User registered successfully. Profile will be created upon email confirmation.');
      }
    } on AuthException catch (e) {
      debugPrint("Registration error: ${e.message}");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Attempts to sign up a new user with email, password, and display name.
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'phone_number': phoneNumber,
        },
      );

      if (response.user != null) {
        // Don't create profile here - let the database trigger handle it
        debugPrint('User signed up successfully. Profile will be created upon email confirmation.');
      }
    } on AuthException catch (e) {
      debugPrint("Sign up error: ${e.message}");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs in a user with email and password.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Handle remember me functionality
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_email', email);
        await prefs.setString('saved_password', password);
      } else {
        await prefs.remove('remember_me');
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }

      // Try to load user profile, create if doesn't exist
      await _loadUserProfileWithFallback();

      // Update last login time if profile exists
      if (currentUser != null && _currentUserProfile != null) {
        try {
          await _supabase
              .from('users')
              .update({'last_login': DateTime.now().toIso8601String()})
              .eq('id', currentUser!.id);
        } catch (e) {
          debugPrint('Error updating last login: $e');
          // Don't fail sign-in for this
        }

        // Register device for notifications
        try {
          await NotificationService().registerDevice(currentUser!.id);
          debugPrint('Device registered for notifications');
        } catch (e) {
          debugPrint('Error registering device for notifications: $e');
          // Don't fail sign-in for this
        }
      }
    } on AuthException catch (e) {
      debugPrint("Sign in error: ${e.message}");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user profile with fallback to create if missing
  Future<void> _loadUserProfileWithFallback() async {
    if (currentUser == null) return;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser!.id)
          .single();

      _currentUserProfile = UserModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('User profile not found, creating new profile: $e');
      
      // Create profile with data from auth.users metadata
      try {
        await _createUserProfile(
          displayName: currentUser!.userMetadata?['display_name'],
          phoneNumber: currentUser!.userMetadata?['phone_number'],
          location: currentUser!.userMetadata?['location'],
          role: currentUser!.userMetadata?['role'] ?? 'member',
          branchId: currentUser!.userMetadata?['branch_id'],
        );
      } catch (createError) {
        debugPrint('Failed to create user profile: $createError');
        // This is a critical error - user can't proceed without a profile
        throw Exception('Unable to create user profile. Please contact support.');
      }
    }
  }

  /// Send verification email to current user
  Future<void> sendVerificationEmail() async {
    if (currentUser?.email == null) return;

    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: currentUser!.email!,
      );
    } on AuthException catch (e) {
      debugPrint("Send verification email error: ${e.message}");
      rethrow;
    }
  }

  /// Signs out the current user and clears the profile.
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Remove device registration before signing out
      if (currentUser != null) {
        try {
          await NotificationService().removeDevice(currentUser!.id);
          debugPrint('Device unregistered from notifications');
        } catch (e) {
          debugPrint('Error unregistering device: $e');
          // Don't fail sign-out for this
        }
      }

      await _supabase.auth.signOut();
      _currentUserProfile = null;
      
      // Clear remember me data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      
    } catch (e) {
      debugPrint("Sign out error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update the current user's profile
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    Map<String, dynamic>? location,
    List<String>? departments,
    Map<String, dynamic>? notificationSettings,
  }) async {
    if (currentUser == null || _currentUserProfile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updateData['display_name'] = displayName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;
      if (location != null) updateData['location'] = location;
      if (departments != null) updateData['departments'] = departments;
      if (notificationSettings != null) {
        updateData['settings'] = {'notifications': notificationSettings};
      }

      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', currentUser!.id);

      await _loadUserProfile();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if current user has a specific role
  bool hasRole(UserRole role) {
    return _currentUserProfile?.role == role;
  }

  /// Check if current user is admin
  bool get isAdmin => hasRole(UserRole.admin);

  /// Check if current user is pastor
  bool get isPastor => hasRole(UserRole.pastor);

  /// Check if current user is worker
  bool get isWorker => hasRole(UserRole.worker);

  /// Check if current user can manage tasks (admin, pastor, or worker)
  bool get canManageTasks => isAdmin || isPastor || isWorker;

  /// Reset password for the given email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      debugPrint("Reset password error: ${e.message}");
      rethrow;
    }
  }

  /// Resend email confirmation
  Future<void> resendConfirmation(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } on AuthException catch (e) {
      debugPrint("Resend confirmation error: ${e.message}");
      rethrow;
    }
  }
}
