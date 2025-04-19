import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service class for handling role-based permissions
class PermissionsService with ChangeNotifier {
  Future<void> initialize() async {
    // Initialize and request necessary permissions
    await Permission.location.request();
    await Permission.notification.request();
    await Permission.camera.request();
    await Permission.storage.request();
  }

  /// Get default permissions for a given role
  static Map<String, bool> getDefaultPermissions(String role) {
    switch (role) {
      case 'admin':
        return {
          // User Management
          'manage_users': true,
          'view_users': true,
          'assign_roles': true,

          // Church Management
          'manage_church': true,
          'manage_departments': true,

          // Task Management
          'create_tasks': true,
          'edit_tasks': true,
          'delete_tasks': true,
          'assign_tasks': true,
          'view_all_tasks': true,

          // Meeting Management
          'create_meetings': true,
          'edit_meetings': true,
          'delete_meetings': true,
          'invite_to_meetings': true,
          'view_all_meetings': true,

          // Content Management
          'create_content': true,
          'edit_content': true,
          'delete_content': true,
        };
      case 'pastor':
        return {
          // User Management
          'manage_users': false,
          'view_users': true,
          'assign_roles': false,

          // Church Management
          'manage_church': false,
          'manage_departments': false,

          // Task Management
          'create_tasks': true,
          'edit_tasks': true,
          'delete_tasks': true,
          'assign_tasks': true,
          'view_all_tasks': true,

          // Meeting Management
          'create_meetings': true,
          'edit_meetings': true,
          'delete_meetings': true,
          'invite_to_meetings': true,
          'view_all_meetings': true,

          // Content Management
          'create_content': true,
          'edit_content': true,
          'delete_content': false,
        };
      case 'worker':
        return {
          // User Management
          'manage_users': false,
          'view_users': true,
          'assign_roles': false,

          // Church Management
          'manage_church': false,
          'manage_departments': false,

          // Task Management
          'create_tasks': true,
          'edit_tasks': true,
          'delete_tasks': true,
          'assign_tasks': false,
          'view_all_tasks': true,

          // Meeting Management
          'create_meetings': false,
          'edit_meetings': false,
          'delete_meetings': false,
          'invite_to_meetings': false,
          'view_all_meetings': true,

          // Content Management
          'create_content': true,
          'edit_content': false,
          'delete_content': false,
        };
      case 'member':
      default:
        return {
          // User Management
          'manage_users': false,
          'view_users': false,
          'assign_roles': false,

          // Church Management
          'manage_church': false,
          'manage_departments': false,

          // Task Management
          'create_tasks': false,
          'edit_tasks': false,
          'delete_tasks': false,
          'assign_tasks': false,
          'view_all_tasks': false,
          'view_assigned_tasks': true,

          // Meeting Management
          'create_meetings': false,
          'edit_meetings': false,
          'delete_meetings': false,
          'invite_to_meetings': false,
          'view_all_meetings': false,
          'view_invited_meetings': true,

          // Content Management
          'create_content': false,
          'edit_content': false,
          'delete_content': false,
          'view_content': true,
        };
    }
  }

  /// Check if a user has a specific permission
  static bool hasPermission(Map<String, bool> permissions, String permission) {
    return permissions[permission] ?? false;
  }

  /// Check if a user can perform a specific action
  static bool canPerformAction(Map<String, bool> permissions, String action) {
    switch (action) {
      case 'create_task':
        return hasPermission(permissions, 'create_tasks');
      case 'assign_task':
        return hasPermission(permissions, 'assign_tasks');
      case 'create_meeting':
        return hasPermission(permissions, 'create_meetings');
      case 'invite_to_meeting':
        return hasPermission(permissions, 'invite_to_meetings');
      case 'manage_users':
        return hasPermission(permissions, 'manage_users');
      default:
        return false;
    }
  }
} 