// lib/models/task_model.dart

class TaskModel {
  final String id; // Unique identifier for the task
  final String title; // Title of the task
  final String description; // Description of the task
  final DateTime deadline; // Deadline for the task
  final String assignedTo; // ID of the user to whom the task is assigned
  final bool
      isAccepted; // Indicates if the task has been accepted by the assignee
  final DateTime? reminder; // Optional reminder time for the task

  // Constructor for creating an instance of TaskModel
  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.assignedTo,
    this.isAccepted = false, // Default value is false (not accepted)
    this.reminder, // Optional parameter for reminder time
  });

  // Factory constructor to create a TaskModel instance from a JSON object
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'], // Map JSON id to model property
      title: json['title'], // Map JSON title to model property
      description:
          json['description'], // Map JSON description to model property
      deadline: DateTime.parse(
          json['deadline']), // Parse deadline from string to DateTime
      assignedTo: json['assignedTo'], // Map JSON assignedTo to model property
      isAccepted: json['isAccepted'] ??
          false, // Default to false if not specified in JSON
      reminder:
          json['reminder'] != null ? DateTime.parse(json['reminder']) : null,
      // Parse reminder if present, otherwise set it as null.
    );
  }

  // Method to convert a TaskModel instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Include id in JSON representation
      'title': title, // Include title in JSON representation
      'description': description, // Include description in JSON representation
      'deadline': deadline.toIso8601String(),
      // Convert DateTime deadline to ISO string format for JSON representation.
      'assignedTo': assignedTo, // Include assignedTo in JSON representation
      'isAccepted':
          isAccepted, // Include isAccepted status in JSON representation
      'reminder': reminder?.toIso8601String(),
      // Convert reminder DateTime to ISO string if present.
    };
  }
}
