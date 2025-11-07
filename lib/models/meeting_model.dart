import 'initial_notification_config.dart';

/// Enum for recurrence frequency matching the database schema
enum RecurrenceFrequency {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

/// Enhanced MeetingModel with new schema features including metadata and ENUM status.
class MeetingModel {
  // Basic meeting information
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final DateTime createdAt;
  final DateTime updatedAt; // New field for tracking updates
  final DateTime? endTime;

  // Meeting classification
  final String type; // "global" or "local"
  final String? branchId;
  final String category;

  // Organizational details
  final String organizerId; // Changed from 'organizer' to match DB
  final String organizerName; // Keep this for display purposes
  final String location;
  final bool isVirtual;
  final String? meetingLink;
  final Map<String, dynamic> attendees; // Now JSONB for structured data

  // Meeting status tracking using ENUM
  final MeetingStatus status;

  // Enhanced features
  final Map<String, dynamic> metadata; // Additional meeting metadata

  // Initial notification control
  final InitialNotificationConfig? initialNotificationConfig;
  final bool initialNotificationSent;
  final DateTime? initialNotificationSentAt;

  // Recurring meeting fields
  final bool isRecurring;
  final RecurrenceFrequency recurrenceFrequency;
  final int recurrenceInterval;
  final DateTime? recurrenceEndDate;
  final int? recurrenceCount;
  final String? parentMeetingId;
  final int? recurrenceDayOfWeek;
  final int? recurrenceDayOfMonth;
  final List<DateTime> recurrenceExceptions;

  /// Constructor for creating a new MeetingModel instance
  MeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type,
    this.branchId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.endTime,
    this.category = 'general',
    required this.organizerId,
    required this.organizerName,
    required this.location,
    this.isVirtual = false,
    this.meetingLink,
    Map<String, dynamic>? attendees,
    this.status = MeetingStatus.scheduled,
    Map<String, dynamic>? metadata,
    this.initialNotificationConfig,
    this.initialNotificationSent = false,
    this.initialNotificationSentAt,
    // Recurring meeting parameters
    this.isRecurring = false,
    this.recurrenceFrequency = RecurrenceFrequency.none,
    this.recurrenceInterval = 1,
    this.recurrenceEndDate,
    this.recurrenceCount,
    this.parentMeetingId,
    this.recurrenceDayOfWeek,
    this.recurrenceDayOfMonth,
    List<DateTime>? recurrenceExceptions,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        attendees = attendees ?? {},
        metadata = metadata ?? {},
        recurrenceExceptions = recurrenceExceptions ?? [];

