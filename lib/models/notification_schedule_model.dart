import 'notification_model.dart'; // Import for NotificationType enum

/// NotificationScheduleModel for managing notification timing and rules.
class NotificationScheduleModel {
  final String id;
  final String entityType; // 'meeting', 'task', 'general'
  final String? entityId; // Specific entity ID (optional for templates)
  final String name; // Schedule name/description
  final List<NotificationTiming> timings; // When to send notifications
  final bool isActive;
  final bool isTemplate; // Whether this is a reusable template
  final Map<String, dynamic> conditions; // Conditions for when to apply
  final Map<String, dynamic> settings; // Additional settings
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  NotificationScheduleModel({
    required this.id,
    required this.entityType,
    this.entityId,
    required this.name,
    required this.timings,
    this.isActive = true,
    this.isTemplate = false,
    Map<String, dynamic>? conditions,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.createdBy,
  })  : conditions = conditions ?? {},
        settings = settings ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    // Validate entity type
    if (!['meeting', 'task', 'general'].contains(entityType)) {
      throw ArgumentError('Invalid entity type: $entityType');
    }

    // Validate timings
    if (timings.isEmpty && !isTemplate) {
      throw ArgumentError(
          'Non-template schedules must have at least one timing');
    }
  }

  factory NotificationScheduleModel.fromJson(Map<String, dynamic> json) {
    return NotificationScheduleModel(
      id: json['id'] ?? '',
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'],
      name: json['name'] ?? '',
      timings: (json['timings'] as List?)
              ?.map((t) => NotificationTiming.fromJson(t))
              .toList() ??
          [],
      isActive: json['is_active'] ?? true,
      isTemplate: json['is_template'] ?? false,
      conditions: Map<String, dynamic>.from(json['conditions'] as Map? ?? {}),
      settings: Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      createdBy: json['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'name': name,
      'timings': timings.map((t) => t.toJson()).toList(),
      'is_active': isActive,
      'is_template': isTemplate,
      'conditions': conditions,
      'settings': settings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  /// Gets the schedule as JSONB for database storage
  Map<String, dynamic> get scheduleJsonb {
    return {
      'timings': timings.map((t) => t.toJson()).toList(),
      'conditions': conditions,
      'settings': settings,
    };
  }

  /// Validates if the schedule is properly configured
  bool get isValid {
    if (name.trim().isEmpty) return false;
    if (timings.isEmpty && !isTemplate) return false;
    return timings.every((timing) => timing.isValid);
  }

  /// Gets all notification times for a given event
  List<DateTime> getNotificationTimes(DateTime eventTime) {
    return timings
        .where((timing) => timing.isValid)
        .map((timing) => timing.calculateNotificationTime(eventTime))
        .where((time) => time.isAfter(DateTime.now()))
        .toList()
      ..sort();
  }

  NotificationScheduleModel copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? name,
    List<NotificationTiming>? timings,
    bool? isActive,
    bool? isTemplate,
    Map<String, dynamic>? conditions,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return NotificationScheduleModel(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      name: name ?? this.name,
      timings: timings ?? this.timings,
      isActive: isActive ?? this.isActive,
      isTemplate: isTemplate ?? this.isTemplate,
      conditions: conditions ?? this.conditions,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationScheduleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a specific notification timing
class NotificationTiming {
  final int? days; // Days before event
  final int? hours; // Hours before event
  final int? minutes; // Minutes before event
  final String? customTime; // Custom time format (e.g., "09:00")
  final String message; // Custom message for this timing
  final NotificationType type; // Type of notification
  final Map<String, dynamic> config; // Additional configuration

  NotificationTiming({
    this.days,
    this.hours,
    this.minutes,
    this.customTime,
    required this.message,
    this.type = NotificationType.general,
    Map<String, dynamic>? config,
  }) : config = config ?? {} {
    // Validate timing values
    if (days != null && days! < 0) {
      throw ArgumentError('Days cannot be negative');
    }
    if (hours != null && hours! < 0) {
      throw ArgumentError('Hours cannot be negative');
    }
    if (minutes != null && minutes! < 0) {
      throw ArgumentError('Minutes cannot be negative');
    }

    // Validate custom time format
    if (customTime != null && !_isValidTimeFormat(customTime!)) {
      throw ArgumentError(
          'Invalid time format. Use HH:MM format (e.g., "09:00")');
    }

    // Validate message
    if (message.trim().isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }
  }

  /// Validates time format (HH:MM)
  static bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  factory NotificationTiming.fromJson(Map<String, dynamic> json) {
    return NotificationTiming(
      days: json['days'],
      hours: json['hours'],
      minutes: json['minutes'],
      customTime: json['custom_time'],
      message: json['message'] ?? '',
      type: NotificationTypeExtension.fromDatabaseValue(
          json['type'] ?? 'general'),
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'hours': hours,
      'minutes': minutes,
      'custom_time': customTime,
      'message': message,
      'type': type.databaseValue,
      'config': config,
    };
  }

  /// Validates if the timing configuration is valid
  bool get isValid {
    // Must have at least one timing component or custom time
    final hasTimingComponent = days != null || hours != null || minutes != null;
    final hasCustomTime = customTime != null && customTime!.isNotEmpty;

    if (!hasTimingComponent && !hasCustomTime) return false;
    if (message.trim().isEmpty) return false;

    // Validate custom time format if present
    if (customTime != null && !_isValidTimeFormat(customTime!)) return false;

    return true;
  }

  /// Calculates the notification time based on an event time
  DateTime calculateNotificationTime(DateTime eventTime) {
    DateTime notificationTime = eventTime;

    if (days != null) {
      notificationTime = notificationTime.subtract(Duration(days: days!));
    }
    if (hours != null) {
      notificationTime = notificationTime.subtract(Duration(hours: hours!));
    }
    if (minutes != null) {
      notificationTime = notificationTime.subtract(Duration(minutes: minutes!));
    }

    // Handle custom time (e.g., "09:00" means send at 9 AM on the calculated date)
    if (customTime != null && customTime!.isNotEmpty) {
      final timeParts = customTime!.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 9;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        // Ensure hour and minute are valid
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          notificationTime = DateTime(
            notificationTime.year,
            notificationTime.month,
            notificationTime.day,
            hour,
            minute,
          );
        }
      }
    }

    return notificationTime;
  }

  /// Gets a human-readable description of the timing
  String get description {
    List<String> parts = [];

    if (days != null && days! > 0) {
      parts.add('$days day${days! > 1 ? 's' : ''}');
    }
    if (hours != null && hours! > 0) {
      parts.add('$hours hour${hours! > 1 ? 's' : ''}');
    }
    if (minutes != null && minutes! > 0) {
      parts.add('$minutes minute${minutes! > 1 ? 's' : ''}');
    }

    if (parts.isEmpty && customTime != null && customTime!.isNotEmpty) {
      return 'At $customTime';
    }

    if (parts.isEmpty) {
      return 'Immediately';
    }

    String timing = '${parts.join(', ')} before';
    if (customTime != null && customTime!.isNotEmpty) {
      timing += ' at $customTime';
    }

    return timing;
  }

  /// Gets the total offset in minutes
  int get totalOffsetMinutes {
    int total = 0;
    if (days != null) total += days! * 24 * 60;
    if (hours != null) total += hours! * 60;
    if (minutes != null) total += minutes!;
    return total;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTiming &&
          runtimeType == other.runtimeType &&
          days == other.days &&
          hours == other.hours &&
          minutes == other.minutes &&
          customTime == other.customTime &&
          message == other.message &&
          type == other.type;

  @override
  int get hashCode =>
      Object.hash(days, hours, minutes, customTime, message, type);
}

/// Predefined notification schedules for common scenarios
class NotificationScheduleTemplates {
  static NotificationScheduleModel get meetingDefault =>
      NotificationScheduleModel(
        id: 'meeting_default',
        entityType: 'meeting',
        name: 'Default Meeting Reminders',
        isTemplate: true,
        createdBy: 'system',
        timings: [
          NotificationTiming(
            days: 7,
            message: 'You have a meeting coming up next week',
            type: NotificationType.meetingReminder,
          ),
          NotificationTiming(
            days: 1,
            customTime: '09:00',
            message: 'Reminder: You have a meeting tomorrow',
            type: NotificationType.meetingReminder,
          ),
          NotificationTiming(
            hours: 1,
            message: 'Your meeting starts in 1 hour',
            type: NotificationType.meetingReminder,
          ),
        ],
      );

  static NotificationScheduleModel get taskDefault => NotificationScheduleModel(
        id: 'task_default',
        entityType: 'task',
        name: 'Default Task Reminders',
        isTemplate: true,
        createdBy: 'system',
        timings: [
          NotificationTiming(
            days: 2,
            customTime: '09:00',
            message: 'Task due in 2 days',
            type: NotificationType.taskDue,
          ),
          NotificationTiming(
            days: 1,
            customTime: '09:00',
            message: 'Task due tomorrow',
            type: NotificationType.taskDue,
          ),
          NotificationTiming(
            hours: 2,
            message: 'Task due in 2 hours',
            type: NotificationType.taskDue,
          ),
        ],
      );

  static NotificationScheduleModel get urgentTaskDefault =>
      NotificationScheduleModel(
        id: 'urgent_task_default',
        entityType: 'task',
        name: 'Urgent Task Reminders',
        isTemplate: true,
        createdBy: 'system',
        timings: [
          NotificationTiming(
            days: 1,
            customTime: '09:00',
            message: 'Urgent task due tomorrow',
            type: NotificationType.taskDue,
          ),
          NotificationTiming(
            hours: 4,
            message: 'Urgent task due in 4 hours',
            type: NotificationType.taskDue,
          ),
          NotificationTiming(
            hours: 1,
            message: 'Urgent task due in 1 hour',
            type: NotificationType.taskDue,
          ),
        ],
      );

  static NotificationScheduleModel get meetingMinimal =>
      NotificationScheduleModel(
        id: 'meeting_minimal',
        entityType: 'meeting',
        name: 'Minimal Meeting Reminders',
        isTemplate: true,
        createdBy: 'system',
        timings: [
          NotificationTiming(
            days: 1,
            customTime: '09:00',
            message: 'Meeting tomorrow',
            type: NotificationType.meetingReminder,
          ),
          NotificationTiming(
            minutes: 15,
            message: 'Meeting starts in 15 minutes',
            type: NotificationType.meetingReminder,
          ),
        ],
      );
}
