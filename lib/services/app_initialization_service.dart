import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agbc_app/services/preferences_service.dart';
import 'package:agbc_app/services/location_service.dart';
import 'package:agbc_app/services/permissions_service.dart';
import 'package:agbc_app/services/notification_service.dart';
import 'package:agbc_app/services/user_service.dart';
import 'dart:developer' as developer;

class AppInitializationService {
  static Future<bool> initializeApp() async {
    try {
      developer.log('Initializing app...');
      
      // Initialize Supabase
      final supabase = Supabase.instance.client;
      developer.log('Supabase initialized');
      
      // Initialize Location Service
      final locationService = LocationService();
      await locationService.initialize();
      developer.log('Location service initialized');
      
      // Initialize Permissions Service
      final permissionsService = PermissionsService();
      await permissionsService.initialize();
      developer.log('Permissions service initialized');
      
      // Initialize Notification Service
      final notificationService = NotificationService();
      await notificationService.initialize();
      developer.log('Notification service initialized');
      
      // Initialize User Service
      final userService = UserService();
      await userService.initialize();
      developer.log('User service initialized');
      
      // Check if user is already logged in
      final currentUser = supabase.auth.currentUser;
      developer.log('Current user status: ${currentUser != null ? 'Logged in' : 'Not logged in'}');
      
      // Check if remember me is enabled
      final isRememberMeEnabled = await PreferencesService.isRememberMeEnabled();
      developer.log('Remember me status: $isRememberMeEnabled');
      
      // If remember me is not enabled and there's a current user, sign them out
      if (!isRememberMeEnabled && currentUser != null) {
        developer.log('Remember me disabled, signing out user');
        await supabase.auth.signOut();
        return false;
      }
      
      // If user is logged in and remember me is enabled, initialize user data
      if (currentUser != null && isRememberMeEnabled) {
        developer.log('User is logged in and remember me is enabled');
        return true;
      }
      
      developer.log('No authenticated user found');
      return false;
    } catch (e, stackTrace) {
      developer.log('Error initializing app', error: e, stackTrace: stackTrace);
      return false;
    }
  }
} 