import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';

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
  static Map<String, bool> getPermissionsForRole(String role) {
    print('Getting permissions for role: $role');
    final permissions = switch (role.toLowerCase()) {
      'admin' => getAdminPermissions(),
      'pastor' => getPastorPermissions(),
      'worker' => getWorkerPermissions(),
      'member' => getMemberPermissions(),
      _ => getMemberPermissions(),
    };
    print('Permissions for $role: $permissions');
    return permissions;
  }

  static Map<String, bool> getAdminPermissions() {
    final permissions = {
      // User Management
      'manage_users': true,
      'view_users': true,
      'edit_users': true,
      'delete_users': true,

      // Task Management
      'create_tasks': true,
      'assign_tasks': true,
      'edit_tasks': true,
      'delete_tasks': true,
      'view_all_tasks': true,

      // Meeting Management
      'create_meetings': true,
      'edit_meetings': true,
      'delete_meetings': true,
      'view_all_meetings': true,

      // Branch Management
      'manage_branch': true,
      'create_branches': true,
      'edit_branches': true,
      'delete_branches': true,
      'view_all_branches': true,

      // Department Management
      'manage_departments': true,
      'create_departments': true,
      'edit_departments': true,
      'delete_departments': true,

      // Settings
      'manage_settings': true,
      'view_settings': true,
      'edit_settings': true,
    };
    print('Admin permissions: $permissions');
    return permissions;
  }

  static Map<String, bool> getPastorPermissions() {
    return {
      // User Management
      'manage_users': false,
      'view_users': true,
      'edit_users': true,
      'delete_users': false,

      // Task Management
      'create_tasks': true,
      'assign_tasks': true,
      'edit_tasks': true,
      'delete_tasks': true,
      'view_all_tasks': true,

      // Meeting Management
      'create_meetings': true,
      'edit_meetings': true,
      'delete_meetings': true,
      'view_all_meetings': true,

      // Branch Management
      'manage_branch': false,
      'create_branches': false,
      'edit_branches': true,
      'delete_branches': false,
      'view_all_branches': true,

      // Department Management
      'manage_departments': true,
      'create_departments': true,
      'edit_departments': true,
      'delete_departments': true,

      // Settings
      'manage_settings': false,
      'view_settings': true,
      'edit_settings': false,
    };
  }

  static Map<String, bool> getWorkerPermissions() {
    return {
      // User Management
      'manage_users': false,
      'view_users': true,
      'edit_users': false,
      'delete_users': false,

      // Task Management
      'create_tasks': true,
      'assign_tasks': true,
      'edit_tasks': true,
      'delete_tasks': false,
      'view_all_tasks': true,

      // Meeting Management
      'create_meetings': false,
      'edit_meetings': false,
      'delete_meetings': false,
      'view_all_meetings': true,

      // Branch Management
      'manage_branch': false,
      'create_branches': false,
      'edit_branches': false,
      'delete_branches': false,
      'view_all_branches': true,

      // Department Management
      'manage_departments': false,
      'create_departments': false,
      'edit_departments': false,
      'delete_departments': false,

      // Settings
      'manage_settings': false,
      'view_settings': false,
      'edit_settings': false,
    };
  }

  static Map<String, bool> getMemberPermissions() {
    return {
      // User Management
      'manage_users': false,
      'view_users': true,
      'edit_users': false,
      'delete_users': false,

      // Task Management
      'create_tasks': false,
      'assign_tasks': false,
      'edit_tasks': false,
      'delete_tasks': false,
      'view_all_tasks': false,

      // Meeting Management
      'create_meetings': false,
      'edit_meetings': false,
      'delete_meetings': false,
      'view_all_meetings': true,

      // Branch Management
      'manage_branch': false,
      'create_branches': false,
      'edit_branches': false,
      'delete_branches': false,
      'view_all_branches': true,

      // Department Management
      'manage_departments': false,
      'create_departments': false,
      'edit_departments': false,
      'delete_departments': false,

      // Settings
      'manage_settings': false,
      'view_settings': false,
      'edit_settings': false,
    };
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