import 'package:flutter/foundation.dart'; // Import for ChangeNotifier
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Import for StreamSubscription
import '../models/user_model.dart'; // Import our custom UserModel
import 'package:logging/logging.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../services/supabase_service.dart';
import '../services/permissions_service.dart';
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
  final _log = Logger('AuthService');
  final SupabaseClient _supabase;
  final SupabaseService _supabaseService;
  final NotificationService _notificationService;
  final PermissionsService _permissionsService;
  bool _rememberMe = false;
  bool _isLoading = false;

  /// Whether the service is currently performing an operation
  bool get isLoading => _isLoading;

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
  final Map<String, List<DateTime>> _loginAttempts = {};
  static const int _maxAttempts = 5;
  static const Duration _attemptWindow = Duration(minutes: 15);
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
      _authStateSubscription =
          _supabase.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null) {
          await _handleAuthStateChange(session);
        } else {
          _currentUser = null;
          notifyListeners();
        }
      });

      // Check if we have a persisted session
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _handleAuthStateChange(session);
        return;
      }

      // If no session, check for saved credentials
      final isRemembered = await PreferencesService.isRememberMeEnabled();
      if (isRemembered) {
        final savedEmail = await PreferencesService.getSavedEmail();
        final savedPassword = await PreferencesService.getSavedPassword();
        if (savedEmail != null && savedPassword != null) {
          // Attempt to sign in with saved credentials
          await signIn(
            email: savedEmail,
            password: savedPassword,
            rememberMe: true,
          );
          return;
        }
      }
    } catch (e) {
      _log.severe('Error initializing auth service: $e');
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
      _log.severe('Error handling auth state change', e);
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

      // Clear saved credentials
      await PreferencesService.clearLoginCredentials();

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
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Check if email is verified
        if (response.user!.emailConfirmedAt == null) {
          throw AuthException(
            'Your email address has not been verified yet. Please check your inbox for the verification link we sent you.',
            code: 'email_not_verified',
          );
        }

        final user = await _supabaseService.getUser(response.user!.id).first;
        if (user != null) {
          _currentUser = user;
          _currentUser = _currentUser!.copyWith(
            lastLogin: DateTime.now(),
            emailVerified: true,
          );
          await _supabaseService.updateUser(_currentUser!);
          // Register device for notifications
          await _notificationService.registerDevice(response.user!.id);
          return _currentUser;
        }
      }
      return null;
    } catch (e) {
      _log.severe('Error during sign in: $e');
      if (e is AuthException) {
        rethrow;
      }
      // Transform Supabase errors into user-friendly messages
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('email not confirmed') ||
          errorMessage.contains('email not verified')) {
        throw AuthException(
          'Your email address has not been verified yet. Please check your inbox for the verification link we sent you.',
          code: 'email_not_verified',
        );
      }
      if (errorMessage.contains('invalid login credentials') ||
          errorMessage.contains('invalid email or password')) {
        throw AuthException(
          'The email or password you entered is incorrect. Please try again.',
          code: 'invalid_credentials',
        );
      }
      if (errorMessage.contains('rate limit')) {
        throw AuthException(
          'Too many login attempts. Please try again in a few minutes.',
          code: 'rate_limit',
        );
      }
      if (errorMessage.contains('network')) {
        throw AuthException(
          'Network error. Please check your internet connection and try again.',
          code: 'network_error',
        );
      }
      throw AuthException(
        'An error occurred while trying to log in. Please try again.',
        code: 'unknown_error',
      );
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
      _log.info('Starting registration process...');

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

      _log.fine('Sign up response: ${response.user != null}');
      _log.fine('Session: ${response.session != null}');

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
        emailVerified: false, // Start as not verified
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

      // 4. Sign out the user - they need to verify email first
      await _supabase.auth.signOut();
      _currentUser = null;
      notifyListeners();

      return user;
    } catch (e) {
      _log.severe('Error during registration: $e');
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
        final metadata = user.userMetadata ?? {};

        // First try to get the user from our database
        final dbUser = await _supabaseService.getUser(user.id).first;

        if (dbUser != null) {
          _currentUser = dbUser;
        } else {
          // If not in database, create from auth data
          _currentUser = UserModel(
            id: user.id,
            displayName: metadata['full_name'] ?? '',
            email: user.email ?? '',
            role: metadata['role'] ?? 'member',
            phoneNumber: metadata['phone'],
            location: metadata['location'],
            branchId: metadata['branch'],
            photoUrl: metadata['photo_url'],
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

          // Save to database
          await _supabaseService.updateUser(_currentUser!);
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _log.severe('Error checking authentication: $e');
      return false;
    }
  }

  /// Sends a verification email to the current user
  Future<void> sendVerificationEmail() async {
    try {
      // Get the current user if available
      final user = _supabase.auth.currentUser;

      if (user == null) {
        // If no user is logged in, we need the email from the login form
        throw AuthException('Please enter your email address first.');
      }

      // Resend the verification email
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );

      _log.info('Verification email resent to: ${user.email}');
    } catch (e) {
      _log.severe('Error sending verification email: $e');
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
          'Failed to send verification email. Please try again.');
    }
  }

  /// Sends a verification email to a specific email address
  Future<void> sendVerificationEmailTo(String email) async {
    try {
      // For existing users who need to verify their email, we use signInWithOtp
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );

      _log.info('Verification email sent to: $email');
    } catch (e) {
      _log.severe('Error sending verification email: $e');
      throw AuthException(
          'Failed to send verification email. Please try again.');
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
      _log.severe('Error checking email verification: $e');
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
        await _supabaseService
            .updateUser(_currentUser!.copyWith(isActive: false));
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

  /// Verifies a user's email using the provided token
  Future<void> verifyEmail(String token) async {
    try {
      _log.fine('Starting email verification with token: $token');

      // Verify the email using Supabase
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        token: token,
      );

      _log.fine('OTP verification response: ${response.user != null}');

      // Get the current user from Supabase
      final user = _supabase.auth.currentUser;
      _log.fine('Current user after verification: ${user?.email}');
      _log.fine('Email confirmed at: ${user?.emailConfirmedAt}');

      if (user != null) {
        // Get the user from our database
        final dbUser = await _supabaseService.getUser(user.id).first;
        if (dbUser != null) {
          // Update email verification status
          final updatedUser = dbUser.copyWith(
            emailVerified: true,
            lastLogin: DateTime.now(),
          );

          // Update in database
          await _supabaseService.updateUser(updatedUser);
          _log.fine('Updated user email verification status');

          // Update local state
          _currentUser = updatedUser;
          notifyListeners();

          // Log the verification status
          _log.info('=== Email Verification Status ===');
          _log.info('User ID: ${user.id}');
          _log.info('Email: ${user.email}');
          _log.info('Email Confirmed At (Auth): ${user.emailConfirmedAt}');
          _log.info('Email Verified (DB): ${updatedUser.emailVerified}');
          _log.info('========================');
        } else {
          _log.fine('User not found in database');
        }
      } else {
        _log.fine('No user found after verification');
      }
    } catch (e) {
      _log.severe('Error verifying email: $e');
      throw AuthException('Failed to verify email. Please try again.');
    }
  }

  /// Checks the current authentication state and updates the user accordingly
  Future<void> checkAuthState() async {
    try {
      _log.fine('=== Checking Auth State ===');
      final session = _supabase.auth.currentSession;
      _log.fine('Current session: ${session != null}');

      if (session != null) {
        _log.fine('Session user ID: ${session.user.id}');
        _log.fine('Session user email: ${session.user.email}');
        _log.fine(
            'Session user emailConfirmedAt: ${session.user.emailConfirmedAt}');

        // Force a session refresh first
        _log.fine('Attempting to refresh session...');
        await _supabase.auth.refreshSession();
        _log.fine('Session refreshed successfully');

        // Get the latest user data after refresh
        final currentUser = _supabase.auth.currentUser;
        _log.fine('Current user after refresh: ${currentUser?.email}');
        _log.fine('Email confirmed at: ${currentUser?.emailConfirmedAt}');
        _log.fine('User metadata: ${currentUser?.userMetadata}');

        final user = await _supabaseService.getUser(session.user.id).first;
        if (user != null) {
          _log.fine('Found user in database: ${user.email}');

          _currentUser = user.copyWith(
            lastLogin: DateTime.now(),
          );
          _log.fine('Updated user last login time');
          await _supabaseService.updateUser(_currentUser!);
          // Register device for notifications
          await _notificationService.registerDevice(session.user.id);
        } else {
          _log.fine('No user found in database');
        }
      } else {
        _log.fine('No session found, clearing current user');
        _currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      _log.severe('Error checking auth state: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  /// Checks if an email exists in the system
  Future<bool> checkEmailExists(String email) async {
    try {
      _log.fine('=== Starting email existence check ===');
      _log.fine('Checking email: $email');
      final trimmedEmail = email.toLowerCase().trim();
      _log.fine('Trimmed email: $trimmedEmail');

      // Check in public.users table
      _log.fine('Checking users table...');
      final response = await _supabase
          .from('users')
          .select('id, email')
          .eq('email', trimmedEmail)
          .maybeSingle();

      _log.fine('Users table response: $response');

      if (response != null) {
        _log.fine('Found user in users table with email: ${response['email']}');
        return true;
      }

      _log.fine('User not found in users table, checking auth...');

      // If not found in users table, try to sign in to check if user exists in auth
      try {
        _log.fine('Attempting dummy sign in to check auth...');
        await _supabase.auth.signInWithPassword(
          email: trimmedEmail,
          password: 'dummy_password_for_check',
        );
        // If we get here, something is wrong - we shouldn't be able to sign in with a dummy password
        _log.warning(
            'Unexpected: Dummy sign in succeeded for email: $trimmedEmail');
        return false;
      } catch (e) {
        _log.fine('Auth check error: $e');
        final errorMessage = e.toString().toLowerCase();

        // Only return true if we get a specific "invalid password" error
        // This indicates the user exists but password is wrong
        if (errorMessage.contains('invalid login credentials') ||
            errorMessage.contains('invalid email or password')) {
          _log.fine('Found user in auth (invalid password)');
          return true;
        }

        // For any other error, including "user not found", return false
        _log.fine('No user found in auth. Error: $errorMessage');
        return false;
      }
    } catch (e) {
      _log.severe('Error checking email registration: $e');
      if (e is PostgrestException) {
        _log.fine('Postgrest error code: ${e.code}');
        _log.fine('Postgrest error message: ${e.message}');
        if (e.code == 'PGRST116') {
          // No rows returned
          return false;
        }
      }
      rethrow;
    } finally {
      _log.fine('=== Email existence check completed ===');
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
        // Update user with Auth's email verification status and metadata
        final isEmailVerified = session.user.emailConfirmedAt != null;
        final metadata = session.user.userMetadata ?? {};

        _currentUser = user.copyWith(
          lastLogin: DateTime.now(),
          emailVerified: isEmailVerified,
          displayName: metadata['full_name'] ?? user.displayName,
          phoneNumber: metadata['phone'] ?? user.phoneNumber,
          location: metadata['location'] ?? user.location,
          branchId: metadata['branch'] ?? user.branchId,
        );

        // Update in database
        await _supabaseService.updateUser(_currentUser!);

        // Double check the update
        final updatedUser =
            await _supabaseService.getUser(session.user.id).first;
        if (updatedUser != null) {
          // If any fields didn't update correctly, try one more time
          if (updatedUser.phoneNumber != _currentUser!.phoneNumber ||
              updatedUser.location != _currentUser!.location ||
              updatedUser.branchId != _currentUser!.branchId) {
            await _supabaseService.updateUser(_currentUser!);
          }
        }

        await _notificationService.registerDevice(session.user.id);

        // Log detailed user information
        _log.info('=== User Session Details ===');
        _log.info('User ID: ${session.user.id}');
        _log.info('Email: ${session.user.email}');
        _log.info('Email Verified (DB): ${_currentUser!.emailVerified}');
        _log.info(
            'Email Verified (Auth): ${session.user.emailConfirmedAt != null}');
        _log.info('Last Sign In: ${session.user.lastSignInAt}');
        _log.info('Created At: ${session.user.createdAt}');
        _log.info('Role: ${user.role}');
        _log.info('Display Name: ${user.displayName}');
        _log.info('Phone Number: ${user.phoneNumber ?? 'Not set'}');
        _log.info('Location: ${user.location ?? 'Not set'}');
        _log.info('Branch ID: ${user.branchId ?? 'Not assigned'}');
        _log.info('Active Status: ${user.isActive}');
        _log.info(
            'Departments: ${user.departments.isEmpty ? 'None' : user.departments.join(', ')}');
        _log.info('Session Expires: ${session.expiresAt}');
        _log.info('Access Token: ${session.accessToken.substring(0, 10)}...');
        _log.info(
            'Refresh Token: ${session.refreshToken?.substring(0, 10) ?? 'N/A'}...');
        _log.info('========================');
      }
    } catch (e) {
      _log.severe('Error handling session: $e');
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

      // Save credentials only after successful login
      if (rememberMe) {
        await PreferencesService.saveLoginCredentials(
          email: email,
          password: password,
          rememberMe: true,
        );
      } else {
        await PreferencesService.clearLoginCredentials();
      }

      // Check if email is verified
      if (response.user!.emailConfirmedAt == null) {
        throw AuthException(
          'Your email address has not been verified yet. Please check your inbox for the verification link we sent you.',
          code: 'email_not_verified',
        );
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
    } catch (e) {
      _log.severe('Error during sign in: $e');
      if (e is AuthException) {
        rethrow;
      }
      // Transform Supabase errors into user-friendly messages
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('email not confirmed') ||
          errorMessage.contains('email not verified')) {
        throw AuthException(
          'Your email address has not been verified yet. Please check your inbox for the verification link we sent you.',
          code: 'email_not_verified',
        );
      }
      if (errorMessage.contains('invalid login credentials') ||
          errorMessage.contains('invalid email or password')) {
        throw AuthException(
          'The email or password you entered is incorrect. Please try again.',
          code: 'invalid_credentials',
        );
      }
      if (errorMessage.contains('rate limit')) {
        throw AuthException(
          'Too many login attempts. Please try again in a few minutes.',
          code: 'rate_limit',
        );
      }
      if (errorMessage.contains('network')) {
        throw AuthException(
          'Network error. Please check your internet connection and try again.',
          code: 'network_error',
        );
      }
      throw AuthException(
        'An error occurred while trying to log in. Please try again.',
        code: 'unknown_error',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force update email verification status
  Future<void> forceUpdateEmailVerification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final isEmailVerified = user.emailConfirmedAt != null;
        _log.info('Force updating email verification status: $isEmailVerified');

        // Get current user from database
        final dbUser = await _supabaseService.getUser(user.id).first;
        if (dbUser != null) {
          // Update with new verification status
          final updatedUser = dbUser.copyWith(
            emailVerified: isEmailVerified,
            lastLogin: DateTime.now(),
          );

          // Update in database
          await _supabaseService.updateUser(updatedUser);

          // Update local state
          _currentUser = updatedUser;
          notifyListeners();

          _log.info('Email verification status updated successfully');
          _log.info('Email Verified (DB): ${updatedUser.emailVerified}');
          _log.info('Email Verified (Auth): $isEmailVerified');
        }
      }
    } catch (e) {
      _log.severe('Error force updating email verification: $e');
      throw AuthException('Failed to update email verification status');
    }
  }
}
