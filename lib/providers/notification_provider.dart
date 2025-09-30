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
  bool _disposed = false; // Add disposal flag

  NotificationProvider(this._supabaseProvider) {
    _initializeNotifications();
  }

  // Getters
  int get unreadCount => _unreadCount;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SupabaseProvider get supabaseProvider => _supabaseProvider;
  bool get disposed => _disposed;

  /// Reset notification state (called when user logs out or changes)
  void resetNotificationState() {
    if (_disposed) return; // Check disposal before proceeding
    debugPrint('=== NotificationProvider: Resetting notification state ===');
    _unreadCount = 0;
    _notifications = [];
    _isLoading = false;
    _error = null;
    _currentUserId = null;
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    if (!_disposed) notifyListeners(); // Safe notify
  }

  /// Load unread notification count
  Future<void> _loadUnreadCount() async {
    if (_disposed) return; // Check disposal
    try {
      _unreadCount = await _supabaseProvider.getUnreadNotificationCount();
      if (!_disposed) notifyListeners(); // Safe notify
    } catch (e) {
      if (_disposed) return; // Don't update state if disposed
      _error = 'Failed to load unread count: $e';
      debugPrint(_error);
      if (!_disposed) notifyListeners(); // Safe notify
    }
  }

  /// Initialize notifications and set up real-time updates
  void _initializeNotifications() {
    if (_disposed) return; // Check disposal
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
    if (_disposed) return; // Check disposal
    _initializeNotifications();
  }

  /// Set up real-time updates for notifications
  Future<void> loadNotifications() async {
    if (_disposed) return; // Check disposal
    try {
      _isLoading = true;
      if (!_disposed) notifyListeners();

      // Get the stream and take the first value
      final stream = _supabaseProvider.getUserNotifications();
      _notifications = await stream.first;

      if (_disposed) return; // Check disposal after async operation
      _isLoading = false;
      if (!_disposed) notifyListeners();
    } catch (e) {
      if (_disposed) return; // Don't update state if disposed
      _isLoading = false;
      if (!_disposed) notifyListeners();
      debugPrint('Error loading notifications: $e');
    }
  }

  void _setupRealtimeUpdates() {
    if (_disposed) return; // Check disposal
    _notificationSubscription?.cancel();
    _notificationSubscription = _supabaseProvider.getUserNotifications().listen(
      (notifications) {
        if (_disposed) return; // Check disposal in callback
        _notifications = notifications;
        _unreadCount = notifications.where((n) => n.isRead == false).length;
        if (!_disposed) notifyListeners(); // Safe notify
      },
      onError: (error) {
        if (_disposed) return; // Check disposal in error callback
        debugPrint('Error in notification stream: $error');
      },
    );
  }

  Future<void> initialize() async {
    if (_disposed) return; // Check disposal
    await loadNotifications();
    await _loadUnreadCount();
    _setupRealtimeUpdates();
  }

  /// Mark notifications as seen (clears badge count but keeps notifications visible)
  Future<void> markAsSeen() async {
    if (_disposed) return; // Check disposal
    try {
      // For now, we'll just clear the unread count locally
      // In a full implementation, you might want to add a 'seen_at' field to the database
      _unreadCount = 0;
      if (!_disposed) notifyListeners(); // Safe notify
    } catch (e) {
      if (_disposed) return; // Don't update state if disposed
      _error = 'Failed to mark notifications as seen: $e';
      debugPrint(_error);
      if (!_disposed) notifyListeners(); // Safe notify
    }
  }

  /// Refresh notification count manually
  Future<void> refreshNotificationCount() async {
    if (_disposed) return; // Check disposal
    await _loadUnreadCount();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_disposed) return; // Check disposal
    try {
      final success = await _supabaseProvider.markNotificationAsRead(notificationId);
      if (_disposed) return; // Check disposal after async operation
      if (success) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          if (!_disposed) notifyListeners(); // Safe notify
        }
      }
    } catch (e) {
      if (_disposed) return; // Don't update state if disposed
      _error = 'Failed to mark notification as read: $e';
      debugPrint(_error);
      if (!_disposed) notifyListeners(); // Safe notify
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_disposed) return; // Check disposal
    try {
      final success = await _supabaseProvider.markAllNotificationsAsRead();
      if (_disposed) return; // Check disposal after async operation
      if (success) {
        // Update local state
        _notifications = _notifications
            .map((n) =>
                n.isRead ? n : n.copyWith(isRead: true, readAt: DateTime.now()))
            .toList();
        _unreadCount = 0;
        if (!_disposed) notifyListeners(); // Safe notify
      }
    } catch (e) {
      if (_disposed) return; // Don't update state if disposed
      _error = 'Failed to mark all notifications as read: $e';
      debugPrint(_error);
      if (!_disposed) notifyListeners(); // Safe notify
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    if (_disposed) return; // Check disposal
    try {
      final success = await _supabaseProvider.clearAllNotifications();
      if (_disposed) return; // Check disposal after async operation
      if (success) {
        // Update local state immediately
        _notifications = [];
        _unreadCount = 0;
        if (!_disposed) notifyListeners(); // Safe notify

        // Force refresh the count from database to ensure consistency
        await _loadUnreadCount();
      }
    } catch (e) {
      if (_disposed) return; // Don't update state if disposed
      _error = 'Failed to clear all notifications: $e';
      debugPrint(_error);
      if (!_disposed) notifyListeners(); // Safe notify
    }
  }

  /// Clear error state
  void clearError() {
    if (_disposed) return; // Check disposal
    _error = null;
    if (!_disposed) notifyListeners(); // Safe notify
  }

  @override
  void dispose() {
    _disposed = true; // Set disposal flag first
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
