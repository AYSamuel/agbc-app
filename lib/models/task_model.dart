import 'recurrence.dart';

/// Enhanced TaskModel with new schema features including metadata, attachments, and ENUMs.
class TaskModel {
  // Basic task information
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt; // New field for tracking updates
  final String createdBy;

  // Assignment and scheduling
  final String assignedTo;
  final DateTime dueDate;
  final String? branchId;

  // Task status and tracking using ENUMs
  final TaskStatus status;
  final DateTime? completedAt;

  // Task classification
  final TaskPriority priority;

  // Enhanced features
  final Map<String, dynamic> metadata; // Additional task metadata
  final List<Map<String, dynamic>> attachments; // File attachments

  /// Constructor for creating a new TaskModel instance
  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.assignedTo,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.branchId,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.completedAt,
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>>? attachments,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        metadata = metadata ?? {},
        attachments = attachments ?? [];

  /// Creates a TaskModel instance from JSON data
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      createdBy: json['created_by'] ?? '',
      assignedTo: json['assigned_to'] ?? '',
      dueDate: DateTime.parse(json['due_date']),
      branchId: json['branch_id'],
      status:
          TaskStatusExtension.fromDatabaseValue(json['status'] ?? 'pending'),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      attachments: List<Map<String, dynamic>>.from(
        json['attachments'] as List? ?? [],
      ),
    );
  }

  /// Converts the TaskModel instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'due_date': dueDate.toIso8601String(),
      'branch_id': branchId,
      'status': status.databaseValue,
      'priority': priority.toString().split('.').last,
      'completed_at': completedAt?.toIso8601String(),
      'metadata': metadata,
      'attachments': attachments,
    };
  }

  /// Checks if the task is overdue
  bool get isOverdue {
    return status != TaskStatus.completed && DateTime.now().isAfter(dueDate);
  }

  /// Checks if the task needs attention (approaching deadline)
  bool get needsAttention {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    return status != TaskStatus.completed && !isOverdue && daysUntilDue <= 2;
  }

  /// Gets the priority color for UI display
  String get priorityColor {
    switch (priority) {
      case TaskPriority.low:
        return '#4CAF50'; // Green
      case TaskPriority.medium:
        return '#FF9800'; // Orange
      case TaskPriority.high:
        return '#F44336'; // Red
      case TaskPriority.urgent:
        return '#9C27B0'; // Purple
    }
  }

  /// Gets the status color for UI display
  String get statusColor {
    switch (status) {
      case TaskStatus.pending:
        return '#9E9E9E'; // Gray
      case TaskStatus.inProgress:
        return '#2196F3'; // Blue
      case TaskStatus.completed:
        return '#4CAF50'; // Green
      case TaskStatus.cancelled:
        return '#F44336'; // Red
    }
  }

  bool get isRecurring {
    final rec = metadata['recurrence'] as Map<String, dynamic>?;
    return rec?['is_recurring'] == true;
  }

  RecurrenceFrequency get recurrenceFrequency {
    final rec = metadata['recurrence'] as Map<String, dynamic>?;
    final value = rec?['frequency'] as String?;
    return RecurrenceFrequencyExtension.fromDatabaseValue(value ?? 'none');
  }

  int get recurrenceInterval {
    final rec = metadata['recurrence'] as Map<String, dynamic>?;
    return (rec?['interval'] as int?) ?? 1;
  }

  DateTime? get recurrenceEndDate {
    final rec = metadata['recurrence'] as Map<String, dynamic>?;
    final v = rec?['end_date'] as String?;
    return v != null ? DateTime.parse(v) : null;
  }

  int? get recurrenceCount {
    final rec = metadata['recurrence'] as Map<String, dynamic>?;
    return rec?['count'] as int?;
  }

  String? get parentTaskId {
    final rec = metadata['recurrence'] as Map<String, dynamic>?;
    return rec?['parent_task_id'] as String?;
  }

  List<DateTime> get recurrenceExceptions {
    final rec = metadata['recurrence'] as Map<String, dynamic>?;
    final list = rec?['exceptions'] as List<dynamic>?;
    if (list == null) return [];
    return list.whereType<String>().map((e) => DateTime.parse(e)).toList();
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
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>>? attachments,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      branchId: branchId ?? this.branchId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Enum for task status matching the database schema
enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

/// Extension to handle database mapping for TaskStatus
extension TaskStatusExtension on TaskStatus {
  /// Converts enum to database string value (snake_case)
  String get databaseValue {
    switch (this) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Creates enum from database string value (snake_case)
  static TaskStatus fromDatabaseValue(String value) {
    switch (value) {
      case 'pending':
        return TaskStatus.pending;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
      default:
        return TaskStatus.cancelled;
    }
  }
}

/// Enum for task priority matching the database schema
enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}