  /// Creates a MeetingModel instance from JSON data
  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: DateTime.parse(json['start_time']),
      type: json['type'] ?? 'local',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      endTime: DateTime.parse(json['end_time']),
      branchId: json['branch_id'],
      organizerId: json['organizer_id'] ?? '',
      organizerName: json['organizer_name'] ?? '',
      location: json['location'] ?? '',
      isVirtual: json['is_virtual'] ?? false,
      meetingLink: json['meeting_link'],
      attendees: {
        'confirmed': List<String>.from(json['attendees'] ?? []),
        'pending': <String>[]
      }, // Convert array to map format for internal use
      status: MeetingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MeetingStatus.scheduled,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      initialNotificationConfig: json['initial_notification_config'] != null
          ? InitialNotificationConfig.fromJson(
              Map<String, dynamic>.from(json['initial_notification_config']))
          : null,
      initialNotificationSent: json['initial_notification_sent'] ?? false,
      initialNotificationSentAt: json['initial_notification_sent_at'] != null
          ? DateTime.parse(json['initial_notification_sent_at'])
          : null,
      // Recurring meeting fields
      isRecurring: json['is_recurring'] ?? false,
      recurrenceFrequency: json['recurrence_frequency'] != null
          ? RecurrenceFrequency.values.firstWhere(
              (e) => e.toString().split('.').last == json['recurrence_frequency'],
              orElse: () => RecurrenceFrequency.none,
            )
          : RecurrenceFrequency.none,
      recurrenceInterval: json['recurrence_interval'] ?? 1,
      recurrenceEndDate: json['recurrence_end_date'] != null
          ? DateTime.parse(json['recurrence_end_date'])
          : null,
      recurrenceCount: json['recurrence_count'],
      parentMeetingId: json['parent_meeting_id'],
      recurrenceDayOfWeek: json['recurrence_day_of_week'],
      recurrenceDayOfMonth: json['recurrence_day_of_month'],
      recurrenceExceptions: json['recurrence_exceptions'] != null
          ? (json['recurrence_exceptions'] as List)
              .map((e) => DateTime.parse(e as String))
              .toList()
          : [],
    );
  }

  /// Converts the MeetingModel instance to JSON format
  Map<String, dynamic> toJson() {
    final json = {
      'title': title,
      'description': description,
      'start_time': dateTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'type': type, // Add type field for global/local distinction
      'organizer_id': organizerId,
      'branch_id': branchId,
      'location': location,
      'is_virtual': isVirtual,
      'meeting_link': meetingLink,
      'attendees': [], // Send as empty array for new meetings
      'status': status.toString().split('.').last,
      'metadata': metadata,
      'initial_notification_config': initialNotificationConfig?.toJson(),
      'initial_notification_sent': initialNotificationSent,
      'initial_notification_sent_at': initialNotificationSentAt?.toIso8601String(),
      // Recurring meeting fields
      'is_recurring': isRecurring,
      'recurrence_frequency': recurrenceFrequency.toString().split('.').last,
      'recurrence_interval': recurrenceInterval,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
      'recurrence_count': recurrenceCount,
      'parent_meeting_id': parentMeetingId,
      'recurrence_day_of_week': recurrenceDayOfWeek,
      'recurrence_day_of_month': recurrenceDayOfMonth,
      'recurrence_exceptions': recurrenceExceptions.map((e) => e.toIso8601String()).toList(),
    };

    // Only include ID if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }

  /// Determines if a meeting should be visible to a user based on their branch affiliation
  bool shouldNotify(String? userBranchId) {
    if (status == MeetingStatus.cancelled) return false;
    if (type == 'global') return true;
    return userBranchId != null && userBranchId == branchId;
  }

  /// Checks if the meeting is currently ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(dateTime) &&
        (endTime == null || now.isBefore(endTime!)) &&
        status != MeetingStatus.cancelled;
  }

  /// Get list of confirmed attendee IDs
  List<String> get attendeeIds {
    return List<String>.from(attendees['confirmed'] ?? []);
  }

  /// Get list of pending attendee IDs
  List<String> get pendingAttendeeIds {
    return List<String>.from(attendees['pending'] ?? []);
  }

  /// Gets the status color for UI display
  String get statusColor {
    switch (status) {
      case MeetingStatus.scheduled:
        return '#2196F3'; // Blue
      case MeetingStatus.inprogress: // Updated from 'ongoing'
        return '#4CAF50'; // Green
      case MeetingStatus.completed:
        return '#9E9E9E'; // Gray
      case MeetingStatus.cancelled:
        return '#F44336'; // Red
    }
  }

  /// Creates a copy of the meeting with updated fields
  MeetingModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? endTime,
    String? type,
    String? branchId,
    String? category,
    String? organizerId,
    String? organizerName,
    String? location,
    bool? isVirtual,
    String? meetingLink,
    Map<String, dynamic>? attendees,
    MeetingStatus? status,
    Map<String, dynamic>? metadata,
    InitialNotificationConfig? initialNotificationConfig,
    bool? initialNotificationSent,
    DateTime? initialNotificationSentAt,
    bool? isRecurring,
    RecurrenceFrequency? recurrenceFrequency,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    int? recurrenceCount,
    String? parentMeetingId,
    int? recurrenceDayOfWeek,
    int? recurrenceDayOfMonth,
    List<DateTime>? recurrenceExceptions,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      branchId: branchId ?? this.branchId,
      category: category ?? this.category,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      location: location ?? this.location,
      isVirtual: isVirtual ?? this.isVirtual,
      meetingLink: meetingLink ?? this.meetingLink,
      attendees: attendees ?? this.attendees,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      initialNotificationConfig: initialNotificationConfig ?? this.initialNotificationConfig,
      initialNotificationSent: initialNotificationSent ?? this.initialNotificationSent,
      initialNotificationSentAt: initialNotificationSentAt ?? this.initialNotificationSentAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceCount: recurrenceCount ?? this.recurrenceCount,
      parentMeetingId: parentMeetingId ?? this.parentMeetingId,
      recurrenceDayOfWeek: recurrenceDayOfWeek ?? this.recurrenceDayOfWeek,
      recurrenceDayOfMonth: recurrenceDayOfMonth ?? this.recurrenceDayOfMonth,
      recurrenceExceptions: recurrenceExceptions ?? this.recurrenceExceptions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeetingModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Enum for meeting status matching the database schema
enum MeetingStatus {
  scheduled,
  inprogress, // Changed from 'ongoing' to match database
  completed,
  cancelled,
}
