import 'package:grace_portal/models/task_model.dart';
import 'package:grace_portal/screens/tasks_screen.dart';
import 'package:grace_portal/utils/theme.dart';
import 'package:grace_portal/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';

class TaskStatusCard extends StatefulWidget {
  final List<TaskModel> tasks;

  const TaskStatusCard({
    super.key,
    required this.tasks,
  });

  @override
  State<TaskStatusCard> createState() => _TaskStatusCardState();
}

class _TaskStatusCardState extends State<TaskStatusCard> {
  @override
  Widget build(BuildContext context) {
    final taskCount = widget.tasks
        .where((task) => task.status != TaskStatus.completed)
        .length;
    final hasTasks = taskCount > 0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Tasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.darkNeutralColor,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasTasks
                      ? AppTheme.warningColor.withValues(alpha: 0.1)
                      : AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Remix.task_line,
                  color:
                      hasTasks ? AppTheme.warningColor : AppTheme.successColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasTasks
                ? 'You have $taskCount ${taskCount == 1 ? 'task' : 'tasks'} assigned to you'
                : 'You don\'t have any tasks assigned to you',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutralColor,
            ),
          ),
          const SizedBox(height: 12),
          CustomButton.text(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => const TasksScreen(showBackButton: true),
                  fullscreenDialog: true,
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View all tasks',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Remix.arrow_right_s_line,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
