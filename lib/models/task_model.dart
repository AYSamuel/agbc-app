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
  final String assigned_to; // ID of user responsible for the task
  final DateTime deadline; // When the task needs to be completed
  final DateTime? reminder; // Optional reminder time
  final String? branch_id; // Associated branch (optional)

  // Task status and tracking
  final bool is_accepted; // Whether assignee has accepted the task
  final bool is_completed; // Whether task has been completed
  final DateTime? completed_at; // When the task was completed
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
    required this.assigned_to,
    required this.createdBy,
    DateTime? createdAt,
    this.branch_id,
    this.reminder,
    this.is_accepted = false,
    this.is_completed = false,
    this.completed_at,
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
          json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      createdBy: json['created_by'] ?? '',
      assigned_to: json['assigned_to'] ?? '',
      deadline: DateTime.parse(json['deadline']),
      branch_id: json['branch_id'],
      reminder:
          json['reminder'] != null ? DateTime.parse(json['reminder']) : null,
      is_accepted: json['is_accepted'] ?? false,
      is_completed: json['is_completed'] ?? false,
      completed_at: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
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
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'assigned_to': assigned_to,
      'deadline': deadline.toIso8601String(),
      'branch_id': branch_id,
      'reminder': reminder?.toIso8601String(),
      'is_accepted': is_accepted,
      'is_completed': is_completed,
      'completed_at': completed_at?.toIso8601String(),
      'status': status,
      'priority': priority,
      'category': category,
      'comments': comments,
      'attachments': attachments,
    };
  }

  /// Checks if the task is overdue
  bool get isOverdue {
    return !is_completed && DateTime.now().isAfter(deadline);
  }

  /// Checks if the task needs attention (approaching deadline)
  bool get needsAttention {
    final daysUntilDeadline = deadline.difference(DateTime.now()).inDays;
    return !is_completed && !isOverdue && daysUntilDeadline <= 2;
  }

  /// Creates a copy of the task with updated fields
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    String? createdBy,
    String? assigned_to,
    DateTime? deadline,
    String? branch_id,
    DateTime? reminder,
    bool? is_accepted,
    bool? is_completed,
    DateTime? completed_at,
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
      assigned_to: assigned_to ?? this.assigned_to,
      deadline: deadline ?? this.deadline,
      branch_id: branch_id ?? this.branch_id,
      reminder: reminder ?? this.reminder,
      is_accepted: is_accepted ?? this.is_accepted,
      is_completed: is_completed ?? this.is_completed,
      completed_at: completed_at ?? this.completed_at,
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
