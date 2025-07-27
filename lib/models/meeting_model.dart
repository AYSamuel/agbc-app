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
  final String organizer;
  final String location;
  final bool isVirtual;
  final String? meetingLink;
  final int expectedAttendance;
  final Map<String, dynamic> attendees; // Now JSONB for structured data

  // Meeting status tracking using ENUM
  final MeetingStatus status;

  // Enhanced features
  final Map<String, dynamic> metadata; // Additional meeting metadata

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
    required this.organizer,
    required this.location,
    this.isVirtual = false,
    this.meetingLink,
    this.expectedAttendance = 0,
    Map<String, dynamic>? attendees,
    this.status = MeetingStatus.scheduled,
    Map<String, dynamic>? metadata,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       attendees = attendees ?? {},
       metadata = metadata ?? {};

  /// Creates a MeetingModel instance from JSON data
  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: DateTime.parse(json['date_time']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      type: json['type'] ?? 'local',
      branchId: json['branch_id'],
      category: json['category'] ?? 'general',
      organizer: json['organizer'] ?? '',
      location: json['location'] ?? '',
      isVirtual: json['is_virtual'] ?? false,
      meetingLink: json['meeting_link'],
      expectedAttendance: json['expected_attendance'] ?? 0,
      attendees: Map<String, dynamic>.from(json['attendees'] as Map? ?? {}),
      status: MeetingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MeetingStatus.scheduled,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  /// Converts the MeetingModel instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_time': dateTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'type': type,
      'branch_id': branchId,
      'category': category,
      'organizer': organizer,
      'location': location,
      'is_virtual': isVirtual,
      'meeting_link': meetingLink,
      'expected_attendance': expectedAttendance,
      'attendees': attendees,
      'status': status.toString().split('.').last,
      'metadata': metadata,
    };
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

  /// Gets list of attendee user IDs
  List<String> get attendeeIds {
    return List<String>.from(attendees['confirmed'] ?? []);
  }

  /// Gets list of pending attendee user IDs
  List<String> get pendingAttendeeIds {
    return List<String>.from(attendees['pending'] ?? []);
  }

  /// Gets the status color for UI display
  String get statusColor {
    switch (status) {
      case MeetingStatus.scheduled:
        return '#2196F3'; // Blue
      case MeetingStatus.ongoing:
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
    String? organizer,
    String? location,
    bool? isVirtual,
    String? meetingLink,
    int? expectedAttendance,
    Map<String, dynamic>? attendees,
    MeetingStatus? status,
    Map<String, dynamic>? metadata,
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
      organizer: organizer ?? this.organizer,
      location: location ?? this.location,
      isVirtual: isVirtual ?? this.isVirtual,
      meetingLink: meetingLink ?? this.meetingLink,
      expectedAttendance: expectedAttendance ?? this.expectedAttendance,
      attendees: attendees ?? this.attendees,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
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
  ongoing,
  completed,
  cancelled,
}
