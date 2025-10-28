enum ResponseType {
  attending('attending'),
  maybe('maybe'),
  notAttending('not_attending');

  const ResponseType(this.value);
  final String value;

  static ResponseType fromString(String value) {
    switch (value) {
      case 'attending':
        return ResponseType.attending;
      case 'maybe':
        return ResponseType.maybe;
      case 'not_attending':
        return ResponseType.notAttending;
      default:
        throw ArgumentError('Invalid response type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case ResponseType.attending:
        return 'Attending';
      case ResponseType.maybe:
        return 'Maybe';
      case ResponseType.notAttending:
        return 'Not Attending';
    }
  }
}

class MeetingResponseModel {
  final String userId;
  final String meetingId;
  final ResponseType responseType;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeetingResponseModel({
    required this.userId,
    required this.meetingId,
    required this.responseType,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MeetingResponseModel.fromJson(Map<String, dynamic> json) {
    return MeetingResponseModel(
      userId: json['user_id'] as String? ?? '',
      meetingId: json['meeting_id'] as String? ?? '',
      responseType: ResponseType.fromString(json['response_type'] as String? ?? 'not_attending'),
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'meeting_id': meetingId,
      'response_type': responseType.value,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MeetingResponseModel copyWith({
    String? userId,
    String? meetingId,
    ResponseType? responseType,
    String? reason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeetingResponseModel(
      userId: userId ?? this.userId,
      meetingId: meetingId ?? this.meetingId,
      responseType: responseType ?? this.responseType,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeetingResponseModel &&
        other.userId == userId &&
        other.meetingId == meetingId &&
        other.responseType == responseType &&
        other.reason == reason &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      meetingId,
      responseType,
      reason,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'MeetingResponseModel(userId: $userId, meetingId: $meetingId, responseType: $responseType, reason: $reason, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

class MeetingAttendanceSummary {
  final String meetingId;
  final int totalResponses;
  final int attending;
  final int maybe;
  final int notAttending;
  final List<MeetingResponseWithUser> responses;

  const MeetingAttendanceSummary({
    required this.meetingId,
    required this.totalResponses,
    required this.attending,
    required this.maybe,
    required this.notAttending,
    required this.responses,
  });

  factory MeetingAttendanceSummary.fromJson(Map<String, dynamic> json) {
    final responsesList = json['responses'] as List<dynamic>? ?? [];
    
    return MeetingAttendanceSummary(
      meetingId: json['meeting_id'] as String? ?? '',
      totalResponses: json['total_responses'] as int? ?? 0,
      attending: json['attending_count'] as int? ?? 0,
      maybe: json['maybe_count'] as int? ?? 0,
      notAttending: json['not_attending_count'] as int? ?? 0,
      responses: responsesList
          .map((response) => MeetingResponseWithUser.fromJson(response as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meeting_id': meetingId,
      'total_responses': totalResponses,
      'attending': attending,
      'maybe': maybe,
      'not_attending': notAttending,
      'responses': responses.map((response) => response.toJson()).toList(),
    };
  }

  double get attendanceRate {
    if (totalResponses == 0) return 0.0;
    return attending / totalResponses;
  }

  @override
  String toString() {
    return 'MeetingAttendanceSummary(meetingId: $meetingId, totalResponses: $totalResponses, attending: $attending, maybe: $maybe, notAttending: $notAttending)';
  }
}

class MeetingResponseWithUser {
  final String userId;
  final String userName;
  final ResponseType responseType;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeetingResponseWithUser({
    required this.userId,
    required this.userName,
    required this.responseType,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MeetingResponseWithUser.fromJson(Map<String, dynamic> json) {
    return MeetingResponseWithUser(
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? 'Unknown User',
      responseType: ResponseType.fromString(json['response_type'] as String? ?? 'not_attending'),
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'response_type': responseType.value,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'MeetingResponseWithUser(userId: $userId, userName: $userName, responseType: $responseType, reason: $reason)';
  }
}