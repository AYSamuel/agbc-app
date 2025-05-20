/// Handles task creation, assignment, tracking, and completion status
/// with support for deadlines, priorities, and notifications.
class TaskModel {
  // Basic task information
  final String id; // Unique identifier for the task
  final String title; // Title/name of the task
  final String description; // Detailed description of the task
  final DateTime createdAt; // When the task was created
  final DateTime? updatedAt; // When the task was last updated
  final String createdBy; // ID of user who created the task

  // Assignment and scheduling
  final String assignedTo; // ID of user responsible for the task
  final DateTime dueDate; // When the task needs to be completed
  final String? branchId; // Associated branch (optional)

  // Task status and tracking
  final String status; // Current status (pending, in_progress, completed, etc.)

  // Task classification
  final String priority; // Priority level (high, medium, low)

  // Collaboration
  final List<String> attachments; // Links to related files/documents

  /// Constructor for creating a new TaskModel instance
  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.assignedTo,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedAt,
    this.branchId,
    this.status = 'pending',
    this.priority = 'medium',
    this.attachments = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a TaskModel instance from JSON data
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      createdBy: json['created_by'] ?? '',
      assignedTo: json['assigned_to'] ?? '',
      dueDate: DateTime.parse(json['due_date']),
      branchId: json['branch_id'],
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
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
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'due_date': dueDate.toIso8601String(),
      'branch_id': branchId,
      'status': status,
      'priority': priority,
      'attachments': attachments,
    };
  }

  /// Checks if the task is overdue
  bool get isOverdue {
    return status != 'completed' && DateTime.now().isAfter(dueDate);
  }

  /// Checks if the task needs attention (approaching deadline)
  bool get needsAttention {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    return status != 'completed' && !isOverdue && daysUntilDue <= 2;
  }

  /// Creates a copy of the task with updated fields
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? assignedTo,
    DateTime? dueDate,
    String? branchId,
    String? status,
    String? priority,
    List<String>? attachments,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      branchId: branchId ?? this.branchId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
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
