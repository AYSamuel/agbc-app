import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task_model.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../models/user_model.dart';
import 'task_details_screen.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_dropdown.dart';
import 'package:remixicon/remixicon.dart';

/// A screen that displays a list of tasks and allows filtering and sorting
class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  String _selectedFilter = 'all';
  String _selectedSort = 'due_date';
  final Map<String, UserModel?> _userCache = {};
  List<UserModel> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    final supabaseProvider =
        Provider.of<SupabaseProvider>(context, listen: false);
    supabaseProvider.getAllUsers().listen((users) {
      if (mounted) {
        setState(() {
          _allUsers = users;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CustomBackButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Task Management',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkNeutralColor,
                    ),
                  ),
                ],
              ),
            ),
            _buildFilterAndSortBar(),
            Expanded(
              child: StreamBuilder<List<TaskModel>>(
                stream: Provider.of<SupabaseProvider>(context).getAllTasks(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }

                  final tasks = _filterAndSortTasks(snapshot.data!);

                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Remix.task_line,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Tasks Found',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are no tasks matching your current filter.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.neutralColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(tasks[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterAndSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: CustomDropdown<String>(
              value: _selectedFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Tasks')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(
                    value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFilter = value;
                  });
                }
              },
              hint: 'Filter by Status',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomDropdown<String>(
              value: _selectedSort,
              items: const [
                DropdownMenuItem(value: 'due_date', child: Text('Due Date')),
                DropdownMenuItem(value: 'priority', child: Text('Priority')),
                DropdownMenuItem(value: 'status', child: Text('Status')),
                DropdownMenuItem(value: 'title', child: Text('Title')),
                DropdownMenuItem(
                    value: 'created_at', child: Text('Created Date')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSort = value;
                  });
                }
              },
              hint: 'Sort by',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(task: task),
          ),
        );
      },
      child: CustomCard(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkNeutralColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.neutralColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusChip(task.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  icon: Remix.flag_line,
                  label: _getPriorityDisplayText(task.priority),
                  color: _getPriorityColor(task.priority),
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Remix.calendar_line,
                  label: _formatDate(task.dueDate),
                  color: AppTheme.neutralColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<UserModel?>(
              future: _getUserDetails(task.assignedTo),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Row(
                    children: [
                      const Icon(
                        Remix.user_line,
                        size: 16,
                        color: AppTheme.neutralColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned to: ${snapshot.data!.displayName}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.neutralColor,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getStatusDisplayText(status),
        style: GoogleFonts.inter(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<TaskModel> _filterAndSortTasks(List<TaskModel> tasks) {
    // Apply filter
    var filteredTasks = tasks;
    if (_selectedFilter != 'all') {
      TaskStatus? filterStatus;
      switch (_selectedFilter) {
        case 'pending':
          filterStatus = TaskStatus.pending;
          break;
        case 'in_progress':
          filterStatus = TaskStatus.inProgress;
          break;
        case 'completed':
          filterStatus = TaskStatus.completed;
          break;
        case 'cancelled':
          filterStatus = TaskStatus.cancelled;
          break;
      }
      if (filterStatus != null) {
        filteredTasks =
            tasks.where((task) => task.status == filterStatus).toList();
      }
    }

    // Apply sort
    switch (_selectedSort) {
      case 'due_date':
        filteredTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case 'priority':
        filteredTasks.sort((a, b) => _getPriorityWeight(b.priority)
            .compareTo(_getPriorityWeight(a.priority)));
        break;
      case 'status':
        filteredTasks.sort((a, b) =>
            _getStatusWeight(a.status).compareTo(_getStatusWeight(b.status)));
        break;
      case 'title':
        filteredTasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'created_at':
        filteredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filteredTasks;
  }

  int _getPriorityWeight(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return 4;
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 1;
    }
  }

  int _getStatusWeight(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 1;
      case TaskStatus.inProgress:
        return 2;
      case TaskStatus.completed:
        return 3;
      case TaskStatus.cancelled:
        return 4;
    }
  }

  String _getStatusDisplayText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'PENDING';
      case TaskStatus.inProgress:
        return 'IN PROGRESS';
      case TaskStatus.completed:
        return 'COMPLETED';
      case TaskStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String _getPriorityDisplayText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'LOW';
      case TaskPriority.medium:
        return 'MEDIUM';
      case TaskPriority.high:
        return 'HIGH';
      case TaskPriority.urgent:
        return 'URGENT';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.pending:
        return Colors.blue;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return const Color(0xFF9D174D);
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<UserModel?> _getUserDetails(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      // Find user from the loaded users list
      final user = _allUsers.firstWhere(
        (user) => user.id == userId,
        orElse: () => throw Exception('User not found'),
      );
      _userCache[userId] = user;
      return user;
    } catch (e) {
      return null;
    }
  }
}
