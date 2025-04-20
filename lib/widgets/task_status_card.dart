import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:agbc_app/models/task_model.dart';
import 'package:provider/provider.dart';
import 'package:agbc_app/services/auth_service.dart';

class TaskStatusCard extends StatefulWidget {
  final List<TaskModel> tasks;

  const TaskStatusCard({
    super.key,
    required this.tasks,
  });

  @override
  State<TaskStatusCard> createState() => _TaskStatusCardState();
}

class _TaskStatusCardState extends State<TaskStatusCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _colorAnimation = ColorTween(
      begin: AppTheme.cardColor,
      end: AppTheme.accentColor.withOpacity(0.15),
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(TaskStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks.length != oldWidget.tasks.length) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final taskCount = widget.tasks.where((task) => task.status != 'completed').length;
    final hasTasks = taskCount > 0;
    
    // For members, only show the card if they have active tasks
    if (user?.role == 'member' && !hasTasks) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: hasTasks 
                  ? AppTheme.accentColor.withOpacity(0.15)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: hasTasks 
                      ? AppTheme.accentColor.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    hasTasks ? Icons.task : Icons.task_alt,
                    key: ValueKey<bool>(hasTasks),
                    color: hasTasks ? AppTheme.accentColor : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    hasTasks
                        ? 'You currently have $taskCount ${taskCount == 1 ? 'task' : 'tasks'} assigned to you'
                        : 'You currently have no tasks assigned to you',
                    key: ValueKey<int>(taskCount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: hasTasks ? AppTheme.accentColor : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 