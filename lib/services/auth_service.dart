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
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase;
  final SupabaseService _supabaseService;
  final NotificationService _notificationService;
  final PermissionsService _permissionsService;
  final SupabaseProvider _supabaseProvider = SupabaseProvider();
  bool _rememberMe = false;
  bool _isLoading = false;

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

  AuthService({
    required SupabaseClient supabase,
    required SupabaseService supabaseService,
    required NotificationService notificationService,
    required PermissionsService permissionsService,
  })  : _supabase = supabase,
        _supabaseService = supabaseService,
        _notificationService = notificationService,
        _permissionsService = permissionsService {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize permissions service
      await _permissionsService.initialize();
      
      // Listen to auth state changes
      _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null) {
          await _handleAuthStateChange(session);
        } else {
          _currentUser = null;
          notifyListeners();
        }
      });
      
      // Check initial auth state
      await _checkCurrentSession();
    } catch (e) {
      print('Error initializing auth service: $e');
    }
  }

  Future<void> _checkCurrentSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _handleAuthStateChange(session);
      }
    } catch (e) {
      print('Error checking current session: $e');
    }
  }

  Future<void> _handleAuthStateChange(Session session) async {
    try {
      // Get user data from our database
      final user = await _supabaseService.getUser(session.user.id).first;
      if (user != null) {
        _currentUser = user;
        // Register device for notifications
        await _notificationService.registerDevice(session.user.id);
      }
      notifyListeners();
    } catch (e) {
      print('Error handling auth state change: $e');
      _currentUser = null;
      notifyListeners();
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
  Future<UserModel> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String phone,
    String location,
    String role,
    String? branchId,
  ) async {
    try {
      print('Starting registration process...');
      
      // 1. Sign up with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'phone': phone,
          'location': location,
          'role': role,
          'branch': branchId,
        },
      );

      print('Sign up response: ${response.user != null}');
      print('Session: ${response.session != null}');

      if (response.user == null) {
        throw AuthException('Registration failed. Please try again.');
      }

      // 2. Create user in our database
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
        branchId: branchId,
      );

      // 3. Save user to database
      await _supabaseService.updateUser(user);

      // 4. If we have a session, set it and sign in
      if (response.session != null) {
        try {
          // Set the session
          await _supabase.auth.setSession(response.session!.accessToken);
          print('Session set after registration');

          // Force a session refresh to get latest user info
          await _supabase.auth.refreshSession();
          print('Session refreshed after registration');

          // Register device for notifications
          await _notificationService.registerDevice(response.user!.id);
        } catch (e) {
          print('Error setting session after registration: $e');
          // Try to sign in with the credentials
          try {
            final signInResponse = await _supabase.auth.signInWithPassword(
              email: email,
              password: password,
            );
            if (signInResponse.session != null) {
              await _supabase.auth.setSession(signInResponse.session!.accessToken);
              print('Successfully signed in after registration');
            }
          } catch (signInError) {
            print('Error signing in after registration: $signInError');
          }
        }
      }

      // 5. Set current user
      _currentUser = user;
      notifyListeners();

      return user;
    } catch (e) {
      print('Error during registration: $e');
      if (e is AuthException) rethrow;
      if (e is PostgrestException) {
        throw AuthException('Database error: ${e.message}');
      }
      throw AuthException('An unexpected error occurred during registration.');
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
      if (user == null) {
        throw AuthException('No authenticated user found.');
      }
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );
    } catch (e) {
      throw AuthException('Failed to send verification email.');
    }
  }

  /// Checks if the current user's email is verified
  Future<bool> isEmailVerified() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Refresh session to get latest user info
      await _supabase.auth.refreshSession();
      
      // Check auth state
      if (user.emailConfirmedAt != null) {
        // Update database if verified
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(emailVerified: true);
          await _supabaseService.updateUser(_currentUser!);
        }
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
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
      print('=== Checking Auth State ===');
      final session = _supabase.auth.currentSession;
      print('Current session: ${session != null}'); // Debug log
      
      if (session != null) {
        print('Session user ID: ${session.user.id}'); // Debug log
        print('Session user email: ${session.user.email}'); // Debug log
        print('Session user emailConfirmedAt: ${session.user.emailConfirmedAt}'); // Debug log
        
        // Force a session refresh first
        print('Attempting to refresh session...'); // Debug log
        await _supabase.auth.refreshSession();
        print('Session refreshed successfully'); // Debug log
        
        // Get the latest user data after refresh
        final currentUser = _supabase.auth.currentUser;
        print('Current user after refresh: ${currentUser?.email}'); // Debug log
        print('Email confirmed at: ${currentUser?.emailConfirmedAt}'); // Debug log
        print('User metadata: ${currentUser?.userMetadata}'); // Debug log
        
        final user = await _supabaseService.getUser(session.user.id).first;
        if (user != null) {
          print('Found user in database: ${user.email}'); // Debug log
          _currentUser = user;
          _currentUser = _currentUser!.copyWith(
            lastLogin: DateTime.now(),
            emailVerified: currentUser?.emailConfirmedAt != null,
          );
          print('Updated user verification status: ${_currentUser!.emailVerified}'); // Debug log
          await _supabaseService.updateUser(_currentUser!);
          // Register device for notifications
          await _notificationService.registerDevice(session.user.id);
        } else {
          print('No user found in database'); // Debug log
        }
      } else {
        print('No session found, clearing current user'); // Debug log
        _currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error checking auth state: $e'); // Debug log
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
      
      // If not found in users table, try to sign in to check if it exists in auth
      try {
        await _supabase.auth.signInWithOtp(
          email: email,
          shouldCreateUser: false,
        );
        print('Email exists in auth system'); // Debug log
        return UserModel(
          id: 'pending',
          email: email,
          displayName: '',
          role: 'member',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          isActive: true,
          emailVerified: false,
          departments: [],
          notificationSettings: {
            'email': true,
            'push': true,
          },
        );
      } catch (e) {
        print('Email not found in auth system'); // Debug log
        return null;
      }
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

  /// Register a new user
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? location,
    String role = 'member',
    String? branchId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Sign up with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'location': location,
          'role': role,
          'branch': branchId,
        },
      );

      if (response.user == null) {
        throw AuthException('Registration failed. Please try again.');
      }

      // 2. Create user in database
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
        location: location,
        branchId: branchId,
      );

      // 3. Save user to database
      await _supabaseService.updateUser(user);

      // 4. Set session if available
      if (response.session != null) {
        await _supabase.auth.setSession(response.session!.accessToken);
        await _handleSession(response.session!);
      }

      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle a new session
  Future<void> _handleSession(Session session) async {
    try {
      final user = await _supabaseService.getUser(session.user.id).first;
      if (user != null) {
        _currentUser = user.copyWith(
          lastLogin: DateTime.now(),
          emailVerified: session.user.emailConfirmedAt != null,
        );
        await _supabaseService.updateUser(_currentUser!);
        await _notificationService.registerDevice(session.user.id);
      }
    } catch (e) {
      print('Error handling session: $e');
      _currentUser = null;
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Invalid email or password');
      }

      await _handleSession(response.session!);

      if (rememberMe) {
        await PreferencesService.saveLoginCredentials(
          email: email,
          password: password,
          rememberMe: true,
        );
      }

      return _currentUser!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
