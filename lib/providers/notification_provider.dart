import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'supabase_provider.dart';
import 'dart:async';

class NotificationProvider extends ChangeNotifier {
  final SupabaseProvider _supabaseProvider;

  int _unreadCount = 0;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  StreamSubscription? _notificationSubscription;

  NotificationProvider(this._supabaseProvider) {
    _initializeNotifications();
  }

  // Getters
  int get unreadCount => _unreadCount;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Reset notification state (called when user logs out or changes)
  void resetNotificationState() {
    debugPrint('=== NotificationProvider: Resetting notification state ===');
    _unreadCount = 0;
    _notifications = [];
    _isLoading = false;
    _error = null;
    _currentUserId = null;
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    notifyListeners();
  }

  /// Load unread notification count
  Future<void> _loadUnreadCount() async {
    try {
      _unreadCount = await _supabaseProvider.getUnreadNotificationCount();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load unread count: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Initialize notifications and set up real-time updates
  void _initializeNotifications() {
    debugPrint('=== NotificationProvider: Initializing notifications ===');
    final userId = Supabase.instance.client.auth.currentUser?.id;
    debugPrint('Current user ID: $userId');

    // Check if user has changed
    if (_currentUserId != userId) {
      debugPrint(
          'User changed from $_currentUserId to $userId - resetting state');
      resetNotificationState();
      _currentUserId = userId;
    }

    if (userId == null) {
      debugPrint(
          'No authenticated user found - skipping notification initialization');
      return;
    }

    _loadUnreadCount();
    _setupRealtimeUpdates();
  }

  /// Reinitialize notifications (call this when user logs in/out)
  void reinitialize() {
    _initializeNotifications();
  }

  /// Set up real-time updates for notifications
  Future<void> loadNotifications() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get the stream and take the first value
      final stream = _supabaseProvider.getUserNotifications();
      _notifications = await stream.first;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading notifications: $e');
    }
  }

  void _setupRealtimeUpdates() {
    _notificationSubscription?.cancel();
    _notificationSubscription = _supabaseProvider.getUserNotifications().listen(
      (notifications) {
        _notifications = notifications;
        _unreadCount = notifications.where((n) => n.isRead == false).length;
        notifyListeners();
      },
      onError: (error) {
        print('Error in notification stream: $error');
      },
    );
  }

  Future<void> initialize() async {
    await loadNotifications();
    await _loadUnreadCount();
    _setupRealtimeUpdates();
  }

  /// Mark notifications as seen (clears badge count but keeps notifications visible)
  Future<void> markAsSeen() async {
    try {
      // For now, we'll just clear the unread count locally
      // In a full implementation, you might want to add a 'seen_at' field to the database
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark notifications as seen: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Refresh notification count manually
  Future<void> refreshNotificationCount() async {
    await _loadUnreadCount();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await _supabaseProvider.markNotificationAsRead(notificationId);
      if (success) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Failed to mark notification as read: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final success = await _supabaseProvider.markAllNotificationsAsRead();
      if (success) {
        // Update local state
        _notifications = _notifications
            .map((n) =>
                n.isRead ? n : n.copyWith(isRead: true, readAt: DateTime.now()))
            .toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to mark all notifications as read: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final success = await _supabaseProvider.clearAllNotifications();
      if (success) {
        // Update local state immediately
        _notifications = [];
        _unreadCount = 0;
        notifyListeners();

        // Force refresh the count from database to ensure consistency
        await _loadUnreadCount();
      }
    } catch (e) {
      _error = 'Failed to clear all notifications: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
