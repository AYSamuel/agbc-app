/// Handles both global (church-wide) and local (branch-specific) meetings
/// with scheduling, attendance tracking, and notification features.
class MeetingModel {
  // Basic meeting information
  final String id; // Unique identifier for the meeting
  final String title; // Title/name of the meeting
  final String description; // Detailed description of the meeting
  final DateTime dateTime; // Scheduled date and time
  final DateTime createdAt; // When the meeting was created
  final DateTime? endTime; // Optional end time for the meeting

  // Meeting classification
  final String type; // Type of meeting: "global" or "local"
  final String? branchId; // Associated branch ID (null for global meetings)
  final String
      category; // Category (e.g., "prayer", "bible_study", "leadership")

  // Organizational details
  final String organizer; // Person responsible for the meeting
  final String location; // Physical or virtual meeting location
  final bool isVirtual; // Whether this is an online meeting
  final String? meetingLink; // Link for virtual meetings
  final int expectedAttendance; // Expected number of attendees
  final List<String> attendees; // List of user IDs who plan to attend

  // Meeting status tracking
  final bool isCancelled; // Whether the meeting has been cancelled
  final String
      status; // Current status (scheduled, ongoing, completed, cancelled)

  /// Constructor for creating a new MeetingModel instance
  MeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type,
    this.branchId, // Optional for global meetings
    DateTime? createdAt, // Optional creation time
    this.endTime, // Optional end time
    this.category = 'general', // Default category
    required this.organizer,
    required this.location,
    this.isVirtual = false, // Default to physical meeting
    this.meetingLink, // Optional virtual meeting link
    this.expectedAttendance = 0,
    this.attendees = const [], // Default to empty list
    this.isCancelled = false, // Default to not cancelled
    this.status = 'scheduled', // Default status
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a MeetingModel instance from JSON data
  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: DateTime.parse(json['date_time']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
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
      attendees: List<String>.from(json['attendees'] ?? []),
      isCancelled: json['is_cancelled'] ?? false,
      status: json['status'] ?? 'scheduled',
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
      'is_cancelled': isCancelled,
      'status': status,
    };
  }

  /// Determines if a meeting should be visible to a user based on their branch affiliation
  bool shouldNotify(String? userBranchId) {
    if (isCancelled) return false; // Don't notify for cancelled meetings
    if (type == 'global') return true; // Global meetings visible to all
    return userBranchId != null &&
        userBranchId == branchId; // Local meeting check
  }

  /// Checks if the meeting is currently ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(dateTime) &&
        (endTime == null || now.isBefore(endTime!)) &&
        !isCancelled;
  }

  /// Creates a copy of the meeting with updated fields
  MeetingModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    DateTime? createdAt,
    DateTime? endTime,
    String? type,
    String? branchId,
    String? category,
    String? organizer,
    String? location,
    bool? isVirtual,
    String? meetingLink,
    int? expectedAttendance,
    List<String>? attendees,
    bool? isCancelled,
    String? status,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      createdAt: createdAt ?? this.createdAt,
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
      isCancelled: isCancelled ?? this.isCancelled,
      status: status ?? this.status,
    );
  }

  /// Two meetings are considered equal if they have the same ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeetingModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
