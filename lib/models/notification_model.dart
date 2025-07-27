/// Enhanced NotificationModel with OneSignal integration and advanced scheduling.
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? readAt;

  // OneSignal integration fields
  final String? oneSignalNotificationId; // Track OneSignal notification ID
  final DateTime? scheduledFor; // When to send the notification
  final bool isPushSent; // Whether push notification was sent
  final NotificationDeliveryStatus deliveryStatus; // Delivery tracking
  final int retryCount; // Number of retry attempts
  final DateTime? lastRetryAt; // Last retry timestamp
  final String? failureReason; // Reason for delivery failure

  // Meeting-specific scheduling fields
  final String? relatedEntityId; // ID of related task/meeting/etc
  final String? relatedEntityType; // Type: 'task', 'meeting', 'user', etc
  final Map<String, dynamic> schedulingConfig; // Custom scheduling configuration

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    Map<String, dynamic>? data,
    this.isRead = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.readAt,
    // OneSignal fields
    this.oneSignalNotificationId,
    this.scheduledFor,
    this.isPushSent = false,
    this.deliveryStatus = NotificationDeliveryStatus.pending,
    this.retryCount = 0,
    this.lastRetryAt,
    this.failureReason,
    // Related entity fields
    this.relatedEntityId,
    this.relatedEntityType,
    Map<String, dynamic>? schedulingConfig,
  }) : data = data ?? {},
       schedulingConfig = schedulingConfig ?? {},
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: NotificationTypeExtension.fromDatabaseValue(json['type'] ?? 'general'),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at']) 
          : null,
      oneSignalNotificationId: json['onesignal_notification_id'],
      scheduledFor: json['scheduled_for'] != null 
          ? DateTime.parse(json['scheduled_for']) 
          : null,
      isPushSent: json['is_push_sent'] ?? false,
      deliveryStatus: NotificationDeliveryStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['delivery_status'],
        orElse: () => NotificationDeliveryStatus.pending,
      ),
      retryCount: json['retry_count'] ?? 0,
      lastRetryAt: json['last_retry_at'] != null 
          ? DateTime.parse(json['last_retry_at']) 
          : null,
      failureReason: json['failure_reason'],
      relatedEntityId: json['related_entity_id'],
      relatedEntityType: json['related_entity_type'],
      schedulingConfig: Map<String, dynamic>.from(json['scheduling_config'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.databaseValue,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      // OneSignal fields
      'onesignal_notification_id': oneSignalNotificationId,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'is_push_sent': isPushSent,
      'delivery_status': deliveryStatus.toString().split('.').last,
      'retry_count': retryCount,
      'last_retry_at': lastRetryAt?.toIso8601String(),
      'failure_reason': failureReason,
      // Related entity fields
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
      'scheduling_config': schedulingConfig,
    };
  }

  /// Checks if this notification should be sent as push
  bool get shouldSendPush {
    if (isPushSent) return false;
    if (deliveryStatus == NotificationDeliveryStatus.failed && retryCount >= 3) {
      return false;
    }
    return scheduledFor == null || DateTime.now().isAfter(scheduledFor!);
  }

  /// Checks if notification is due for retry
  bool get shouldRetry {
    if (deliveryStatus != NotificationDeliveryStatus.failed) return false;
    if (retryCount >= 3) return false;
    
    final retryDelay = Duration(minutes: [1, 5, 15][retryCount]);
    return lastRetryAt == null || 
           DateTime.now().isAfter(lastRetryAt!.add(retryDelay));
  }

  /// Gets OneSignal payload for this notification
  Map<String, dynamic> get oneSignalPayload {
    Map<String, dynamic> payload = {
      'headings': {'en': title},
      'contents': {'en': message},
      'data': {
        'notification_id': id,
        'type': type.databaseValue,
        'action_data': data,
        'related_entity_id': relatedEntityId,
        'related_entity_type': relatedEntityType,
      },
      'include_external_user_ids': [userId],
    };

    // Add scheduling if specified
    if (scheduledFor != null && scheduledFor!.isAfter(DateTime.now())) {
      payload['send_after'] = scheduledFor!.toUtc().toIso8601String();
    }

    // Add custom scheduling config
    if (schedulingConfig.isNotEmpty) {
      payload.addAll(schedulingConfig);
    }

    return payload;
  }

  /// Gets the notification icon based on type
  String get icon {
    switch (type) {
      case NotificationType.taskAssigned:
        return '📋';
      case NotificationType.taskDue:
        return '⏰';
      case NotificationType.taskCompleted:
        return '✅';
      case NotificationType.meetingReminder:
        return '📅';
      case NotificationType.meetingCancelled:
        return '❌';
      case NotificationType.meetingUpdated:
        return '📝';
      case NotificationType.commentAdded:
        return '💬';
      case NotificationType.roleChanged:
        return '👤';
      case NotificationType.branchAnnouncement:
        return '📢';
      case NotificationType.general:
        return '📢';
    }
  }

  /// Gets the notification priority
  int get priority {
    switch (type) {
      case NotificationType.taskDue:
      case NotificationType.meetingCancelled:
        return 3; // High
      case NotificationType.taskAssigned:
      case NotificationType.taskCompleted:
      case NotificationType.meetingReminder:
      case NotificationType.meetingUpdated:
      case NotificationType.roleChanged:
        return 2; // Medium
      case NotificationType.commentAdded:
      case NotificationType.branchAnnouncement:
      case NotificationType.general:
        return 1; // Low
    }
  }

  /// Gets the notification color for UI
  String get color {
    switch (type) {
      case NotificationType.taskAssigned:
        return '#2196F3'; // Blue
      case NotificationType.taskDue:
        return '#FF9800'; // Orange
      case NotificationType.taskCompleted:
        return '#4CAF50'; // Green
      case NotificationType.meetingReminder:
        return '#9C27B0'; // Purple
      case NotificationType.meetingCancelled:
        return '#F44336'; // Red
      case NotificationType.meetingUpdated:
        return '#FF9800'; // Orange
      case NotificationType.commentAdded:
        return '#607D8B'; // Blue Gray
      case NotificationType.roleChanged:
        return '#795548'; // Brown
      case NotificationType.branchAnnouncement:
        return '#3F51B5'; // Indigo
      case NotificationType.general:
        return '#9E9E9E'; // Gray
    }
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
    String? oneSignalNotificationId,
    DateTime? scheduledFor,
    bool? isPushSent,
    NotificationDeliveryStatus? deliveryStatus,
    int? retryCount,
    DateTime? lastRetryAt,
    String? failureReason,
    String? relatedEntityId,
    String? relatedEntityType,
    Map<String, dynamic>? schedulingConfig,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      readAt: readAt ?? this.readAt,
      oneSignalNotificationId: oneSignalNotificationId ?? this.oneSignalNotificationId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isPushSent: isPushSent ?? this.isPushSent,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      failureReason: failureReason ?? this.failureReason,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      schedulingConfig: schedulingConfig ?? this.schedulingConfig,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Enum for notification types matching the database schema
enum NotificationType {
  taskAssigned,
  taskDue,
  taskCompleted,
  meetingReminder,
  meetingCancelled,
  meetingUpdated,
  commentAdded,
  roleChanged,
  branchAnnouncement,
  general,
}

/// Extension to handle database mapping for NotificationType
extension NotificationTypeExtension on NotificationType {
  /// Converts enum to database string value (snake_case)
  String get databaseValue {
    switch (this) {
      case NotificationType.taskAssigned:
        return 'task_assigned';
      case NotificationType.taskDue:
        return 'task_due';
      case NotificationType.taskCompleted:
        return 'task_completed';
      case NotificationType.meetingReminder:
        return 'meeting_reminder';
      case NotificationType.meetingCancelled:
        return 'meeting_cancelled';
      case NotificationType.meetingUpdated:
        return 'meeting_updated';
      case NotificationType.commentAdded:
        return 'comment_added';
      case NotificationType.roleChanged:
        return 'role_changed';
      case NotificationType.branchAnnouncement:
        return 'branch_announcement';
      case NotificationType.general:
        return 'general';
    }
  }

  /// Creates enum from database string value (snake_case)
  static NotificationType fromDatabaseValue(String value) {
    switch (value) {
      case 'task_assigned':
        return NotificationType.taskAssigned;
      case 'task_due':
        return NotificationType.taskDue;
      case 'task_completed':
        return NotificationType.taskCompleted;
      case 'meeting_reminder':
        return NotificationType.meetingReminder;
      case 'meeting_cancelled':
        return NotificationType.meetingCancelled;
      case 'meeting_updated':
        return NotificationType.meetingUpdated;
      case 'comment_added':
        return NotificationType.commentAdded;
      case 'role_changed':
        return NotificationType.roleChanged;
      case 'branch_announcement':
        return NotificationType.branchAnnouncement;
      case 'general':
      default:
        return NotificationType.general;
    }
  }
}

/// Enum for notification delivery status
enum NotificationDeliveryStatus {
  pending,
  scheduled,
  sent,
  delivered,
  failed,
  cancelled,
}