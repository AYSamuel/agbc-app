import 'package:grace_portal/models/task_model.dart';
import 'package:grace_portal/screens/tasks_screen.dart';
import 'package:grace_portal/config/theme.dart';
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
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
              Text(
                'Current Tasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasTasks
                      ? AppTheme.warningColor.withValues(alpha: 0.1)
                      : AppTheme.secondary(context).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Remix.task_line,
                  color: hasTasks
                      ? AppTheme.warningColor
                      : AppTheme.secondary(context),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasTasks
                ? 'You are currently involved in $taskCount ${taskCount == 1 ? 'task' : 'tasks'}'
                : 'You are not currently involved in any tasks',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View all tasks',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary(context),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Remix.arrow_right_s_line,
                  size: 20,
                  color: AppTheme.primary(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
