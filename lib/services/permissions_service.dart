import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service class for handling role-based permissions
class PermissionsService with ChangeNotifier {
  late final Map<String, Map<String, bool>> _permissions;
  late final Map<String, bool> _defaultPermissions;
  late final Map<String, bool> _adminPermissions;

  PermissionsService() {
    _adminPermissions = _getAdminPermissions();
    _defaultPermissions = _getMemberPermissions();
    _permissions = {
      'admin': _adminPermissions,
      'pastor': _getPastorPermissions(),
      'worker': _getWorkerPermissions(),
      'member': _defaultPermissions,
    };
  }

  Future<void> initialize() async {
    // Initialize and request necessary permissions
    await Permission.location.request();
    await Permission.notification.request();
    await Permission.camera.request();
    await Permission.storage.request();
  }

  /// Get default permissions for a given role
  Map<String, bool> getPermissionsForRole(String role) {
    try {
      return _permissions[role.toLowerCase()] ?? _defaultPermissions;
    } catch (e) {
      return _defaultPermissions;
    }
  }

  Map<String, bool> _getAdminPermissions() {
    return {
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
  }

  static Map<String, bool> _getPastorPermissions() {
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

  static Map<String, bool> _getWorkerPermissions() {
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

  static Map<String, bool> _getMemberPermissions() {
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
