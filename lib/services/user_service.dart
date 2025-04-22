// lib/services/user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart'; // Import the UserModel
import 'package:flutter/material.dart';
import 'supabase_service.dart';

/// Service class for handling user-related operations with Supabase.
class UserService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final SupabaseService _supabaseService;

  UserModel? _currentUser;
  Map<String, dynamic>? _currentUserData;
  
  UserModel? get currentUser => _currentUser;
  
  UserService() {
    _supabaseService = SupabaseService();
    initialize();
  }

  Future<void> initialize() async {
    try {
      await _loadUserData();
    } catch (e) {
      // Handle error silently in production
    }
  }

  /// Fetches user details from Supabase by user ID.
  ///
  /// [id] is the unique identifier of the user.
  Future<UserModel?> getUserDetails(String userId) async {
    try {
      final data = await _supabase.from('users').select().eq('id', userId).single();
      if (data != null) {
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      rethrow; // Let the UI handle the error
    }
  }

  /// Updates user information in Supabase.
  ///
  /// [user] is the UserModel containing updated user information.
  Future<void> updateUser(UserModel user) async {
    try {
      await _supabase.from('users').update(user.toJson()).eq('id', user.id);
      if (user.id == _currentUser?.id) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      rethrow; // Let the UI handle the error
    }
  }

  /// Creates a new user in Supabase.
  ///
  /// [user] is the UserModel containing user information.
  Future<void> createUser(UserModel user) async {
    try {
      await _supabase.from('users').insert(user.toJson());
    } catch (e) {
      rethrow; // Let the UI handle the error
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase.from('users').select().eq('id', user.id).single();
        if (data != null) {
          _currentUser = UserModel.fromJson(data);
          notifyListeners();
        }
      }
    } catch (e) {
      rethrow; // Let the UI handle the error
    }
  }

  Future<void> loadUserData(String id) async {
    try {
      final userDoc = await _supabase.from('users').select().eq('id', id).single();
      if (userDoc != null) {
        _currentUserData = userDoc;
        notifyListeners();
      }
    } catch (e) {
      rethrow; // Let the UI handle the error
    }
  }

  Map<String, dynamic>? get currentUserData => _currentUserData;

  Future<UserModel?> getUserData(String id) async {
    try {
      final doc = await _supabase.from('users').select().eq('id', id).single();
      if (doc != null) {
        return UserModel.fromJson(doc);
      }
      return null;
    } catch (e) {
      rethrow; // Let the UI handle the error
    }
  }
}
