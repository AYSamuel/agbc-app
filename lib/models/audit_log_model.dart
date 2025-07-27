/// AuditLogModel for tracking system changes and user actions.
class AuditLogModel {
  final String id;
  final String? userId; // Nullable for system actions
  final String action;
  final String tableName;
  final String? recordId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    this.userId,
    required this.action,
    required this.tableName,
    this.recordId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] ?? '',
      userId: json['user_id'],
      action: json['action'] ?? '',
      tableName: json['table_name'] ?? '',
      recordId: json['record_id'],
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'table_name': tableName,
      'record_id': recordId,
      'old_values': oldValues,
      'new_values': newValues,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Gets a human-readable description of the action
  String get description {
    final table = tableName.replaceAll('_', ' ');
    switch (action.toUpperCase()) {
      case 'INSERT':
        return 'Created new $table';
      case 'UPDATE':
        return 'Updated $table';
      case 'DELETE':
        return 'Deleted $table';
      default:
        return '$action on $table';
    }
  }

  /// Gets the action severity level
  int get severity {
    switch (action.toUpperCase()) {
      case 'DELETE':
        return 3; // High
      case 'UPDATE':
        return 2; // Medium
      case 'INSERT':
      case 'SELECT':
        return 1; // Low
      default:
        return 2; // Medium
    }
  }

  /// Gets the changes made (for UPDATE actions)
  Map<String, dynamic> get changes {
    if (action.toUpperCase() != 'UPDATE' || oldValues == null || newValues == null) {
      return {};
    }

    Map<String, dynamic> changes = {};
    newValues!.forEach((key, newValue) {
      final oldValue = oldValues![key];
      if (oldValue != newValue) {
        changes[key] = {
          'from': oldValue,
          'to': newValue,
        };
      }
    });

    return changes;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}