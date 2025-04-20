/// Handles task creation, assignment, tracking, and completion status
/// with support for deadlines, priorities, and notifications.
class TaskModel {
  // Basic task information
  final String id; // Unique identifier for the task
  final String title; // Title/name of the task
  final String description; // Detailed description of the task
  final DateTime createdAt; // When the task was created
  final String createdBy; // ID of user who created the task

  // Assignment and scheduling
  final String assignedTo; // ID of user responsible for the task
  final DateTime deadline; // When the task needs to be completed
  final DateTime? reminder; // Optional reminder time
  final String? churchId; // Associated church branch (optional)

  // Task status and tracking
  final bool isAccepted; // Whether assignee has accepted the task
  final bool isCompleted; // Whether task has been completed
  final DateTime? completedAt; // When the task was completed
  final String status; // Current status (pending, in_progress, completed, etc.)

  // Task classification
  final String priority; // Priority level (high, medium, low)
  final String category; // Category (e.g., "maintenance", "ministry", "event")

  // Collaboration
  final List<Map<String, dynamic>> comments; // Task-related comments/updates
  final List<String> attachments; // Links to related files/documents

  /// Constructor for creating a new TaskModel instance
  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.assignedTo,
    required this.createdBy,
    DateTime? createdAt,
    this.churchId,
    this.reminder,
    this.isAccepted = false,
    this.isCompleted = false,
    this.completedAt,
    this.status = 'pending',
    this.priority = 'medium',
    this.category = 'general',
    this.comments = const [],
    this.attachments = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a TaskModel instance from JSON data
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      createdBy: json['createdBy'] ?? '',
      assignedTo: json['assignedTo'] ?? '',
      deadline: DateTime.parse(json['deadline']),
      churchId: json['churchId'],
      reminder:
          json['reminder'] != null ? DateTime.parse(json['reminder']) : null,
      isAccepted: json['isAccepted'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      category: json['category'] ?? 'general',
      comments: List<Map<String, dynamic>>.from(json['comments'] ?? []),
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  /// Converts the TaskModel instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'deadline': deadline.toIso8601String(),
      'churchId': churchId,
      'reminder': reminder?.toIso8601String(),
      'isAccepted': isAccepted,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'status': status,
      'priority': priority,
      'category': category,
      'comments': comments,
      'attachments': attachments,
    };
  }

  /// Checks if the task is overdue
  bool get isOverdue {
    return !isCompleted && DateTime.now().isAfter(deadline);
  }

  /// Checks if the task needs attention (approaching deadline)
  bool get needsAttention {
    final daysUntilDeadline = deadline.difference(DateTime.now()).inDays;
    return !isCompleted && !isOverdue && daysUntilDeadline <= 2;
  }

  /// Creates a copy of the task with updated fields
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    String? createdBy,
    String? assignedTo,
    DateTime? deadline,
    String? churchId,
    DateTime? reminder,
    bool? isAccepted,
    bool? isCompleted,
    DateTime? completedAt,
    String? status,
    String? priority,
    String? category,
    List<Map<String, dynamic>>? comments,
    List<String>? attachments,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      deadline: deadline ?? this.deadline,
      churchId: churchId ?? this.churchId,
      reminder: reminder ?? this.reminder,
      isAccepted: isAccepted ?? this.isAccepted,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
    );
  }

  /// Adds a comment to the task
  TaskModel addComment(String userId, String content) {
    final newComment = {
      'userId': userId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return copyWith(
      comments: [...comments, newComment],
    );
  }

  /// Two tasks are considered equal if they have the same ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
