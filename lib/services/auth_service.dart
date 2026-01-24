// lib/services/auth_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

/// A service class to manage user authentication (sign-up, sign-in, sign-out)
/// and notify listeners about authentication state changes.
/// This service integrates with your existing UserModel and database schema.
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  UserModel? _currentUserProfile;
  bool _isLoading = false;

  /// Returns the currently authenticated user from Supabase Auth, or null if no user is logged in.
  User? get currentUser => _supabase.auth.currentUser;

  /// Returns the Supabase client instance
  SupabaseClient get supabase => _supabase;

  /// Returns the current user's profile from the public.users table
  UserModel? get currentUserProfile => _currentUserProfile;

  /// Returns whether the service is currently loading
  bool get isLoading => _isLoading;

  /// Returns whether a user is currently authenticated with a valid profile
  /// A user is considered authenticated only if they have both:
  /// 1. A valid auth session (currentUser != null)
  /// 2. A valid user profile in the database (currentUserProfile != null)
  bool get isAuthenticated => currentUser != null && _currentUserProfile != null;

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

      // If user profile doesn't exist in database, sign out the user
      // This handles the case where a user was deleted from the backend
      if (currentUser != null && _currentUserProfile == null) {
        debugPrint('User profile not found in database - signing out user');
        await signOut();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
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
      // Prepare location data as JSONB
      Map<String, dynamic>? locationData;
      if (location.isNotEmpty) {
        final locationParts = location.split(',').map((e) => e.trim()).toList();
        locationData = {
          'city': locationParts[0],
          'country':
              locationParts.length > 1 ? locationParts[1] : locationParts[0],
        };
      }

      // Prepare notification settings
      final notificationSettings = {
        'push_enabled': true,
        'email_enabled': true,
        'task_notifications': true,
        'general_notifications': true,
        'meeting_notifications': true
      };

      // Sign up with all metadata - let the database trigger handle profile creation
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://aysamuel.github.io/agbc-app/email-confirmed.html',
        data: {
          'display_name': displayName,
          'phone_number': phoneNumber.isNotEmpty ? phoneNumber : null,
          'location': locationData,
          'role': role,
          'branch_id':
              (branchId != null && branchId.isNotEmpty) ? branchId : null,
          'notification_settings': notificationSettings,
          'preferences': {},
        },
      );

      if (response.user != null) {
        debugPrint(
            'User registered successfully. Profile created by database trigger.');
        
        // Capture OneSignal Player ID after successful registration
        await _captureOneSignalPlayerId();
        
        // The database trigger will automatically create the user profile
        // No need for manual profile creation
      }
    } on AuthException catch (e) {
      debugPrint("Registration error: ${e.message}");
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

      // Load user profile - it should exist from registration
      await _loadUserProfile();

      // Update last login time if profile exists
      if (currentUser != null && _currentUserProfile != null) {
        try {
          await _supabase
              .from('users')
              .update({'last_login': DateTime.now().toIso8601String()}).eq(
                  'id', currentUser!.id);
        } catch (e) {
          debugPrint('Error updating last login: $e');
          // Don't fail sign-in for this
        }

        // Capture OneSignal Player ID after successful login
        await _captureOneSignalPlayerId();

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

  /// Capture and store OneSignal Player ID for the current user
  Future<void> _captureOneSignalPlayerId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Wait a bit for OneSignal to initialize
        await Future.delayed(const Duration(seconds: 1));
        
        // Updated OneSignal API usage
        final playerId = OneSignal.User.pushSubscription.id;
        if (playerId != null && playerId.isNotEmpty) {
          // Update user record with OneSignal Player ID
          await _supabase
              .from('users')
              .update({'onesignal_player_id': playerId})
              .eq('id', user.id);
          
          debugPrint('OneSignal Player ID captured: $playerId');
        } else {
          debugPrint('OneSignal Player ID not available yet');
          // Retry after a longer delay
          await Future.delayed(const Duration(seconds: 3));
          await _retryPlayerIdCapture(user.id);
        }
      }
    } catch (e) {
      debugPrint('Error capturing OneSignal Player ID: $e');
      // Try alternative method if the first one fails
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _retryPlayerIdCapture(user.id);
      }
    }
  }

  /// Retry capturing OneSignal Player ID
  Future<void> _retryPlayerIdCapture(String userId) async {
    try {
      // Alternative method to get player ID
      final playerId = OneSignal.User.pushSubscription.id;
      
      if (playerId != null && playerId.isNotEmpty) {
        await _supabase
            .from('users')
            .update({'onesignal_player_id': playerId})
            .eq('id', userId);
            
        debugPrint('OneSignal Player ID captured on retry: $playerId');
      } else {
        debugPrint('OneSignal Player ID still not available after retry');
      }
    } catch (e) {
      debugPrint('Error retrying OneSignal Player ID capture: $e');
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
      throw Exception('User profile not found. Please contact support.');
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
        debugPrint(
            'User signed up successfully. Profile will be created upon email confirmation.');
      }
    } on AuthException catch (e) {
      debugPrint("Sign up error: ${e.message}");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
        // Update notification_settings column directly (matches database schema)
        updateData['notification_settings'] = notificationSettings;
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

  /// Check if user should stay logged in based on remember me setting
  Future<bool> shouldStayLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? false;
  }

  /// Reset password for the given email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://aysamuel.github.io/agbc-app/reset-password.html',
      );
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
