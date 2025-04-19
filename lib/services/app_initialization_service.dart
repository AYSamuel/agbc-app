import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:agbc_app/services/preferences_service.dart';
import 'package:agbc_app/services/location_service.dart';
import 'package:agbc_app/services/permissions_service.dart';
import 'package:agbc_app/services/notification_service.dart';
import 'package:agbc_app/services/user_service.dart';

class AppInitializationService {
  static Future<bool> initializeApp() async {
    try {
      // Initialize Firebase Core
      await Firebase.initializeApp();
      
      // Initialize Firebase Auth
      final auth = FirebaseAuth.instance;
      
      // Initialize Firestore
      final firestore = FirebaseFirestore.instance;
      
      // Initialize Firebase Messaging
      final messaging = FirebaseMessaging.instance;
      
      // Initialize Location Service
      final locationService = LocationService();
      await locationService.initialize();
      
      // Initialize Permissions Service
      final permissionsService = PermissionsService();
      await permissionsService.initialize();
      
      // Initialize Notification Service
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      // Initialize User Service
      final userService = UserService();
      await userService.initialize();
      
      // Check if user is already logged in
      final currentUser = auth.currentUser;
      
      // Check if remember me is enabled
      final isRememberMeEnabled = await PreferencesService.isRememberMeEnabled();
      
      // If user is logged in or remember me is enabled, initialize user data
      if (currentUser != null || isRememberMeEnabled) {
        // Initialize user-specific services
        if (currentUser != null) {
          await userService.loadUserData(currentUser.uid);
        } else if (isRememberMeEnabled) {
          final savedEmail = await PreferencesService.getSavedEmail();
          if (savedEmail != null) {
            final user = await auth.signInWithEmailAndPassword(
              email: savedEmail,
              password: (await PreferencesService.getSavedPassword()) ?? '',
            );
            if (user.user != null) {
              await userService.loadUserData(user.user!.uid);
            }
          }
        }
        return true;
      }
      
      // If no user is logged in and remember me is not enabled, show login screen
      return false;
    } catch (e) {
      // If there's any error during initialization, show login screen
      print('Error during app initialization: $e');
      return false;
    }
  }
} 