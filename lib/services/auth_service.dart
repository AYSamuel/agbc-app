import 'package:flutter/foundation.dart'; // Import for ChangeNotifier
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Import for StreamSubscription
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart'; // Import our custom UserModel
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../services/supabase_service.dart';
import '../services/permissions_service.dart';
import 'package:flutter/material.dart';
import 'package:agbc_app/providers/supabase_provider.dart';
import '../services/preferences_service.dart';
import 'package:agbc_app/services/notification_service.dart';

/// Exception for user-facing authentication errors.
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Service class for handling authentication-related operations.
class AuthService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService;
  final PermissionsService _permissionsService;
  final SupabaseProvider _supabaseProvider = SupabaseProvider();
  bool _rememberMe = false;

  // Private variable to store the current user
  UserModel? _currentUser;
  StreamSubscription<AuthState>? _authStateSubscription;

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

  final NotificationService _notificationService = NotificationService();

  AuthService({
    required SupabaseService supabaseService,
    required PermissionsService permissionsService,
  })  : _supabaseService = supabaseService,
        _permissionsService = permissionsService {
    initialize();
  }

  Future<void> initialize() async {
    try {
      await _permissionsService.initialize();
      _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null) {
          try {
            final user = await _supabaseService.getUser(session.user.id).first;
            if (user != null) {
              _currentUser = user;
              _currentUser = _currentUser!.copyWith(
                lastLogin: DateTime.now(),
                emailVerified: session.user.emailConfirmedAt != null,
              );
              await _supabaseService.updateUser(_currentUser!);
              // Register device for notifications
              await _notificationService.registerDevice(session.user.id);
            } else {
              _currentUser = UserModel(
                id: session.user.id,
                displayName: session.user.userMetadata?['full_name'] ?? '',
                email: session.user.email ?? '',
                role: 'member',
                createdAt: DateTime.now(),
                lastLogin: DateTime.now(),
                isActive: true,
                emailVerified: session.user.emailConfirmedAt != null,
                departments: [],
                notificationSettings: {
                  'email': true,
                  'push': true,
                },
                phoneNumber: session.user.phone ?? '',
              );
              await _supabaseService.updateUser(_currentUser!);
              // Register device for notifications
              await _notificationService.registerDevice(session.user.id);
            }
          } catch (e) {
            print('Error loading user data: $e');
            _currentUser = null;
          }
        } else {
          _currentUser = null;
        }
        notifyListeners();
      });
    } catch (e) {
      print('Error initializing auth service: $e');
    }
  }

  /// Set the remember me preference
  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    if (!value) {
      // If remember me is disabled, clear the auth state and saved credentials
      await _supabase.auth.signOut();
      await PreferencesService.clearLoginCredentials();
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    try {
      // Cancel the auth state listener
      await _authStateSubscription?.cancel();
      _authStateSubscription = null;

      // Remove device registration
      if (_currentUser != null) {
        await _notificationService.removeDevice(_currentUser!.id);
      }

      // Clear the current user
      _currentUser = null;
      notifyListeners();

      // Clear platform-specific persistence (web only)
      if (kIsWeb) {
        await _supabase.auth.signOut();
      }

      // Clear any cached data
      _loginAttempts.clear();
    } catch (e) {
      // Handle error silently in production
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
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        final user = await _supabaseService.getUser(response.user!.id).first;
        if (user != null) {
          _currentUser = user;
          _currentUser = _currentUser!.copyWith(
            lastLogin: DateTime.now(),
            emailVerified: response.user!.emailConfirmedAt != null,
          );
          await _supabaseService.updateUser(_currentUser!);
          // Register device for notifications
          await _notificationService.registerDevice(response.user!.id);
          return _currentUser;
        }
      }
      return null;
    } catch (e) {
      print('Error during sign in: $e');
      return null;
    }
  }

  /// Registers a new user with the provided email and password.
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String phone,
    String location,
    String role,
    String? branch,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'phone': phone,
          'location': location,
          'role': role,
          'branch': branch,
        },
      );

      if (response.user != null) {
        final user = UserModel(
          id: response.user!.id,
          displayName: name,
          email: email,
          role: role,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          isActive: true,
          emailVerified: false,
          departments: [],
          notificationSettings: {
            'email': true,
            'push': true,
          },
          phoneNumber: phone,
          location: location,
          branchId: branch,
        );
        
        await _supabaseService.updateUser(user);
        _currentUser = user;
        notifyListeners();
        return user;
      }
      return null;
    } catch (e) {
      print('Error during registration: $e');
      return null;
    }
  }

  /// Updates a user's role (only accessible by admins)
  Future<void> updateUserRole(String id, String newRole) async {
    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  /// Get tasks based on user's role and permissions
  Stream<List<TaskModel>> getTasksForCurrentUser() {
    if (_currentUser != null) {
      return _supabaseService.getTasksForUser(_currentUser!.id);
    }
    return Stream.value([]);
  }

  /// Checks if there's a currently authenticated user.
  Future<bool> checkAuthentication() async {
    try {
      User? user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.auth.refreshSession();
        _currentUser = UserModel(
          id: user.id,
          displayName: user.userMetadata?['full_name'] ?? '',
          email: user.email ?? '',
          role: user.userMetadata?['role'] ?? 'member',
          phoneNumber: user.phone,
          photoUrl: user.userMetadata?['photo_url'],
          createdAt: DateTime.parse(user.createdAt),
          lastLogin: DateTime.now(),
          isActive: true,
          emailVerified: user.emailConfirmedAt != null,
          departments: [],
          notificationSettings: {
            'email': true,
            'push': true,
          },
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Sends a verification email to the current user
  Future<void> sendVerificationEmail() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.auth.resend(
          type: OtpType.signup,
          email: user.email!,
        );
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
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Refresh the session to get the latest user data
        await _supabase.auth.refreshSession();
        return user.emailConfirmedAt != null;
      }
      return false;
    } catch (e) {
      throw AuthException('Failed to check email verification status: $e');
    }
  }

  String _handleAuthException(dynamic e) {
    if (e is AuthException) {
      return e.message;
    } else if (e is PostgrestException) {
      return 'Database error: ${e.message}';
    } else if (e is AuthException) {
      return 'Authentication error: ${e.message}';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Signs out the user and clears all auth state
  Future<void> signOut() async {
    try {
      // Remove device registration
      if (_currentUser != null) {
        await _notificationService.removeDevice(_currentUser!.id);
      }
      await _supabase.auth.signOut();

      // Clear the current user first
      _currentUser = null;
      notifyListeners();

      // Clear any cached data
      _loginAttempts.clear();
    } catch (e) {
      // Handle error silently in production
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthException(_handleAuthException(e));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      if (_supabase.auth.currentUser != null) {
        await _supabase.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } else {
        throw AuthException('No authenticated user found');
      }
    } catch (e) {
      throw AuthException(_handleAuthException(e));
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      if (_supabase.auth.currentUser != null) {
        await _supabase.auth.updateUser(
          UserAttributes(email: newEmail),
        );
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(email: newEmail);
          await _supabaseService.updateUser(_currentUser!);
          notifyListeners();
        }
      } else {
        throw AuthException('No authenticated user found');
      }
    } catch (e) {
      throw AuthException(_handleAuthException(e));
    }
  }

  Future<void> updateProfile(String name, String? photoUrl) async {
    try {
      if (_supabase.auth.currentUser != null) {
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': name,
              'photo_url': photoUrl,
            },
          ),
        );
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            displayName: name,
            photoUrl: photoUrl,
          );
          await _supabaseService.updateUser(_currentUser!);
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
      if (_supabase.auth.currentUser != null) {
        await _supabaseService.updateUser(_currentUser!.copyWith(isActive: false));
        await _supabase.auth.signOut();
        _currentUser = null;
        notifyListeners();
      } else {
        throw AuthException('No authenticated user found');
      }
    } catch (e) {
      throw AuthException('Failed to delete account: $e');
    }
  }

  /// Get meetings based on user's role
  Stream<List<MeetingModel>> getMeetings() {
    if (_currentUser == null) {
      return Stream.value([]);
    }

    if (_currentUser!.role == 'admin' || _currentUser!.role == 'pastor') {
      return _supabaseService.getAllMeetings();
    } else {
      return _supabaseService.getMeetingsForUser(_currentUser!.id);
    }
  }

  /// Checks the current authentication state and updates the user accordingly
  Future<void> checkAuthState() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        final user = await _supabaseService.getUser(session.user.id).first;
        if (user != null) {
          _currentUser = user;
          _currentUser = _currentUser!.copyWith(
            lastLogin: DateTime.now(),
            emailVerified: session.user.emailConfirmedAt != null,
          );
          await _supabaseService.updateUser(_currentUser!);
          // Register device for notifications
          await _notificationService.registerDevice(session.user.id);
        }
      } else {
        _currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error checking auth state: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  /// Checks if an email exists in the system
  Future<UserModel?> checkEmailExists(String email) async {
    try {
      print('Checking email in database: $email'); // Debug log
      
      // Check in public.users table
      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();
      
      print('Database response: $response'); // Debug log
      
      if (response != null) {
        print('User found in database'); // Debug log
        return UserModel.fromJson(response);
      }
      
      print('No user found in database'); // Debug log
      return null;
    } catch (e) {
      print('Error checking email: $e'); // Debug log
      
      if (e is PostgrestException) {
        print('Postgrest error code: ${e.code}'); // Debug log
        if (e.code == 'PGRST116') {
          // No rows returned
          return null;
        }
      }
      
      // If we get here, it's an unexpected error
      throw AuthException('An error occurred while verifying your email. Please try again.');
    }
  }
}
