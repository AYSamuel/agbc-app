import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agbc_app/services/location_service.dart';
import 'package:agbc_app/services/permissions_service.dart';
import 'package:agbc_app/services/notification_service.dart';
import 'package:agbc_app/services/user_service.dart';
import 'package:agbc_app/providers/branches_provider.dart';
import 'package:agbc_app/providers/supabase_provider.dart';
import 'dart:developer' as developer;

class AppInitializationService {
  static Future<bool> initializeApp() async {
    try {
      developer.log('Starting app initialization...');

      // Initialize Supabase
      final supabase = Supabase.instance.client;
      developer.log('Supabase initialized');

      // Initialize SupabaseProvider first since other services depend on it
      final supabaseProvider = SupabaseProvider();
      developer.log('SupabaseProvider initialized');

      // Initialize Permissions Service (needed for other services)
      final permissionsService = PermissionsService();
      await permissionsService.initialize();
      developer.log('Permissions service initialized');

      // Initialize Location Service
      final locationService = LocationService();
      await locationService.initialize();
      developer.log('Location service initialized');

      // Initialize Notification Service
      final notificationService = NotificationService();
      await notificationService.initialize();
      developer.log('Notification service initialized');

      // Initialize User Service
      final userService = UserService();
      await userService.initialize();
      developer.log('User service initialized');

      // Initialize Branches Provider
      final branchesProvider = BranchesProvider(supabaseProvider);
      await branchesProvider.initialize();
      developer.log('Branches provider initialized');

      // If user is logged in, initialize their data
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        developer.log('User is logged in, initializing user data...');

        // Initialize user data which will also initialize branch data
        await supabaseProvider.initializeUserData(currentUser.id);
        developer.log('User data initialized');
      } else {
        developer.log('No user is logged in');
      }

      return true;
    } catch (e) {
      developer.log('Error during app initialization: $e');
      return false;
    }
  }
}
