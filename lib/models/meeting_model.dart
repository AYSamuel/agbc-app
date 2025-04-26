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
  final bool is_virtual; // Whether this is an online meeting
  final String? meeting_link; // Link for virtual meetings
  final int expected_attendance; // Expected number of attendees
  final List<String> attendees; // List of user IDs who plan to attend

  // Meeting status tracking
  final bool is_cancelled; // Whether the meeting has been cancelled
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
    this.is_virtual = false, // Default to physical meeting
    this.meeting_link, // Optional virtual meeting link
    this.expected_attendance = 0,
    this.attendees = const [], // Default to empty list
    this.is_cancelled = false, // Default to not cancelled
    this.status = 'scheduled', // Default status
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a MeetingModel instance from JSON data
  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: DateTime.parse(json['dateTime']),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      type: json['type'] ?? 'local',
      branchId: json['branchId'],
      category: json['category'] ?? 'general',
      organizer: json['organizer'] ?? '',
      location: json['location'] ?? '',
      is_virtual: json['is_virtual'] ?? false,
      meeting_link: json['meeting_link'],
      expected_attendance: json['expected_attendance'] ?? 0,
      attendees: List<String>.from(json['attendees'] ?? []),
      is_cancelled: json['is_cancelled'] ?? false,
      status: json['status'] ?? 'scheduled',
    );
  }

  /// Converts the MeetingModel instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'type': type,
      'branchId': branchId,
      'category': category,
      'organizer': organizer,
      'location': location,
      'is_virtual': is_virtual,
      'meeting_link': meeting_link,
      'expected_attendance': expected_attendance,
      'attendees': attendees,
      'is_cancelled': is_cancelled,
      'status': status,
    };
  }

  /// Determines if a meeting should be visible to a user based on their branch affiliation
  bool shouldNotify(String? userBranchId) {
    if (is_cancelled) return false; // Don't notify for cancelled meetings
    if (type == 'global') return true; // Global meetings visible to all
    return userBranchId != null &&
        userBranchId == branchId; // Local meeting check
  }

  /// Checks if the meeting is currently ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(dateTime) &&
        (endTime == null || now.isBefore(endTime!)) &&
        !is_cancelled;
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
    bool? is_virtual,
    String? meeting_link,
    int? expected_attendance,
    List<String>? attendees,
    bool? is_cancelled,
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
      is_virtual: is_virtual ?? this.is_virtual,
      meeting_link: meeting_link ?? this.meeting_link,
      expected_attendance: expected_attendance ?? this.expected_attendance,
      attendees: attendees ?? this.attendees,
      is_cancelled: is_cancelled ?? this.is_cancelled,
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
