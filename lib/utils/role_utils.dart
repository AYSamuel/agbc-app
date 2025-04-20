import 'package:flutter/material.dart';

class RoleUtils {
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'pastor':
        return Colors.purple;
      case 'worker':
        return Colors.blue;
      case 'member':
      default:
        return Colors.green;
    }
  }
} 