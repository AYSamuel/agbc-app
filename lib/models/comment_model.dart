class CommentModel {
  final String id;
  final String taskId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userName; // Optional display name of the user

  CommentModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userName,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      taskId: json['task_id'] ?? '',
      userId: json['user_id'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      userName: json['user_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
    };
  }
}
