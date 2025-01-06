// lib/models/meeting_model.dart

class MeetingModel {
  final String id; // Unique identifier for the meeting
  final String title; // Title of the meeting
  final String description; // Description of the meeting
  final DateTime dateTime; // Date and time of the meeting
  final String type; // Type of meeting (global or local)
  final String? churchId; // Optional church ID for local meetings

  // Constructor for creating an instance of MeetingModel
  MeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type, // "global" or "local"
    this.churchId, // Only applicable for local meetings (can be null)
  });

  // Factory constructor to create a MeetingModel instance from a JSON object
  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['dateTime']),
      type: json['type'], // "global" or "local"
      churchId: json['churchId'],
      // Can be null for global meetings.
    );
  }

  // Method to convert a MeetingModel instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Include id in JSON representation.
      'title': title, // Include title in JSON representation.
      'description': description,
      // Include description in JSON representation.
      'dateTime': dateTime.toIso8601String(),
      // Convert DateTime dateTime to ISO string format.
      'type': type, // Include type (global or local) in JSON representation.
      'churchId': churchId, // Can be null for global meetings.
    };
  }

  /// Method to determine if a user should see this meeting based on their church affiliation.
  bool shouldNotify(String? userChurchId) {
    if (type == 'global') {
      return true; // All users should see global meetings
    } else if (type == 'local') {
      return userChurchId != null && userChurchId == churchId;
      // Only notify users if they belong to the specified church branch
    }
    return false; // Default case, no notification
  }
}
