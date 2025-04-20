import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:agbc_app/models/task_model.dart';

class TaskStatusCard extends StatelessWidget {
  final List<TaskModel> tasks;

  const TaskStatusCard({
    super.key,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final taskCount = tasks.where((task) => task.status != 'completed').length;
    final hasTasks = taskCount > 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: hasTasks 
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            hasTasks ? Icons.task : Icons.task_alt,
            color: hasTasks ? AppTheme.primaryColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            taskCount == 0 
                ? 'You currently have no tasks assigned to you'
                : 'You currently have $taskCount ${taskCount == 1 ? 'task' : 'tasks'} assigned to you',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: hasTasks ? AppTheme.primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
} 