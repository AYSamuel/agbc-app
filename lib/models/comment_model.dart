/// Enhanced CommentModel with new schema features including metadata and updated_at.
class CommentModel {
  final String id;
  final String taskId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt; // New field for tracking updates
  final String? userName; // Optional display name of the user
  final Map<String, dynamic> metadata; // Additional comment metadata

  CommentModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.userName,
    Map<String, dynamic>? metadata,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       metadata = metadata ?? {};

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      taskId: json['task_id'] ?? '',
      userId: json['user_id'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      userName: json['user_name'],
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_name': userName,
      'metadata': metadata,
    };
  }

  /// Checks if the comment has been edited
  bool get isEdited {
    return updatedAt.isAfter(createdAt.add(const Duration(seconds: 1)));
  }

  /// Gets the comment type from metadata
  String get type {
    return metadata['type'] ?? 'comment';
  }

  CommentModel copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    Map<String, dynamic>? metadata,
  }) {
    return CommentModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      userName: userName ?? this.userName,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
