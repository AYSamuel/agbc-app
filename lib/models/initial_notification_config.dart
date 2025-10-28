/// Configuration for initial meeting notifications
/// This class defines when and how users should be notified about newly created meetings
class InitialNotificationConfig {
  /// Whether to send initial notification about the meeting
  final bool enabled;
  
  /// When to send the notification (immediate, scheduled, or none)
  final NotificationTiming timing;
  
  /// Custom schedule time (required if timing is scheduled)
  final DateTime? scheduledDateTime;

  const InitialNotificationConfig({
    required this.enabled,
    required this.timing,
    this.scheduledDateTime,
  });

  /// Creates a default configuration with immediate notification enabled
  factory InitialNotificationConfig.immediate() {
    return const InitialNotificationConfig(
      enabled: true,
      timing: NotificationTiming.immediate,
    );
  }

  /// Creates a configuration with scheduled notification
  factory InitialNotificationConfig.scheduled(DateTime scheduledDateTime) {
    return InitialNotificationConfig(
      enabled: true,
      timing: NotificationTiming.scheduled,
      scheduledDateTime: scheduledDateTime,
    );
  }

  /// Creates a configuration with no initial notification
  factory InitialNotificationConfig.none() {
    return const InitialNotificationConfig(
      enabled: false,
      timing: NotificationTiming.none,
    );
  }

  /// Creates an InitialNotificationConfig from JSON data
  factory InitialNotificationConfig.fromJson(Map<String, dynamic> json) {
    return InitialNotificationConfig(
      enabled: json['enabled'] ?? true,
      timing: NotificationTiming.values.firstWhere(
        (e) => e.toString().split('.').last == json['timing'],
        orElse: () => NotificationTiming.immediate,
      ),
      scheduledDateTime: json['scheduledDateTime'] != null
          ? DateTime.parse(json['scheduledDateTime'])
          : null,
    );
  }

  /// Converts the InitialNotificationConfig to JSON format
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'timing': timing.toString().split('.').last,
      'scheduledDateTime': scheduledDateTime?.toIso8601String(),
    };
  }

  /// Validates the configuration
  bool get isValid {
    if (!enabled) return true;
    if (timing == NotificationTiming.scheduled && scheduledDateTime == null) {
      return false;
    }
    if (timing == NotificationTiming.scheduled && 
        scheduledDateTime!.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  /// Gets a user-friendly description of the notification timing
  String get description {
    if (!enabled || timing == NotificationTiming.none) {
      return 'No initial notification';
    }
    
    switch (timing) {
      case NotificationTiming.immediate:
        return 'Notify immediately';
      case NotificationTiming.scheduled:
        if (scheduledDateTime != null) {
          return 'Notify on ${_formatDateTime(scheduledDateTime!)}';
        }
        return 'Scheduled notification';
      case NotificationTiming.none:
        return 'No initial notification';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Creates a copy with updated fields
  InitialNotificationConfig copyWith({
    bool? enabled,
    NotificationTiming? timing,
    DateTime? scheduledDateTime,
  }) {
    return InitialNotificationConfig(
      enabled: enabled ?? this.enabled,
      timing: timing ?? this.timing,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InitialNotificationConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          timing == other.timing &&
          scheduledDateTime == other.scheduledDateTime;

  @override
  int get hashCode => Object.hash(enabled, timing, scheduledDateTime);
}

/// Enum for notification timing options
enum NotificationTiming {
  /// Send notification immediately when meeting is created
  immediate,
  
  /// Send notification at a custom scheduled time
  scheduled,
  
  /// Don't send initial notification
  none,
}

/// Extension to get user-friendly names for NotificationTiming
extension NotificationTimingExtension on NotificationTiming {
  String get displayName {
    switch (this) {
      case NotificationTiming.immediate:
        return 'Immediate';
      case NotificationTiming.scheduled:
        return 'Scheduled';
      case NotificationTiming.none:
        return 'None';
    }
  }

  String get description {
    switch (this) {
      case NotificationTiming.immediate:
        return 'Send notification right away';
      case NotificationTiming.scheduled:
        return 'Send notification at a specific time';
      case NotificationTiming.none:
        return 'Don\'t send initial notification';
    }
  }
}